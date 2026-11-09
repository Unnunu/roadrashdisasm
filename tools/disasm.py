#!/usr/bin/env python3
"""Disassemble a ROM range into the project's AS syntax.

Uses capstone (m68k, big endian) and resolves known symbols from the assembler
listing and the equates in `ram_const.asm`/`unknown.asm`/`hw_const.asm`.

Examples:
    # project-style output for a code range
    python3 tools/disasm.py 0x1180 0x13c0

    # self-contained round-trip source (raw external references, with org)
    python3 tools/disasm.py 0x1180 0x13c0 --mode roundtrip --org -o /tmp/fade.asm

The round-trip mode is meant for validating the translator: assemble the output
with `tools/asl`, convert with `tools/p2bin`, and compare the produced bytes to
the same slice of `baserom.md`.
"""
import argparse
import re
import sys

try:
    from capstone import Cs, CS_ARCH_M68K, CS_MODE_BIG_ENDIAN, CS_MODE_M68K_000
except ImportError:
    sys.exit("capstone is required (python3 -m pip install capstone)")

DEFAULT_ROM = "baserom.md"
DEFAULT_LISTING = "build/roadrash.lst"
EQUATE_FILES = ["src/core/ram_const.asm", "src/core/unknown.asm", "src/core/hw_const.asm"]

BRANCH_BASE = {
    "bra", "bsr", "bcc", "bcs", "beq", "bne", "bmi", "bpl", "bvs", "bvc",
    "bge", "bgt", "ble", "blt", "bls", "bhi",
}
DB_BASE = {
    "dbf", "dbt", "dbeq", "dbne", "dbcc", "dbcs", "dbmi", "dbpl", "dbvs",
    "dbvc", "dbge", "dbgt", "dble", "dblt", "dbra",
}
CALL_BASE = {"jsr", "jmp", "bsr"}

AUTO_NAME_RE = re.compile(
    r"^(sub_|loc_|locret_|unk_|off_|word_|byte_|ram_[0-9A-Fa-f]{6}$)"
)


def equ_is_address(addr):
    """Heuristic: is an equ value an address rather than a small constant?

    Small values are struct offsets / flags (e.g. STRUCT_OFFSET_*), not addresses.
    Code labels below 0x10000 come from the assembler listing instead.
    """
    if 0x10000 <= addr < 0xA00000:   # ROM / code / data pointers
        return True
    if 0xA00000 <= addr <= 0xC000FF: # hardware registers
        return True
    if addr >= 0xFF0000:             # work RAM
        return True
    return False


