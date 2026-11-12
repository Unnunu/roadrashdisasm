#!/usr/bin/env python3
"""Shared work-RAM layout tables and readers for the race analysis tools.

The race tools (`race_dump.py`, `ram_diff.py`) decode a 64 KiB dump of work RAM
($FF0000-$FFFFFF). This module parses the equates from `src/core/ram_const.asm`
and owns the small amount of layout knowledge needed by both tools:

- actor struct size and field widths,
- named actor slots and their load addresses,
- active/free/visible list formats,
- object array record layout.

Only layout is encoded here. Field semantics stay in the analysis docs; unknown
offsets are reported as unnamed instead of being guessed.
"""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EQUATE_FILE = ROOT / "src/core/ram_const.asm"

DEFAULT_BASE = 0xFF0000
RAM_SIZE = 0x10000

ACTOR_SIZE = 0x80
OBJECT_SIZE = 0x14

ACTIVE_COUNT = 0xFF1A06
ACTOR_LIST = 0xFF1A08
ACTIVE_LIST = 0xFF1A0C
OPPONENT_FREE_LIST = 0xFF1982
TRAFFIC_FREE_LIST = 0xFF19C4
VISIBLE_LIST = 0xFF1D50
OBJECT_ARRAY = 0xFFD37C
OBJECT_ENTRY_COUNT = 0xFFDE72
TRACK_OBJECT_COUNT = 0xFFD7CA
EXTRA_ACTOR_SLOT = 0xFF2FAA

# Offsets that are read/written as longs or bytes; everything else is a word.
LONG_OFFSETS = {0x04, 0x1E, 0x26}
BYTE_OFFSETS = set(range(0x68, 0x79))

# Object record fields actually documented in docs/analysis/road_render.md.
OBJECT_FIELDS = [
    (0x00, "RoadObject_X"),
    (0x02, "RoadObject_Y"),
    (0x04, "RoadObject_Scale"),
    (0x06, "RoadObject_Limit"),
    (0x08, "RoadObject_Shape"),
    (0x0A, "RoadObject_Flags"),
    (0x0C, "RoadObject_XOffset"),
    (0x0E, "RoadObject_ReservedE"),
    (0x10, "RoadObject_Reserved10"),
    (0x12, "RoadObject_Shape2"),
]

EQUATE_RE = re.compile(
    r"^\s*([A-Za-z_][\w.$]*)\s+equ\s+\$([0-9A-Fa-f]+)\s*(?:;.*)?$"
)

WIDTH_NAMES = {1: "byte", 2: "word", 4: "long"}


def parse_equates(path: Path = EQUATE_FILE) -> dict[str, int]:
    """Return `name -> value` for every `equ $XXXX` line in path."""
    values: dict[str, int] = {}
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return values
    for line in text.splitlines():
        m = EQUATE_RE.match(line)
        if m:
            values.setdefault(m.group(1), int(m.group(2), 16))
    return values


def parse_address(text: str) -> int:
    """Accept `0xff0000`, `$FF0000`, `ff0000` or decimal."""
    text = text.strip()
    if text.startswith("$"):
        return int(text[1:], 16)
    if text.lower().startswith("0x"):
        return int(text, 16)
    if re.fullmatch(r"[0-9A-Fa-f]+", text):
        return int(text, 16)
    return int(text, 10)


def actor_symbols(equates: dict[str, int]) -> dict[int, str]:
    """Map actor-struct offset -> first `RaceActor_*` symbol at that offset."""
    symbols: dict[int, str] = {}
    for name, value in equates.items():
        if name.startswith("RaceActor_") and 0 <= value < ACTOR_SIZE:
            symbols.setdefault(value, name)
    return symbols


def object_symbols(equates: dict[str, int]) -> dict[int, str]:
    symbols: dict[int, str] = {}
    for offset, name in OBJECT_FIELDS:
        symbols[offset] = name
    return symbols


def actor_fields() -> list[tuple[int, int]]:
    """Return `(offset, width)` for the whole actor struct without overlaps."""
    fields: list[tuple[int, int]] = []
    offset = 0
    while offset < ACTOR_SIZE:
        if offset in LONG_OFFSETS and offset + 4 <= ACTOR_SIZE:
            fields.append((offset, 4))
            offset += 4
        elif offset in BYTE_OFFSETS or offset & 1:
            fields.append((offset, 1))
            offset += 1
        else:
            fields.append((offset, 2))
            offset += 2
    return fields


ACTOR_FIELDS = actor_fields()


def actor_field_at(offset: int) -> tuple[int, int] | None:
    for start, width in ACTOR_FIELDS:
        if start <= offset < start + width:
            return start, width
    return None


