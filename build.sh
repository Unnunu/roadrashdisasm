#!/usr/bin/env bash
set -e

AS=tools/asl
P2BIN=tools/p2bin

if [ ! -f baserom.md ]; then
    echo "baserom.md not found. Copy the reference ROM to baserom.md first, e.g.:"
    echo "    cp roadrash.md baserom.md"
    exit 1
fi

# assemble
if ! "$AS" -cpu 68000 -L -olist roadrash.lst -o roadrash.p main.asm; then
    echo "Build FAILED"
    exit 1
fi

# convert to binary
"$P2BIN" roadrash.p roadrash.md

# check for exact match
if cmp -s roadrash.md baserom.md; then
    echo "Matched OK: $(wc -c < roadrash.md) bytes"
else
    echo "No matching"
    exit 1
fi
