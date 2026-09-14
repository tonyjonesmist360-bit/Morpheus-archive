# Dependency / Version Manifest

| Dependency | Version tested against | Source | Why |
|---|---|---|---|
| FXServer | recommended artifact (≥ 7290) | fivem.net server-download | Lua 5.4, statebags, OneSync |
| qbx_core | recipe `main` (Qbox Project 1.0.0) | qbox-project | player load events, citizenid, jobs, Logout export |
| ox_lib | latest release (≥ 3.x) | overextended | notify, progressCircle, context, **radial**, inputDialog, callbacks |
| oxmysql | latest release | overextended | `MySQL.*` |
| ox_inventory | latest release | overextended | stashes, metadata items, `forceOpenInventory`, `Search`, weight exports |
| ox_target | latest release | overextended | zones, `addLocalEntity`, `addGlobalPlayer` |
| pma-voice | `main` | AvarianKnight | `setRadioChannel` / `getRadioChannel` |
| illenium-appearance | latest release | iLLeniumStudios | creator + wardrobe |
| bob74_ipl | `master` | Bob74 | house interiors |
| mm_radio (optional) | recipe | qbox-project | radio UI if present |

**Not tested against anything yet.** "Tested against" above means "written to the API of". See INTEGRATION_REPORT.md.

Pack: outbreak v0.18.0 — 27 slice resources, 8 extended, 2 progression; 8 migrations, 23 tables. Lua 5.4 everywhere (`lua54 'yes'`). All resources `fx_version 'cerulean'`.
