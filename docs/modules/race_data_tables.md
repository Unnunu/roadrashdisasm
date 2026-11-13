# Module card: gap data tables

- **Files / ranges:** `src/data/race_data_tables.asm` (`$19A12-$19F61`),
  `src/data/race_engine_tables.asm` (`$257D0-$25855`), `src/data/race_actor_extra_tables.asm`
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

## API
| Table | Address | Size | Contract | Algorithm | Data | Hardware | Why | Dynamic | Status |
|-------|---------|------|----------|-----------|------|----------|-----|---------|--------|
| `RiderIntro_RecordTable` | ``$19A12`` |
| `RaceResults_LevelTablePos/Neg` | ``$19D32`/`$19DD2`` |
| `RaceResults_CopTablePos/Neg` | ``$19E22`/`$19EC2`` |
| `EndLevel_LevelRiderTable` | ``$19F12`` |
| `unk_257D0` | ``$257D0`` |
| `unk_257E2/E8/EE` | ``$257E2`+` |
| `unk_25802/2580A` | ``$25802`+` |

Full list: the related analysis page.
