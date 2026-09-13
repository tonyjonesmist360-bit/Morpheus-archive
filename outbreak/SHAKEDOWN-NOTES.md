# SHAKEDOWN NOTES

Format: step · symptom · root cause · patch · status.

---

## Pre-boot pass (2026-09-12, before first start)

Framework API surface checked against current upstream source rather than from memory.
This is the class of bug `tools_diag*.py` explicitly cannot see.

### PB-1 · `player.Functions.SetMoney` does not exist in Qbox — **FIXED**

- **Step:** `FIRST_BOOT_CHECKLIST` S1/S2/S4 + `SMOKE-SCRIPT` §3 (would have failed before the first frame)
- **Symptom (predicted):** on the first join of a brand-new character,
  `outbreak_spawn` errors `attempt to call a nil value (field 'SetMoney')` and the
  `QBCore:Server:PlayerLoaded` handler aborts at that line. Everything below it never runs:
  no starter kit, no seeded needs, no scenario time/weather, no `outbreak:client:freshSpawn`
  (so no story text), no scenario radio transmission.
- **Root cause:** `qbx_core/server/player.lua` builds `self.Functions` with `AddMoney` and
  `RemoveMoney` but **no `SetMoney`**. The qb-core bridge does not add one either —
  `bridge/qb/server/functions.lua` has no `SetMoney`. `SetMoney` exists only as a
  top-level export: `exports.qbx_core:SetMoney(identifier, moneyType, amount, reason)`.
  The call was also unprotected, so the failure cascaded through the whole spawn flow.
- **Patch:** `outbreak_spawn/server/spawn.lua:15`
  ```lua
  - player.Functions.SetMoney('cash', 0, 'outbreak-wipe'); player.Functions.SetMoney('bank', 0, 'outbreak-wipe')
  + exports.qbx_core:SetMoney(src, 'cash', 0, 'outbreak-wipe'); exports.qbx_core:SetMoney(src, 'bank', 0, 'outbreak-wipe')
  ```
  One line, anchor verified unique. Deliberately **not** wrapped in `pcall` — during the
  shakedown a money-wipe failure should be loud, not swallowed.
- **Status:** applied in the pack folder. Both analyzers re-run clean
  (0 ERROR / 0 WARN / same 8 baseline INFO). **Untested on FXServer.**

### PB-2 · `exports['pma-voice']:getRadioChannel` does not exist — **no change needed**

- **Relates to:** `KNOWN_LIMITATIONS.md` #16
- **Finding:** confirmed absent. `pma-voice/client/module/radio.lua` exports
  `setRadioChannel`, `SetRadioChannel`, `addPlayerToRadio`, `removePlayerFromRadio`,
  `toggleRadioAnim`, `setDisableRadioAnim`, `getRadioAnimState`, `setRadioTalkAnim`,
  `addRadioDisableBit`, `removeRadioDisableBit` — **there is no getter.**
- **Why no patch:** both call sites (`outbreak_radio/client/radio.lua:28` and `:38`) are already
  `pcall`-guarded and fall back to the resource's own `onChannel`, which `setRadioChannel`
  (which does exist) keeps current. Degrades cleanly.
- **Residual risk:** if a channel is changed through `mm_radio`'s own UI rather than through
  `outbreak_radio`, `onChannel` drifts out of sync. Watch at `SMOKE-SCRIPT` §3.

### PB-3 · Verified-good — no action

| Assumption | Result |
|---|---|
| `exports['qb-core']:GetCoreObject()` (13 server files, line 2, unprotected) | **OK.** `qbx_core/fxmanifest.lua` declares `provide 'qb-core'`; `bridge/qb/server/main.lua` registers `GetCoreObject`. Gated by `GetConvar('qbx:enablebridge', 'true')` — **default enabled**, nothing to turn on. |
| `QBCore:Server:PlayerLoaded` (7 handlers) | **OK.** Triggered by `qbx_core/server/player.lua` in `CreatePlayer`. |
| `exports.qbx_core:Logout(source)` (2 sites) | **OK.** Exact signature match. |
| `player.Functions.Logout()` (fallback) | **OK.** Exists on the player object. |
| `player.Functions.SetJob(job, grade)` | **OK.** Exists, signature matches. |
| `pma-voice:radioActive` / `pma-voice:setTalkingOnRadio` handlers | **OK.** Both are genuinely triggered by pma-voice. The analyzers' "never triggered" INFO is correct and harmless — they are external. |
| fxmanifest file references | **OK.** Every declared `client/*.lua`, `server/*.lua`, `html/*.html` exists on disk. |
| Declared `dependencies` | **OK.** All resolve to slice resources or foundation resources the Qbox recipe ships. **None** name a resource disabled by INSTALL-WALKTHROUGH Part 6 — no "dependency not found" from our side. |
| Duplicate `RegisterCommand` names across 66 commands | **OK.** None. |
| Top-level (load-time) code | **OK.** Only `GetCoreObject()` and function definitions. No other boot hazard. |
| `outbreak_world_items.id` has no AUTO_INCREMENT | **Intentional.** `worlditems.lua` assigns ids itself via `nextId`. |

