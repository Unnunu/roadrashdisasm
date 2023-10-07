#!/usr/bin/bash

# build
if tools/asm68k -i main.asm -o roadrash.md ; then
    echo "Build OK"
else
    echo "Build FAILED"
    exit
fi

# check for match
cmp_result=$(cmp roadrash.md baserom.md 2>&1)
if [[ "$cmp_result" == *"EOF"* ]]; then
    matched_size=$(wc -c roadrash.md | awk '{print $1;}')
    total_size=$(wc -c baserom.md | awk '{print $1;}')
    echo "Matched OK: $matched_size bytes of $total_size bytes"
else
    echo "No matching"
    exit
fi
