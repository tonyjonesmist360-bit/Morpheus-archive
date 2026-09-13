# Configuration reference (slice)

| File | Knobs |
|---|---|
| `outbreak_core/shared/config.lua` | `MaxPerPlayer`, `SpawnRadius`, `NightMultiplier`, `HeadshotOnly`, `InfectionChancePerHit`, `AggroRadius`, `Variants` (weights, night-only), `Weather` (noise/spawn multipliers), `Hordes` |
| `outbreak_needs/shared/config.lua` | decay rates, `SprintMultiplier`, infection stages/`fatal`, `WoundTypes` (bleed, treat items), `BoneToPart`, `Encumbrance` |
| `outbreak_noise/client/noise.lua` (`NoiseCfg`) | per-action noise values, `Decay` |
| `outbreak_items/shared/loot_config.lua` | container models → tables, `Tables`, `RespawnMinutes`, `SearchSeconds` |
| `outbreak_items/data/ox_items_snippet.lua` | **the item list** — paste into `ox_inventory/data/items.lua` |
| `outbreak_housing/shared/config.lua` | `Houses` (door, interior), `OccupiedChance`, `SearchSpots`, `Stories`, `BarricadeCost`, `KeyItem` |
| `outbreak_down/shared/config.lua` | `DeathMode` (permadeath/losegear/keep), `PvP`, timers, `Respawn.points` |
| `outbreak_spawn/shared/config.lua` | `Scenarios` (pos, story, kit, hour, weather, radio, starting needs); convar `ob_scenario` |
| `outbreak_identity/shared/config.lua` | `FormerLives`, `Traits` |
| `outbreak_skills/shared/config.lua` | XP per action, level effects, trait starts/multipliers |
| `outbreak_world/shared/config.lua` | `DayLengthMinutes`, `Blackout`, weather pool |
| `outbreak_emotes/shared/emotes.lua` | emotes, `Actions` (anim dicts for every progress action) |
| `outbreak_binds/client/binds.lua` | every key + pad default |
| `outbreak_faction/shared/config.lua` | jobs, armory/cache, radio channels |
| convars | `ob_debug` (0/1), `ob_scenario` |

Other resources to touch once: `illenium-appearance/config.lua` (see `outbreak_identity/data/illenium_config_notes.md`), `qbx_core/shared/jobs.lua` (see `outbreak_faction/data/jobs_snippet.lua`), ox_target keybind (Settings → E).
