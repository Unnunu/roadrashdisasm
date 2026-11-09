#!/usr/bin/env python3
"""Generate a best-effort function index and call graph from the sources.

Usage:
    python3 tools/callgraph.py -o docs/callgraph.md

The graph is derived from `jsr`/`bsr`/`jmp` targets in the `.asm` sources plus the
address labels from `build/roadrash.lst`. Indirect calls (`jsr (a0)`, ...) cannot be
resolved statically and are only counted.
"""
import argparse
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEFAULT_LISTING = os.path.join(ROOT, "build", "roadrash.lst")
EQUATE_FILES = ["ram_const.asm", "unknown.asm", "hw_const.asm"]

LABEL_RE = re.compile(r"^\s*([A-Za-z_][\w.$]*):")
INSN_RE = re.compile(r"^\s*([A-Za-z_.$][\w.$]*)(.*)$")
CALL_MNEMONICS = {"jsr", "bsr", "jmp"}
REG_RE = re.compile(r"^(d[0-7]|a[0-7]|sp|pc|usp|ssp|sr|ccr)$", re.I)


def parse_listing(path):
    names = {}
    addr2name = {}
    pat = re.compile(
        r"^\s*(?:\(\d+\)\s*)?\d+\s*/\s*([0-9A-Fa-f]+)\s*:\s*"
        r"([A-Za-z_][\w.$]*):"
    )
    try:
        fh = open(path, encoding="utf-8", errors="replace")
    except OSError:
        return names, addr2name
    for line in fh:
        m = pat.match(line)
        if m:
            addr, name = int(m.group(1), 16), m.group(2)
            names[name] = addr
            addr2name.setdefault(addr, []).append(name)
    return names, addr2name


