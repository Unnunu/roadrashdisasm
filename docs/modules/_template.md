# Module card: `<file>.asm`

- **ROM range:** `0x......`-`0x......`
- **Status:** one-line durable status (details and coverage: the analysis page)
- **Related:** `docs/analysis/<file>.md`, `docs/ram-map.md`, `docs/modules/README.md`

## Role / purpose

Two to five lines: what the module does and where it sits in the flow.

## Entry points & API

| Symbol | Address | Called by | Description |
|--------|---------|-----------|-------------|
| `<Name>` | `0x......` | caller | one-line contract |

Full API/contracts: the related analysis page.

## External calls / dependencies

- Callers and the main callees/helpers.

## Hacks / bugs / quirks

- Only durable, surprising facts; no experiment logs or open questions.

## Links

- Analysis: `docs/analysis/<file>.md`
- RAM: `docs/ram-map.md` (single RAM lookup table)
- Status: `docs/analysis/coverage.md` (single dashboard)

<!--
Rules: a card is a thin router, at most ~30 lines. Do not duplicate coverage
matrices, long RAM lists, experiment tables or step-by-step control flow; those
belong in the analysis page. Session history goes to the task file.
-->
