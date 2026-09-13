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

## First boot (2026-09-13) — B1/B2/B3 PASS on the third attempt

Environment as built: FXServer b35245, txAdmin v8.1.1, MariaDB **12.3.3**, base folder
`C:\FXServer\txData` (the recipe deployed straight into txData, no `.base` subfolder — works,
but every setup script needs `-Base "C:\FXServer\txData"`), live database
**`QboxProject_A70B55`** (not `outbreak`).

### FB-1 · MariaDB 12.3 auth plugin blocks txAdmin and oxmysql — **FIXED (environment)**

- **Symptom:** txAdmin recipe deploy: *"Database connection failed: Your database does not accept
  the required authentication method."* HeidiSQL connected fine (it uses `libmariadb.dll`), which is
  what localised it to the driver rather than the credentials.
- **Root cause:** MariaDB 11.6+ ships PARSEC, and 12.3 didn't put root on `mysql_native_password`.
  txAdmin and oxmysql both use node `mysql2`, which speaks only `mysql_native_password` and
  `caching_sha2_password`.
- **Fix:** `ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('…')`
  then restart the service. **Add this to INSTALL-WALKTHROUGH Part 3** — anyone installing current
  MariaDB hits it.

### FB-2 · Setup scripts wrote UTF-8 BOMs — **FIXED (tooling)**

- **Symptom:** `@qbx_core/shared/jobs.lua:1: unexpected symbol near '<\239>'` and the same for
  `@ox_inventory/data/items.lua`. `\239` = `0xEF`, first byte of `EF BB BF`.
- **Root cause:** Windows PowerShell 5.1's `Set-Content -Encoding UTF8` emits a BOM. Lua refuses it.
- **Blast radius — the lesson of the night.** One BOM, ~20 errors. qbx_core failed to load so its
  qb-core bridge never registered `GetCoreObject`, which killed **all 13 outbreak server files** plus
  `illenium-appearance`. ox_inventory failed so `Items`/`RegisterStash` vanished
  (`qbx_jewelery`, `qbx_taxijob`, `qbx_mechanicjob`); `GetJobs` vanished (`qbx_management`,
  `Renewed-Banking`). **None of those were real bugs.** Chasing `GetCoreObject` as a bridge problem
  would have burned the evening — the give-away was that `illenium-appearance`, untouched by us,
  failed the same way.
- **Fix:** `Write-TextNoBom` / `Add-TextNoBom` / `Remove-Bom` in `_common.ps1`, routed through
  01/04/05; `06-fix-bom.ps1` repairs an already-written tree. `Remove-Bom` reads raw **bytes** —
  `File.ReadAllText` silently swallows a BOM, so a text-level check can never detect one.

### FB-3 · Migrations applied to the wrong database — **FIXED (environment)**

- **Symptom:** `Table 'qboxproject_a70b55.outbreak_loot' doesn't exist` despite `03-apply-migrations`
  reporting 21 tables created.
- **Root cause:** the redeploy named its own database `QboxProject_A70B55`. The migrations went into
  `outbreak`, which nothing reads.
- **Fix:** `03-apply-migrations.ps1 -DbName qboxproject_a70b55`. **Always read the live
  `mysql_connection_string` out of `server.cfg` first** rather than trusting the name you asked for.
  The now-orphaned `outbreak` database can be dropped.

### FB-4 · `set sv_lan 1` locks every player out — **FIXED (pack)**

- **Symptom:** *"This server has bans or whitelisting enabled, which requires every player to have at
  least one identifier, but you have none."*
- **Root cause:** `server.cfg.additions` ended with `set sv_lan 1`. LAN mode stops FiveM issuing
  identifiers, so txAdmin rejects the connection — **and** `add_principal identifier.license:…` can
  never match, silently revoking `outbreak.debug` / `outbreak.admin` / `outbreak.dm`. The pack
  contradicted itself: `ops/OPS.md` already said to keep `sv_lan 0`.
- **Fix:** `set sv_lan 0` in `server.cfg.additions`, with a comment explaining why. Localhost-only
  comes from not forwarding port 30120, not from `sv_lan`.

### FB-5 · Semicolons in cfg comments parse as commands — **FIXED (pack)**

- **Symptom:** `[cmd] No such command ace.` / `prerequisite.` / `apply.` on every boot.
- **Root cause:** FiveM splits cfg lines on `;` **before** stripping `#` comments, so text after a
  semicolon inside a comment is executed. Three lines in `server.cfg.additions` had them.
- **Fix:** semicolons replaced. Cosmetic only, but it is noise in the one log we read all night.

### Boot result (third attempt, 14:21)

126 resources, all **21 `outbreak_*` started with zero errors**. No BOM, no `GetCoreObject`, no
missing-export cascade, no missing-table error. `ox_inventory` went 301 → **345 items** (+44 against
47 in the snippet: ~3 names such as `bread` overwrote stock definitions, which is intended).
Part 6 verified: none of the nine competing resources started.

Residual, harmless: `Couldn't find resource sessionmanager` / `hardcap` (present on the stock boot
too), `Argument count mismatch (passed 1, wanted 2)`, and txAdmin's `wmic` warnings on Windows 11.

---

## Smoke §1 — instrumentation pass (2026-09-13)

### S1-1 · Animation dictionaries — **ALL PASS**

