# DIAG BEFORE — 2026-09-15T04:26Z — 5f8a176

## tools_diag.py
# DIAGNOSTIC REPORT (static, pre-boot)

Resources scanned: 37  ·  files: 179


## ERROR (0)


## WARN (0)


## INFO (6)

- **outbreak_debug** — handler 'onClientResourceStart' registered but never triggered (dead or external)
- **outbreak_debug** — handler 'onResourceStart' registered but never triggered (dead or external)
- **outbreak_director** — handler 'onResourceStop' registered but never triggered (dead or external)
- **outbreak_faction** — data/jobs_snippet.lua is a paste-in fragment (not loaded, not syntax-checked as a file)
- **outbreak_items** — data/ox_items_snippet.lua is a paste-in fragment (not loaded, not syntax-checked as a file)
- **outbreak_weapons** — data/weapons_snippet.lua is a paste-in fragment (not loaded, not syntax-checked as a file)

## What this pass cannot see (runtime only)
- Native names/signatures, animation dictionary + clip names, prop model names, blip sprites — all from memory
- World coordinates (houses, stations, camps, decoy, spawn points)
- Framework API surface: qb-core bridge functions, `exports.qbx_core:Logout`, `illenium-appearance` exports, `mm_radio` exports, `pma-voice` `getRadioChannel`
- ox_inventory client weight exports; ox_lib `registerRadial` payload shape; NUI focus + keyboard behaviour
- OneSync entity ownership behaviour (zombie migration, wave election), `TaskWarpPedIntoVehicle` on anim-locked peds
- JavaScript inside NUI html (not parsed here)


## tools_diag2.py
# SYSTEMS CHECK — pass 2 (static)

Resources: 37 · Lua files: 158 · migrations: 8 · items defined: 68 · commands: 88


## ERROR (0)

## WARN (0)

## INFO (0)

## tools_diag3.py
# SYSTEMS CHECK - pass 3 (classes that slipped past passes 1 and 2)

Resources: 37


## ERROR (0)


## WARN (0)


## INFO (0)


## tools_luac.py
# LUA PARSE (luac5.4) - 159 files

## ERROR (0)