def actor_slots(equates: dict[str, int]) -> list[tuple[int, str]]:
    """Named 0x80-byte actor slots present in work RAM."""
    slots: list[tuple[int, str]] = []

    def add(address: int | None, name: str) -> None:
        if address is not None and all(address != a for a, _ in slots):
            slots.append((address, name))

    add(equates.get("RacePlayerA"), "RacePlayerA")
    add(equates.get("ram_FF1F2A"), "ram_FF1F2A")
    for index in range(2, 16):
        name = f"Race_ActorStruct_{index}"
        add(equates.get(name), name)
    add(equates.get("RacePlayerB"), "RacePlayerB")
    add(equates.get("Race_StaticActor_0"), "Race_StaticActor_0")
    add(equates.get("Race_StaticActor_1"), "Race_StaticActor_1")
    add(EXTRA_ACTOR_SLOT, "ram_FF2FAA")
    return slots


def static_slots(equates: dict[str, int]) -> list[tuple[int, str]]:
    return [
        (equates[name], name)
        for name in ("Race_StaticActor_0", "Race_StaticActor_1")
        if name in equates
    ]


def actor_slot_for(address: int, slots: list[tuple[int, str]]) -> tuple[int, str] | None:
    for base, name in slots:
        if base <= address < base + ACTOR_SIZE:
            return base, name
    return None


class Dump:
    """Big-endian view of a work-RAM dump with bounds-checked reads."""

    def __init__(self, path: str | Path, base: int = DEFAULT_BASE) -> None:
        self.path = Path(path)
        self.base = base
        self.data = self.path.read_bytes()
        self.size = len(self.data)

    def _offset(self, address: int) -> int | None:
        offset = address - self.base
        if 0 <= offset < self.size:
            return offset
        return None

    def read(self, address: int, width: int) -> int | None:
        offset = self._offset(address)
        if offset is None or offset + width > self.size:
            return None
        return int.from_bytes(self.data[offset:offset + width], "big")

    def u8(self, address: int) -> int | None:
        return self.read(address, 1)

    def u16(self, address: int) -> int | None:
        return self.read(address, 2)

    def u32(self, address: int) -> int | None:
        return self.read(address, 4)

    def valid(self, address: int, width: int = 1) -> bool:
        offset = self._offset(address)
        return offset is not None and offset + width <= self.size


def read_pointer_list(dump: Dump, address: int, limit: int = 32) -> tuple[list[int], bool]:
    """Read a long pointer list terminated by `$FFFFFFFF`."""
    entries: list[int] = []
    cursor = address
    for _ in range(limit):
        value = dump.u32(cursor)
        if value is None:
            return entries, False
        entries.append(value)
        cursor += 4
        if value == 0xFFFFFFFF:
            return entries, True
    return entries, False


def read_free_list(dump: Dump, address: int, limit: int = 32) -> tuple[int | None, list[int], bool]:
    """Read a free list: word count followed by unaligned long entries."""
    count = dump.u16(address)
    if count is None:
        return None, [], False
    entries: list[int] = []
    complete = count <= limit
    for index in range(min(count, limit)):
        value = dump.u32(address + 2 + 4 * index)
        if value is None:
            complete = False
            break
        entries.append(value)
    return count, entries, complete


def read_visible_list(dump: Dump, address: int, limit: int = 128) -> tuple[list[int], bool]:
    """Read a word index list terminated by `$FFFF`."""
    entries: list[int] = []
    cursor = address
    for _ in range(limit):
        value = dump.u16(cursor)
        if value is None:
            return entries, False
        if value == 0xFFFF:
            return entries, True
        entries.append(value)
        cursor += 2
    return entries, False


def object_count(dump: Dump, limit: int = 64) -> int:
    """Count object records, using the runtime count and falling back to `$FFFF`."""
    count = dump.u16(OBJECT_ENTRY_COUNT)
    if count is not None and 0 < count <= limit:
        return count
    for index in range(limit):
        value = dump.u16(OBJECT_ARRAY + index * OBJECT_SIZE)
        if value is None or value == 0xFFFF:
            return index
    return limit


def object_field_at(offset: int) -> tuple[int, str] | None:
    for start, name in OBJECT_FIELDS:
        width = 2
        if start <= offset < start + width:
            return start, name
    return None


def format_value(value: int | None, width: int) -> str:
    if value is None:
        return "??" * width
    return f"{value:0{width * 2}X}"


def symbol_for(offset: int, symbols: dict[int, str]) -> str:
    return symbols.get(offset, "(unnamed)")
