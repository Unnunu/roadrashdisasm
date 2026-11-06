#!/usr/bin/env bash
set -e

AS=tools/asl
P2BIN=tools/p2bin

if [ ! -f baserom.md ]; then
    echo "baserom.md not found. Copy the reference ROM to baserom.md first."
    exit 1
fi

# assemble
if ! "$AS" -cpu 68000 -L -olist roadrash.lst -o roadrash.p main.asm; then
    echo "Build FAILED"
    exit 1
fi

# convert to binary
"$P2BIN" roadrash.p roadrash.md

# The sources currently cover only the beginning of the full ROM, so compare the
# built prefix against baserom.md. As more of the ROM is disassembled the built
# image grows; it must always stay byte-identical to the ROM prefix.
built=$(wc -c < roadrash.md)
ref=$(wc -c < baserom.md)
if [ "$built" -gt "$ref" ]; then
    echo "Built image ($built bytes) is larger than baserom.md ($ref bytes)"
    echo "No matching"
    exit 1
fi

if cmp -s -n "$built" roadrash.md baserom.md; then
    echo "Matched OK: $built bytes of $ref bytes"
else
    echo "No matching"
    exit 1
fi
