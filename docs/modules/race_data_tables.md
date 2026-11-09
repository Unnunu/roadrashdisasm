# Module card: gap data tables

- **Files / ranges:** `race_data_tables.asm` (`$19A12-$19F61`),
  `race_engine_tables.asm` (`$257D0-$25855`), `race_actor_extra_tables.asm`
  (`$259B6-$25EBF`)
- **Status:** tables extracted from the ROM gap and assembled from source; semantics
  partial (audio timing/extra tables TODO)
- **Related:** `docs/analysis/race_data_tables.md`, `docs/analysis/rider_intro.md`,
  `docs/analysis/race_results.md`, `docs/analysis/endlevel.md`,
  `docs/analysis/race_actors.md`, `docs/ram-map.md`

## Role / purpose

Replaces the raw ROM bridge at the known table boundaries with real source data:
the rider-intro quote/image records, the results level/cop portrait tables, the
end-level rider table, the race physics/engine constants and the actor/AI data tables.

## Coverage matrix

| Table | Address | Size | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|-------|---------|------|----------|-----------|------|----------|-----|---------|--------|
| `RiderIntro_RecordTable` | `$19A12` | `$320` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `RaceResults_LevelTablePos/Neg` | `$19D32`/`$19DD2` | `$A0`/`$50` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `RaceResults_CopTablePos/Neg` | `$19E22`/`$19EC2` | `$A0`/`$50` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `EndLevel_LevelRiderTable` | `$19F12` | `$50` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `unk_257D0` | `$257D0` | `$12` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `unk_257E2/E8/EE` | `$257E2`+ | `$26` | [~] | - | [x] | - | [~] | [ ] | partial |
| `unk_25802/2580A` | `$25802`+ | `$10` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `unk_25812` | `$25812` | `$44` | [~] | - | [x] | - | [~] | [ ] | partial |
| `unk_259B6/259C0` | `$259B6`+ | `$5A` | [~] | - | [x] | - | [~] | [ ] | partial |
| `unk_25A10` | `$25A10` | `$34` | [x] | - | [x] | - | [x] | [ ] | analyzed |
| `unk_25A44/25AC4/25B50/25B70` | `$25A44`+ | `$4DC` | [~] | - | [x] | - | [~] | [ ] | partial |

Detailed analysis: `docs/analysis/race_data_tables.md`.