def parse_equates(paths):
    """Return (name->addr, addr->[names]) from `NAME equ $VALUE` lines."""
    name2addr = {}
    addr2names = {}
    pat = re.compile(
        r"^\s*([A-Za-z_.$][\w.$]*)\s+equ\s+\$([0-9A-Fa-f]+)\s*(?:;.*)?$"
    )
    for path in paths:
        try:
            fh = open(path, encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line in fh:
            m = pat.match(line)
            if m:
                name, addr = m.group(1), int(m.group(2), 16)
                name2addr[name] = addr
                if equ_is_address(addr):
                    addr2names.setdefault(addr, []).append(name)
    return name2addr, addr2names


def parse_listing(path):
    """Return (name->addr, addr->[names]) from the AS listing labels."""
    name2addr = {}
    addr2names = {}
    # Global labels on their own line (or followed by code).
    pat = re.compile(
        r"^\s*(?:\(\d+\)\s*)?\d+\s*/\s*([0-9A-Fa-f]+)\s*:\s*"
        r"([A-Za-z_][\w.$]*):"
    )
    try:
        fh = open(path, encoding="utf-8", errors="replace")
    except OSError:
        return name2addr, addr2names
    for line in fh:
        m = pat.match(line)
        if m:
            addr, name = int(m.group(1), 16), m.group(2)
            name2addr[name] = addr
            addr2names.setdefault(addr, []).append(name)
    return name2addr, addr2names


def pick_name(names):
    """Prefer human-readable names over auto-generated ones."""
    if not names:
        return None
    human = [n for n in names if not AUTO_NAME_RE.match(n)]
    pool = human or names
    return sorted(pool, key=lambda s: (len(s), s))[0]


class Symbols:
    def __init__(self, name2addr, addr2names):
        self.name2addr = dict(name2addr)
        self.addr2names = {a: list(n) for a, n in addr2names.items()}

    def name_for(self, addr):
        return pick_name(self.addr2names.get(addr))

    def add(self, addr, name):
        self.name2addr[name] = addr
        self.addr2names.setdefault(addr, [])
        if name not in self.addr2names[addr]:
            self.addr2names[addr].append(name)


def base_mnemonic(mn):
    return re.sub(r"\.[bwsl]$", "", mn)


def instruction_target(ins):
    """Return the absolute branch/call target of an instruction, if any."""
    base = base_mnemonic(ins.mnemonic)
    if not (base in BRANCH_BASE or base in DB_BASE or base in CALL_BASE):
        return None
    m = re.findall(r"\$([0-9a-fA-F]+)", ins.op_str)
    if not m:
        return None
    return int(m[-1], 16)


def disassemble_segment(rom, start, end):
    md = Cs(CS_ARCH_M68K, CS_MODE_BIG_ENDIAN | CS_MODE_M68K_000)
    return list(md.disasm(rom[start:end], start))


def format_operands(ins, symbols, labels, mode, symbolize_imm=False):
    mn = ins.mnemonic
    ops = ins.op_str
    base = base_mnemonic(mn)
    is_branch = base in BRANCH_BASE
    is_db = base in DB_BASE
    is_call = base in CALL_BASE
    branchlike = is_branch or is_db or is_call

    # mnemonic normalization
    if is_branch and mn.endswith(".b"):
        mn = mn[:-2] + ".s"
    if base == "dbra":
        mn = "dbf"
    if mn == "lea.l":
        mn = "lea"

    # stack pointer spelling
    ops = re.sub(r"\ba7\b", "sp", ops)

    def resolve(addr):
        if addr in labels:
            return labels[addr]
        if mode == "project":
            return symbols.name_for(addr)
        return None

    # symbolize immediate addresses when asked (opt-in; can be ambiguous)
    if symbolize_imm and mode == "project":
        def imm_repl(m):
            addr = int(m.group(1), 16)
            if addr < 0x100:
                return m.group(0)
            name = resolve(addr)
            return "#" + name if name else m.group(0)
        ops = re.sub(r"#\$([0-9a-fA-F]+)", imm_repl, ops)

    # absolute reference with explicit size: $ADDR.w / $ADDR.l
    def abs_repl(m):
        addr, size = int(m.group(1), 16), m.group(2)
        name = resolve(addr)
        if name:
            return "(%s).%s" % (name, size)
        return "($%05X).%s" % (addr, size)

    ops = re.sub(r"\$([0-9a-fA-F]+)\.([wl])", abs_repl, ops)

    # PC-relative target: $ADDR(pc)
    def pc_repl(m):
        addr = int(m.group(1), 16)
        name = resolve(addr)
        if name:
            return "%s(pc)" % name
        return "($%05X,pc)" % addr

    ops = re.sub(r"\$([0-9a-fA-F]+)\(pc\)", pc_repl, ops)

    # branch / call target (unsized $ADDR, e.g. "bne.w $12f6")
    if branchlike:
        matches = list(re.finditer(r"\$([0-9a-fA-F]+)", ops))
        if matches:
            last = matches[-1]
            addr = int(last.group(1), 16)
            name = resolve(addr)
            repl = name if name else "$%05X" % addr
            ops = ops[: last.start()] + repl + ops[last.end():]

    # zero displacement: $0(aN) -> 0.w(aN); indexed zero displacement -> (..)
    def zero_disp(m):
        inner = m.group(1)
        if "," in inner:
            return "(" + inner + ")"
        return "0.w(" + inner + ")"

    ops = re.sub(r"\$0\(([^)]*)\)", zero_disp, ops)

    # uppercase remaining hex literals
    ops = re.sub(r"\$([0-9a-fA-F]+)", lambda m: "$" + m.group(1).upper(), ops)

    # whitespace normalization (project style has no spaces around commas)
    ops = re.sub(r"\s*,\s*", ",", ops)
    ops = re.sub(r"\s*/\s*", "/", ops)
    ops = re.sub(r"\s+", " ", ops).strip()
    return mn, ops


def collect_labels(insns, symbols, start, end, entry_name=None):
    call_targets = set()
    branch_targets = set()
    addrs = {ins.address for ins in insns}
    for ins in insns:
        target = instruction_target(ins)
        if target is None:
            continue
        if not (start <= target < end) or target not in addrs:
            continue
        base = base_mnemonic(ins.mnemonic)
        if base in CALL_BASE:
            call_targets.add(target)
        else:
            branch_targets.add(target)

    labels = {}
    # The range entry point is always a function label.
    labels[start] = entry_name or symbols.name_for(start) or "sub_%05X" % start
    for addr in sorted(call_targets):
        if addr not in labels:
            labels[addr] = symbols.name_for(addr) or "sub_%05X" % addr
    for addr in sorted(branch_targets):
        if addr in labels:
            continue
        labels[addr] = symbols.name_for(addr) or "loc_%05X" % addr
    return labels


def emit_code(rom, start, end, symbols, mode, out, symbolize_imm=False, entry_name=None):
    insns = disassemble_segment(rom, start, end)
    labels = collect_labels(insns, symbols, start, end, entry_name)
    for ins in insns:
        if ins.address in labels:
            out.write("%s:\n" % labels[ins.address])
        mn, ops = format_operands(ins, symbols, labels, mode, symbolize_imm)
        line = "%s%s" % (" " * 16 + mn.ljust(12), ops)
        out.write(line.rstrip() + "\n")
    return insns


def emit_data(rom, start, end, out):
    addr = start
    while addr < end:
        chunk = rom[addr:min(addr + 16, end)]
        out.write(
            " " * 16
            + "dc.b    "
            + ",".join("$%02X" % b for b in chunk)
            + "\n"
        )
        addr += len(chunk)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("start", help="start address (hex, e.g. 0x1180)")
    ap.add_argument("end", help="end address, exclusive (hex)")
    ap.add_argument("--rom", default=DEFAULT_ROM)
    ap.add_argument("--listing", default=DEFAULT_LISTING)
    ap.add_argument("--mode", choices=("project", "roundtrip"), default="project")
    ap.add_argument("--org", action="store_true", help="emit an org directive")
    ap.add_argument("--entry-name", default=None,
                    help="label name for the first address of the range")
    ap.add_argument("--symbolize-immediates", action="store_true",
                    help="replace #$ADDR immediates with known symbol names where possible")
    ap.add_argument("--data", action="append", default=[],
                    help="data range START-END to emit as dc.b (repeatable)")
    ap.add_argument("-o", "--output", default="-")
    args = ap.parse_args()

    start = int(args.start, 0)
    end = int(args.end, 0)
    rom = open(args.rom, "rb").read()

    name2addr, addr2names = parse_equates(EQUATE_FILES)
    l_name2addr, l_addr2names = parse_listing(args.listing)
    name2addr.update(l_name2addr)
    for addr, names in l_addr2names.items():
        addr2names.setdefault(addr, []).extend(names)
    symbols = Symbols(name2addr, addr2names)

    data_ranges = []
    for spec in args.data:
        a, b = spec.split("-", 1)
        data_ranges.append((int(a, 0), int(b, 0)))
    data_ranges.sort()

    out = sys.stdout if args.output == "-" else open(args.output, "w", encoding="utf-8")
    try:
        out.write("; Generated by tools/disasm.py from %s\n" % args.rom)
        out.write("; Range: $%05X-$%05X\n" % (start, end))
        if args.org:
            out.write("    org $%05X\n" % start)

        addr = start
        for dstart, dend in data_ranges:
            dstart = max(dstart, start)
            dend = min(dend, end)
            if dend <= addr or dstart >= end:
                continue
            if addr < dstart:
                emit_code(rom, addr, dstart, symbols, args.mode, out, args.symbolize_immediates, args.entry_name)
            emit_data(rom, dstart, dend, out)
            addr = dend
        if addr < end:
            emit_code(rom, addr, end, symbols, args.mode, out, args.symbolize_immediates, args.entry_name)
    finally:
        if out is not sys.stdout:
            out.close()


if __name__ == "__main__":
    main()