def parse_equates():
    names = {}
    pat = re.compile(
        r"^\s*([A-Za-z_.$][\w.$]*)\s+equ\s+\$([0-9A-Fa-f]+)\s*(?:;.*)?$"
    )
    for fname in EQUATE_FILES:
        path = os.path.join(ROOT, fname)
        try:
            fh = open(path, encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line in fh:
            m = pat.match(line)
            if m:
                names.setdefault(m.group(1), int(m.group(2), 16))
    return names


def pick_addr_name(names):
    if not names:
        return None
    # prefer human-readable names over placeholders
    human = [n for n in names if not re.match(r"^(sub_|loc_|locret_|unk_|off_|ram_[0-9A-Fa-f]{6}$)", n)]
    return sorted(human or names, key=lambda s: (len(s), s))[0]


def strip_comment(line):
    i = line.find(";")
    return line[:i] if i >= 0 else line


def extract_target(operand, addr2name):
    t = operand.strip()
    if not t:
        return None
    if t.startswith("#"):
        return None
    # indirect / register modes
    m = re.match(r"^\(([^)]*)\)", t)
    if m:
        inner = m.group(1).strip()
        if REG_RE.match(inner) or "," in inner:
            return None
        # (symbol).w / (symbol).l
        inner = re.sub(r"\.([bwl])$", "", inner).strip()
        if inner.startswith("$"):
            try:
                addr = int(inner[1:], 16)
            except ValueError:
                return None
            return pick_addr_name(addr2name.get(addr))
        if re.match(r"^[A-Za-z_.$][\w.$]*$", inner):
            return inner
        return None
    # $ADDR.w / $ADDR.l
    m = re.match(r"^\$([0-9A-Fa-f]+)(?:\.[bwl])?$", t)
    if m:
        addr = int(m.group(1), 16)
        if addr < 0x8000:
            addr &= 0xFFFFFF  # abs.w operands are sign-extended 16-bit
        return pick_addr_name(addr2name.get(addr))
    # bare symbol (optionally sized)
    m = re.match(r"^([A-Za-z_][\w.$]*)(?:\.[bwl])?$", t)
    if m and not REG_RE.match(m.group(1)):
        return m.group(1)
    return None


def canonical(name, names, addr2name):
    addr = names.get(name)
    if addr is not None:
        picked = pick_addr_name(addr2name.get(addr))
        if picked:
            return picked
    return name


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-o", "--output", default="docs/callgraph.md")
    ap.add_argument("--listing", default=DEFAULT_LISTING)
    args = ap.parse_args()

    names, addr2name = parse_listing(args.listing)
    equ_names = parse_equates()
    for name, addr in equ_names.items():
        names.setdefault(name, addr)
        addr2name.setdefault(addr, []).append(name)

    edges = set()
    indirect = 0
    files = sorted(f for f in os.listdir(ROOT) if f.endswith(".asm"))
    for fname in files:
        current = None
        path = os.path.join(ROOT, fname)
        for line in open(path, encoding="utf-8", errors="replace"):
            code = strip_comment(line).rstrip()
            lm = LABEL_RE.match(code)
            if lm:
                label = lm.group(1)
                # local labels and generated loc_/locret_ labels do not start functions
                if not label.startswith(".") and not re.match(r"^(loc_|locret_)", label):
                    current = label
                continue
            im = INSN_RE.match(code)
            if not im:
                continue
            mn, tail = im.group(1).lower(), im.group(2)
            base = re.sub(r"\.[bwls]$", "", mn)
            if base not in CALL_MNEMONICS:
                continue
            operand = tail.strip()
            if not operand:
                continue
            target = extract_target(operand, addr2name)
            if target is None:
                if re.match(r"^\(([^)]*)\)", operand):
                    indirect += 1
                continue
            if target.startswith("."):
                continue
            target = canonical(target, names, addr2name)
            caller = current or ("<%s>" % fname)
            edges.add((caller, target))

    nodes = set()
    for a, b in edges:
        nodes.add(a)
        nodes.add(b)
    # keep the index focused on functions that are called or call
    callers = {n: set() for n in nodes}
    callees = {n: set() for n in nodes}
    for a, b in edges:
        callees[a].add(b)
        callers[b].add(a)

    # The overview graph stays readable: only the key entry points.
    roots = [r for r in ("RESET", "doStart", "TopLevel_Init", "VerticalInterrupt",
                         "HorizontalInterrupt") if r in nodes]

    out = []
    out.append("# Call graph (generated)")
    out.append("")
    out.append("Generated by `tools/callgraph.py` from the `.asm` sources and")
    out.append("`build/roadrash.lst`. Best effort: `jsr`/`bsr`/`jmp` targets only;")
    out.append("indirect calls (e.g. `jsr (a0)`) are counted but not resolved.")
    out.append("")
    out.append("## Summary")
    out.append("")
    out.append("- Functions/symbols: **%d**" % len(nodes))
    out.append("- Resolved call edges: **%d**" % len(edges))
    out.append("- Indirect calls seen: **%d**" % indirect)
    out.append("")
    out.append("Notes: `VerticalInterrupt` calls the pointer stored in `ram_UpdateFunction`")
    out.append("and `FadeWithFunction_GameTick` calls `Fade_ram_UpdateFunction` indirectly;")
    out.append("those edges are not resolved here.")
    out.append("")
    out.append("## Entry points / selected roots")
    out.append("")
    out.append("```mermaid")
    out.append("flowchart LR")
    for r in roots:
        if not callees.get(r):
            continue
        out.append('    %s["%s"]' % (mangle(r), r))
        for c in sorted(callees[r]):
            out.append('    %s["%s"] --> %s["%s"]' % (mangle(r), r, mangle(c), c))
    out.append("```")
    out.append("")
    out.append("## Function index")
    out.append("")
    out.append("| Function | Address | Callers | Callees |")
    out.append("|---|---|---|---|")
    for n in sorted(nodes, key=lambda x: (names.get(x, 0xFFFFFFFF), x)):
        addr = names.get(n)
        addr_s = "`0x%05X`" % addr if addr is not None else ""
        cs = ", ".join("`%s`" % x for x in sorted(callers[n])) or "-"
        ce = ", ".join("`%s`" % x for x in sorted(callees[n])) or "-"
        out.append("| `%s` | %s | %s | %s |" % (n, addr_s, cs, ce))
    out.append("")

    with open(os.path.join(ROOT, args.output), "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))
    print("wrote %s: %d nodes, %d edges, %d indirect" %
          (args.output, len(nodes), len(edges), indirect))


def mangle(name):
    return re.sub(r"[^A-Za-z0-9_]", "_", name)


if __name__ == "__main__":
    main()