`/ob_animcheck` → **"0 missing"**. Every dictionary in `EmoteCfg.Actions` loads.
**`KNOWN_LIMITATIONS` #8 is cleared** — the bare-progress-circle fallback is not needed anywhere.
This was the single biggest name-from-memory risk in the pack and it cost one command to retire.

### S1-2 · Prop models — 4 of 10 INVALID, 2 fixed

`/ob_models` on the ten props from `SMOKE-SCRIPT` §1:

| Model | Result | Used by | Action |
|---|---|---|---|
| `prop_cs_hand_radio` | ok | radio item | — |
| `prop_worklight_03b` | ok | placeable light | — |
| `prop_mil_crate_01` | ok | cache crate | — |
| `v_ret_ml_sweet1` | ok | 24/7 shelf | — |
| `v_ret_ml_chips1` | ok | 24/7 shelf | — |
| `prop_ecola_can` | ok | takeable can | — |
| `prop_ld_planks01` | **INVALID** | barricades + takeable plank | → **`prop_woodpile_01a`** |
| `prop_gaslamp_01` | **INVALID** | placeable lantern | → **`prop_worklight_01a`** |
| `prop_cs_body_bag` | **INVALID** | corpse marker | **unresolved** |
| `v_ret_ml_bread01` | **INVALID** | 24/7 shelf bread | **unresolved** |

Replacements were **verified with a second `/ob_models` pass**, not guessed. `v_ret_ml_bread02`
is referenced in the same config line and is also INVALID.

Candidates tested and rejected — recorded so nobody retries them:
`prop_byard_plank01`, `prop_plank_01`, `prop_bordwalk_01`, `prop_gaslamp_02`, `prop_lantern_01`,
`prop_cs_lantern`, `prop_bodybag_01`, `xm_prop_body_bag_01`, `prop_cs_bodybag`, `v_ret_ml_bread`,
`v_ret_ml_bread02`, `prop_food_bs_bread`, `v_res_tt_bread`, `prop_bread_01`.
Also confirmed ok but unused: `prop_logpile_01`, `prop_worklight_02a`.

**Working theory on the body bag:** GTA V may ship no vanilla body-bag prop — most servers add a
custom one. If so the corpse marker should become a duffel or tarp rather than keep hunting.

### S1-3 · Zombie movement clipset — `move_m@drunk@verydrunk` is bad

- **Symptom:** with `WalkStyles = { 'move_m@drunk@verydrunk', 'move_m@injured' }`, roughly half the
  zombies lurched and half walked normally. Skins were correct throughout.
- **Why it is silent:** `SetPedMovementClipset` does nothing at all if the animset never loaded.
  `zombies.lua:90-93` requests it and waits 2 s correctly, so the code is right and the *name* is wrong.
  Nothing logs. `/ob_animcheck` cannot see this — movement clipsets are not anim dictionaries.
- **Bisect:** narrowed to `move_m@drunk@verydrunk` alone → zombies did **not** lurch. So that is the
  bad name and `move_m@injured` is the good one. Now set to `move_m@injured` alone, pending confirmation.
- **Note for the config pass:** a second good clipset is wanted for variety. Any candidate needs the
  same bisect treatment — there is no validity check for animsets the way `/ob_models` checks props.

### S1-4 · Client crash during session init — cache, not content

`An exception occurred (c0000005 at 0x141684c8d) during execution of the INIT_SESSION function for
CExtraContentWrapper.` Game-side crash while mounting DLC content; the server was healthy throughout
(all 21 resources up). Cleared `FiveM.app\data\{cache,server-cache,server-cache-priv}`. Recurrence
points at GTA V file integrity rather than the pack — nothing in `[outbreak]` streams assets.

---

## Deferred

- **illenium-appearance creator hangs and traps the player.** `SMOKE-SCRIPT` §2 / checklist C1.
  The creator opens, its NUI throws `Cannot read properties of undefined (reading 'masks')` and
  `(reading 'hats')` in `illenium-appearance/web/dist/assets/index.*.js`, no UI renders, the
  callback never fires. Dropping our config table did **not** help, so the argument shape is not the
  cause — it is inside illenium or its Qbox configuration. Contained in `identity.lua` by bounding
  the `IsNuiFocused()` wait at 90 s so a hang can no longer strand a player; the creator itself is
  still broken. **Next step:** stop `outbreak_identity` and trigger illenium's own creator standalone
  to establish whether our call is involved at all; then check `illenium-appearance/config.lua`
  against `outbreak_identity/data/illenium_config_notes.md`, which the pack never applied.
- **`outbreak_binds` registers invalid controller keys.** `Invalid key name DPAD_DOWN / DPAD_UP /
  BUTTON_B / DPAD_LEFT / DPAD_RIGHT` on every client start, so no pad binding registers.
  `SMOKE-SCRIPT` §13 / checklist G2. Keyboard binds are unaffected.
- **Restarting `outbreak_core` stops 14 dependents and restarts only core.** Anything declaring it
  as a dependency is left stopped. Restart the whole server instead; only leaf resources
  (`outbreak_hud`, `outbreak_wheel`, `outbreak_debug`, `outbreak_dm`, `outbreak_faction`,
  `outbreak_identity`, `outbreak_skills`) are safe to restart individually.
- **`server.cfg.additions` is fixed in the pack but not in the live tree.** The `sv_lan` and
  semicolon fixes only reach the server on the next deploy, since `05-append-cfg.ps1` is
  marker-guarded and will not re-append.

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
