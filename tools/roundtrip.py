#!/usr/bin/env python3
"""Round-trip check: ROM range -> generated AS -> assemble -> compare bytes.

Usage:
    python3 tools/roundtrip.py 0x1180 0x13c0
    python3 tools/roundtrip.py 0x7e6a2 0x7ea66
    python3 tools/roundtrip.py 0x1180 0x13c0 --data 0x1200-0x1210

The generated source is self-contained (raw external references plus an `org`),
assembled with the project toolchain, and compared against `baserom.md`.
"""
import argparse
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def run(cmd):
    return subprocess.run(
        cmd, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
    )


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("start")
    ap.add_argument("end")
    ap.add_argument("--data", action="append", default=[],
                    help="data range START-END passed to tools/disasm.py")
    args = ap.parse_args()

    start, end = int(args.start, 0), int(args.end, 0)
    with open(os.path.join(ROOT, "baserom.md"), "rb") as fh:
        rom = fh.read()
    expected = rom[start:end]

    with tempfile.TemporaryDirectory() as td:
        asm = os.path.join(td, "range.asm")
        obj = os.path.join(td, "range.p")
        out = os.path.join(td, "range.bin")

        cmd = [sys.executable, "tools/disasm.py", hex(start), hex(end),
               "--mode", "roundtrip", "--org", "-o", asm]
        for spec in args.data:
            cmd += ["--data", spec]
        r = run(cmd)
        if r.returncode:
            print(r.stdout)
            return 1

        r = run(["tools/asl", "-cpu", "68000", "-o", obj, asm])
        if r.returncode:
            print(r.stdout)
            return 1

        r = run(["tools/p2bin", obj, out])
        if r.returncode:
            print(r.stdout)
            return 1

        with open(out, "rb") as fh:
            built = fh.read()

    if built == expected:
        print("Round-trip OK: %d bytes ($%05X-$%05X)" % (len(expected), start, end))
        return 0

    n = min(len(built), len(expected))
    i = 0
    while i < n and built[i] == expected[i]:
        i += 1
    print("Round-trip FAIL at +0x%X (built %d, expected %d)" %
          (i, len(built), len(expected)))
    lo = max(0, i - 8)
    print("built:", built[lo:i + 16].hex(" "))
    print("base :", expected[lo:i + 16].hex(" "))
    return 1


if __name__ == "__main__":
    sys.exit(main())
