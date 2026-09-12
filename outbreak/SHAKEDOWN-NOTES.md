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