### PB-4 · `outbreak_faction` never loads oxmysql — **FIXED**

- **Step:** `SMOKE-SCRIPT` §0 / checklist B2 ("no red `outbreak_*` errors on join") — fires on **every join**
- **Symptom (predicted):** `attempt to index a nil value (global 'MySQL')` from `outbreak_faction`
  every time any player connects. Reputation then silently reads 0 for everyone, and `addRep`
  throws again on every faction reputation change.
- **Root cause:** `outbreak_faction/fxmanifest.lua` declared
  `server_scripts { 'server/faction.lua' }` with **no `@oxmysql/lib/MySQL.lua`**, but
  `server/faction.lua` uses `MySQL.query.await` (line 52) and `MySQL.prepare` (line 61).
  `repLoad` is wired to `QBCore:Server:PlayerLoaded`, so it runs on connect.
  The other nine MySQL-using resources all include it correctly — faction is the only one that missed.
- **Patch:** `outbreak_faction/fxmanifest.lua`
  ```lua
  - server_scripts { 'server/faction.lua' }
  + server_scripts { '@oxmysql/lib/MySQL.lua', 'server/faction.lua' }
  ```
- **Status:** applied. Both analyzers clean. **Untested on FXServer.**
- **Analyzer gap worth knowing:** neither `tools_diag.py` nor `tools_diag2.py` cross-checks
  manifest includes against the globals a file actually uses. Both reported 0/0 with this bug present.

### PB-5 · Second-pass checks that came back clean — no action

| Check | Result |
|---|---|
| Every resource using `lib.*` includes `@ox_lib/init.lua` | **OK** — 18/18 |
| Every resource using `MySQL.*` includes `@oxmysql/lib/MySQL.lua` | **Was 9/10** — see PB-4, now 10/10 |
| `cache.*` (ox_lib global) used without ox_lib | **None** |
| Cross-resource config globals (`NeedsCfg`, `EmoteCfg`, `LootCfg`, `WorldItemsCfg`) | **OK** — every consumer includes the defining file. `NoiseCfg` is file-local to `outbreak_noise/client/noise.lua`, by design. |
| Internal `exports.outbreak_*` calls resolve to a definition | **OK** |
| Calls into HELD groups (`outbreak_intel`, `outbreak_opportunities`, `outbreak_vehicles`) | **OK — all 6 sites `pcall`-guarded.** They no-op while progression/extended stay commented out, and light up when enabled. `outbreak_items/server/loot.lua:20` looks unguarded on its own line; the `pcall` wrapper is on line 19. |
| `outbreak:*` events triggered with no handler | **None.** `outbreak:event:` is built by concatenation in `director.lua`; `outbreak:event:horde` is registered. |
| `outbreak_worlditems` referencing `@outbreak_opportunities/...` | **Not an include** — it is a comment explaining why that is not possible; entropy reads exports instead. |

---

## Deferred

- **`illenium-appearance` export names — UNVERIFIED.** `startPlayerCustomization` (2 sites) and
  `setPlayerOutfit` (1 site). Could not confirm the export registrations in current upstream;
  they were not in `client/client.lua` where expected. **Both call sites are `pcall`-guarded**, so a
  wrong name means the creator silently never opens — no crash. `SMOKE-SCRIPT` §2 / checklist C1
  settles this in five seconds of real play. Do not rename on a guess.
- **`qbx_medical` / `qbx_police` removal fallout.** INSTALL-WALKTHROUGH Part 6 moves them out of
  `[qbx]`. Other `[qbx]` job resources may declare them as dependencies. Collect the resource names
  from the Part 6e boot; decide then, not at 9pm.
- **`qbx_radialmenu` vs `outbreak_wheel` (G)** and **`qbx_seatbelt` vs `outbreak_binds`.** Not on the
  pack's disable list. Do not pre-emptively move. First suspect if the wheel misbehaves in §4.
- **Everything in `KNOWN_LIMITATIONS.md` #8, #19, #20** (anim dicts, prop models) is unreachable
  statically. That is exactly what `SMOKE-SCRIPT` §1 (`/ob_animcheck`, `/ob_models`, `/ob_walk`)
  exists to resolve — run it before anything else.
