#!/usr/bin/env bash
set -e

AS=tools/asl
P2BIN=tools/p2bin
BUILD=build
OUT="$BUILD/roadrash.bin"

if [ ! -f baserom.md ]; then
    echo "baserom.md not found. Copy the full reference ROM to baserom.md first."
    exit 1
fi

mkdir -p "$BUILD"

# assemble
if ! "$AS" -cpu 68000 -L -olist "$BUILD/roadrash.lst" -o "$BUILD/roadrash.p" main.asm; then
    echo "Build FAILED"
    exit 1
fi

# convert to binary
"$P2BIN" "$BUILD/roadrash.p" "$OUT"

# The sources currently cover only the beginning of the full ROM, so compare the
# built prefix against baserom.md. As more of the ROM is disassembled the built
# image grows; it must always stay byte-identical to the ROM prefix.
built=$(wc -c < "$OUT" | awk '{print $1}')
ref=$(wc -c < baserom.md | awk '{print $1}')
if [ "$built" -gt "$ref" ]; then
    echo "Built image ($built bytes) is larger than baserom.md ($ref bytes)"
    echo "No matching"
    exit 1
fi

if cmp -s -n "$built" "$OUT" baserom.md; then
    echo "Matched OK: $built bytes of $ref bytes"
    rm -f "$OUT"
else
    echo "No matching"
    first=$(cmp -l -n "$built" "$OUT" baserom.md | head -1 || true)
    if [ -n "$first" ]; then
        echo "First difference: $first  (byte#, built, baserom; octal values)"
    fi
    echo "Built image kept at $OUT"
    exit 1
fi
