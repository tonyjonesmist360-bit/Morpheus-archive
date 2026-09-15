# DIAG AFTER — 2026-09-15T04:52Z — e51f951+wip

## tools_diag.py
# DIAGNOSTIC REPORT (static, pre-boot)

Resources scanned: 39  ·  files: 186


## ERROR (0)


## WARN (0)


## INFO (6)

- **outbreak_debug** — handler 'onClientResourceStart' registered but never triggered (dead or external)
- **outbreak_debug** — handler 'onResourceStart' registered but never triggered (dead or external)
- **outbreak_debug** — handler 'onResourceStop' registered but never triggered (dead or external)
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

Resources: 39 · Lua files: 165 · migrations: 8 · items defined: 71 · commands: 95


## ERROR (0)

## WARN (0)

## INFO (0)

## tools_diag3.py
# SYSTEMS CHECK - pass 3 (classes that slipped past passes 1 and 2)

Resources: 39


## ERROR (0)


## WARN (0)


## INFO (0)


## tools_luac.py
# LUA PARSE (luac5.4) - 166 files

## ERROR (0)

