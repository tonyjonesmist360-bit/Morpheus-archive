# DIAGNOSTIC REPORT (static, pre-boot)

Resources scanned: 35  ·  files: 159


## ERROR (0)


## WARN (0)


## INFO (6)

- **outbreak_debug** — handler 'onClientResourceStart' registered but never triggered (dead or external)
- **outbreak_debug** — handler 'onResourceStart' registered but never triggered (dead or external)
- **outbreak_faction** — data/jobs_snippet.lua is a paste-in fragment (not loaded, not syntax-checked as a file)
- **outbreak_items** — data/ox_items_snippet.lua is a paste-in fragment (not loaded, not syntax-checked as a file)
- **outbreak_status** — handler 'onResourceStop' registered but never triggered (dead or external)
- **outbreak_weapons** — data/weapons_snippet.lua is a paste-in fragment (not loaded, not syntax-checked as a file)

## What this pass cannot see (runtime only)
- Native names/signatures, animation dictionary + clip names, prop model names, blip sprites — all from memory
- World coordinates (houses, stations, camps, decoy, spawn points)
- Framework API surface: qb-core bridge functions, `exports.qbx_core:Logout`, `illenium-appearance` exports, `mm_radio` exports, `pma-voice` `getRadioChannel`
- ox_inventory client weight exports; ox_lib `registerRadial` payload shape; NUI focus + keyboard behaviour
- OneSync entity ownership behaviour (zombie migration, wave election), `TaskWarpPedIntoVehicle` on anim-locked peds
- JavaScript inside NUI html (not parsed here)
