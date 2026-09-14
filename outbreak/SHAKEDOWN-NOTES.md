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

## External API verification pass (2026-09-13, static, against upstream source)

Checked every third-party name the pack calls, against the actual upstream repository rather
than memory. This retires several `KNOWN_LIMITATIONS` entries outright.

| API | Uses | Verdict |
|---|---|---|
| `ox_target:addSphereZone` | 16 | **OK** — `function(data)` |
| `ox_target:addLocalEntity` | 6 | **OK** — `(arr, options)` |
| `ox_target:addModel` | 4 | **OK** — `(arr, options)` |
| `ox_target:addGlobalVehicle` | 1 | **OK** |
| `ox_target:addGlobalPlayer` | 1 | **OK** |
| `lib.notify` | 81 | **OK** |
| `lib.inputDialog` | 24 | **OK** |
| `lib.registerContext` / `showContext` | 25 | **OK** |
| `lib.progressCircle` | 9 | **OK** |
| `lib.callback.register` / `await` | 16 | **OK** |
| `lib.showTextUI` / `hideTextUI` | 9 | **OK** |
| `lib.registerRadial` / `showRadial` | 3 | **OK**, and see below |
| `ox_inventory` server exports | 60+ | **OK** — incl. `GetItemCount`, `forceOpenInventory` |
| `qbx_core` bridge + `Logout` + `SetJob` | 16 | **OK** (see PB-3) |
| `pma-voice:setRadioChannel` | 4 | **OK** |
| `pma-voice:getRadioChannel` | 4 | **DOES NOT EXIST** — guarded, see PB-2 |
| `illenium-appearance:startPlayerCustomization` | 2 | name **OK**, call is wrong — see EV-1 |
| `illenium-appearance:setPlayerOutfit` | 1 | **UNVERIFIED**, pcall-guarded |
| `mm_radio:openRadio` | 1 | **UNVERIFIED**, could not reach source |

### Retired: `lib.registerRadial` payload shape

`KNOWN_LIMITATIONS` listed this as unverified. It is **correct as written**. ox_lib defines
`RadialMenuProps = { id, items }` and `RadialItem = { icon, label, menu?, onSelect?, keepOpen? }`.
Only `lib.addRadialItem` requires a per-item `id`; items passed inside `registerRadial` do not.
`outbreak_wheel` uses the latter, with `label` + `icon` + `onSelect`/`menu`. No change needed.

### EV-1 · The creator callback throws the appearance away — **unresolved, do not guess**

illenium's documented usage is:

```lua
exports['illenium-appearance']:startPlayerCustomization(function(appearance)
  if appearance then --[[ caller persists it ]] else --[[ cancelled ]] end
end, config)
```

The caller is responsible for saving the returned appearance. `outbreak_identity` passes
`function() end` at **both** call sites, so even once the NUI hang is fixed the chosen face and
clothes are **never persisted** — checklist C1 ("closing saves") cannot pass as written, and C4
("relog: no creator") would re-trigger the creator forever.

**Not patched**, because the correct save path is exactly the kind of guess that has cost us time
tonight: it may be a `illenium-appearance:server:*` event, an export, or handled internally
depending on framework config. Identify it from the running resource first — the pack ships
`outbreak_identity/data/illenium_config_notes.md`, which was never applied and is the place to start.

---

## Build 2026-09-14 — identity order, vehicles v2, colour vision

### B3-1 · Identity runs before the creator

`outbreak:client:createSurvivor` opened illenium's creator first and the WHO WERE YOU dialog
second. The creator is the half that is broken (FB-7) and the half that is purely cosmetic; the
dialog is the half that feeds gameplay, because traits set starting skill levels and the callsign
is what other survivors see with `/look`. One broken dependency was therefore blocking character
creation outright.

Reversed. Dialog first, then the creator as an optional trailing step in `openCreator()`, still
bounded at 90s. If it fails the player gets *"The mirror is cracked — use /wardrobe to try again
later"* and keeps playing. Also fixed a tight retry: dismissing the dialog re-fired the event with
no delay, now `Wait(2000)` first.

**EV-1 is still open.** The appearance is still discarded by the empty callback. This makes a
broken creator survivable; it does not make it work.

### B3-2 · Vehicles v2 enabled

`ensure outbreak_vehicles` is live. `CLAUDE.md` holds the extended groups until smoke 0–11 pass and
they have not — this is a deliberate override, taken on request.

Pre-flight before enabling, all clean: every export it calls exists (`ox_target:addGlobalVehicle`,
five ox_inventory exports, `outbreak_skills:grantXP/getLevel/effects`, `outbreak_emotes:action`,
`outbreak_minigames:play`), all seven manifest dependencies start earlier in the cfg, and
`004_vehicles.sql` is applied. Also removed a duplicate `ensure outbreak_vehicles` left commented
in the EXTENDED block, which would have double-ensured it the moment that block was uncommented.

**Untested in play.** If the boot goes red, comment line 42 of `server.cfg.additions` and restart —
nothing else in the slice depends on it.

### B3-3 · Colour vision — the real failure was not red/green

The palette was already close to safe: blue `H2O` against orange `FOOD` is the canonical
colourblind-safe pair. The genuine failure was **rust against olive** — under deuteranopia both
collapse toward the same yellow-brown, and that is exactly *critical* against *normal fatigue*. A
player could not distinguish a dying bar from a healthy one by hue.

"Low" now carries four independent signals: rust hue, 45° stripes, throb, and the numeric value
next to its stencil tag. Stripes survive colour blindness and screenshots; throb survives colour
blindness but not a still; the number survives everything. Applied identically in HUD and panel.

Rule recorded in `UI-SYSTEM.md`: colour may reinforce a meaning, never carry it alone — if the
screen is unreadable in greyscale it is not finished.

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

## 2026-09-14 — live tree relocated, and it is stale

**Symptom.** Boot log of 2026-09-13 18:14 showed both bugs we had already fixed:
`outbreak_faction/server/faction.lua:50: attempt to call a nil value (global 'cid')` (FB-6)
and `outbreak_needs/server/needs.lua:60: attempt to call a nil value (global 'SetEntityHealth')`
(FB-8), the latter firing on every needs tick.

**Root cause.** Not a regression. The patches were made in the pack and never copied to the
live tree. Three independent confirmations that the running tree predates v0.14:
FB-6 and FB-8 both present; `set sv_master1 ""` absent (the master-list query retry loop is
still in the log); and `outbreak_status` not among the started resources.

**Path change.** The live tree is no longer `C:\FXServer\txData`. Tony reorganised during the
purge:

| path | role |
|---|---|
| `C:\Outbreak\pack` | source of truth |
| `C:\Outbreak\txData` | live base — `resources\[outbreak]` etc. |
| `C:\Outbreak\server` | artifact |
| `C:\Outbreak\archive` | old trees |

Every setup script now takes `-Base "C:\Outbreak\txData"`. `CLAUDE.md` and `ops/backup.bat`
updated. `INSTALL-WALKTHROUGH.md` keeps the generic `C:\FXServer` layout — it is the
from-scratch doc, not a record of this install.

**Status.** Fix ready in pack, not yet deployed. Redeploy pending.

## 2026-09-14 — cfg comment tokenisation: SEMICOLONS

**Symptom.** `No such command ace.` / `No such command prerequisite.` / `No such command apply.`
during boot, in the middle of the outbreak ensure block.

**Root cause — confirmed.** The 07-update-cfg.ps1 preview printed the live block, which the pack
no longer matched. The offending line:

```
ensure outbreak_dm              # director menu (007_dm.sql); ace outbreak.dm
```

FiveM splits cfg lines on `;` **before** stripping `#` comments. So that line is two commands:
`ensure outbreak_dm # director menu (007_dm.sql)` and `ace outbreak.dm`. The second is the
error. `prerequisite` and `apply` came from semicolons inside the old VEHICLES comment block
the same way. Not the brackets, not the em dashes, not the inline `#` — the semicolons.

An earlier pass had "removed semicolons from comments" in the pack, but the live cfg was still
the pre-fix revision, which is why the pack file did not contain the words the log reported.

**Patch.** The v0.15.0 `server.cfg.additions` has no semicolons anywhere. It also has whole-line
ASCII comments only — over-broad for this cause, but it costs nothing and closes the door on
the other candidates. Deployed via 07-update-cfg.ps1 on 2026-09-13 19:05. Boot clean.

**Rule for the file, permanent:** no `;` in server.cfg comments, ever. It is the one character
the parser reads through a `#`.

**Also corrected.** I had said `apply` was printed where `ensure outbreak_vehicles` should be
and something was eating the ensure. Wrong: the live cfg never had that ensure line at all
(confirmed by its absence from the preview's lost-lines list). Nothing was eaten; vehicles
was simply never enabled live until this deploy.

## 2026-09-14 — 07-update-cfg.ps1 first run: blank-line binding bug

**Symptom.** `Write-TextNoBom : Cannot bind argument to parameter 'Lines' because it is an
empty string.` at the write step. server.cfg untouched (failure was at parameter binding,
before the body ran); backup already taken.

**Root cause.** `[Parameter(Mandatory=$true)][string[]]$Lines` validates every element as
non-empty. `[AllowEmptyCollection()]` permits an empty array, not an empty element. Any real
server.cfg has blank lines, so the head of the file could never be written back.
`Add-TextNoBom` had the same defect and is called with `@('')` by 05-append-cfg.ps1.

**Patch.** Dropped Mandatory, added AllowEmptyString + AllowNull with `@()` default, null-guard
in both bodies. Patched live via a one-line ReadAllText/Replace, and in the repo.

**Status.** Fixed. Second run wrote cleanly; boot 19:05 shows 23 resources.

## 2026-09-14 — ops/backup.bat was silently backing up no resources

**Symptom.** None observed; found while correcting the paths.

**Root cause.** `Compress-Archive -Path '...\resources\[outbreak]'` — the same PowerShell
bracket-wildcard trap that bit the setup scripts. `[outbreak]` is a character class matching
one character from `outbreak`, so the path matched nothing and the zip contained only
`server.cfg`. The dump half of the script was fine.

**Patch.** `-Path` → `-LiteralPath`. Also: `DB` corrected to `QboxProject_A70B55`, paths moved
to `C:\Outbreak\`, `mariadb-dump.exe` now located by scanning `C:\Program Files\MariaDB *`
instead of the hardcoded 11.4 (Tony runs 12.3.3), and both halves now report a non-zero exit.
`DBPASS` left as `CHANGE_ME` — the real password does not belong in the repo.

**Status.** Fixed, untested.

## 2026-09-13 19:05 — first login after v0.15.0: `hotZone` nil in outbreak_core

**Symptom.** `@outbreak_core/client/zombies.lua:50: attempt to call a nil value (global
'hotZone')`, once per HUD tick, called from `outbreak_hud/client/hud.lua:30`.

**Root cause.** `exports('currentZone', ...)` at line 49 calls `hotZone()`. `hotZone` is a
`local function` declared at line 123. A Lua local is only in scope after its declaration, so
inside the closure the name resolved to a global — nil. The file already forward-declares
`spawnZombie` for exactly this reason (line 4); I added `hotZone` in v2 and did not.

**Patch.** `local hotZone` beside the `spawnZombie` forward declaration; definition changed
from `local function hotZone(pos)` to `hotZone = function(pos)`. Two lines.

**Why the analyzers missed it.** diag3 check 1 asks "is it defined anywhere in the resource"
— yes. It never asked "is it defined *before* it is used". Added check 6: any call to a
`local function` / `local NAME = function` that precedes its declaration. Regression-tested
against both shapes: the original (no forward decl) and the shadow case (bare `local NAME`
above + `local function NAME` below, which declares a second local the closure never sees).

**Status.** Fixed in pack; live patch by PowerShell replace on both copies, then full restart.

**Also seen, not ours:** `TypeError: Cannot read properties of undefined (reading 'replace')
(@chat/dist/chat.js:1)` — stock chat resource, most likely a qbx_chat_theme interaction.
`ultra-voltlab` audio `dlchei4_game.dat` failed loading — recipe resource. Both noted, neither
chased.

## 2026-09-14 — autonomous build: v0.16.0 (settlements, cooking, morale, World Director)

Tony's brief while away: stability first, then the food/supply foundation, then roadmap 1–3 (World
Director, Settlement Needs, morale as behaviour), everything with its UI. Full design in
`DESIGN-supply.md`; test plan in `SMOKE-SCRIPT §14` / checklist S1–S8.

**ALWAYS FIRST — bug status.** Latest login log (19:05) was clean after the `hotZone` fix. Still
open and *not* fixable from here: illenium creator NUI errors (needs the recipe's illenium config
in front of us — next step unchanged from the Deferred entry), `prop_cs_body_bag` and the two bread
shelf props (need `/ob_models`), the stock `chat.js` TypeError (not ours). Nothing else red.

**Could not boot.** No FXServer in this container. Substitute: `tools_luac.py` (a real Lua 5.4
parse of all 145 files) added to the chain, and all four passes are clean. First boot of v0.16.0
is Tony's; rollback is two `#`s in the cfg.

**Built.** `outbreak_supply` (config 60 lines, server 330, client 120), `outbreak_director`
(config 45, server 170, client 60), migration 008, three items + useables, Home column in F1,
HUD strip token, Director menu tools, housing `getHouse`/`houses` exports + Settlement door entry.

**Deploy traps fixed on the way.** `04-paste-ins.ps1` no-oped when the marker existed, exactly like
05 — an upgraded snippet never landed. It now diffs the managed block and refreshes it.
`03-apply-migrations.ps1` hardcoded 21 tables (now 23); `_common.ps1` migration list and
`SliceResourceCount` (24) updated.

**Unverified until it runs** (all listed in DESIGN-supply.md): ox_lib context `progress`/`colorScheme`
rendering, `GetInventoryItems` on an unopened stash, the four stranger ped models, rumour coordinates
(only used to pick the nearest label).

**Deliberately not built.** Resident *bodies* inside the house (behaviour is visible through the
ledger, notes, notifies and stock — bodies are a follow-up once interiors are settled). Consumption
while the server is empty (world moves when someone is in it — a design choice, documented).

## 2026-09-14 — overnight build sheet: v0.17.0

Full list and test order in `TEST-CHECKLIST.md`; summary of done / verified / skipped / needs-me in the
session report. Notes that matter for debugging tomorrow:

- **Why nothing worked while downed.** `outbreak_down` called `SetPlayerControl(PlayerId(), false, 256)` on
  every down state. That disables *every* input, including chat's T, the wheel's G, F10, the radio, and the
  E the self-splint thread was polling with `IsControlJustPressed` — which returns false for disabled
  controls. Replaced with a per-frame `DisableControlAction` over body inputs only. If anything is still
  dead on the floor, that list (`BODY_CONTROLS` in `client/down.lua`) is where to look.
- **Voice reset is best-effort.** The natives are real; which one actually clears a stuck mumble session
  is inferred. `/ob_voicereset` prints before/after `MumbleIsConnected()` with `ob_debug 1` — that line
  tells you whether the reconnect path ran at all.
- **Radio sounds are synthesized** by `tools/gen_audio.py`; re-run it to change them. If the squelch is
  too loud, `RadioCfg.Sfx`. If the voice distortion is too much, `RadioCfg.Submix = false`.
- **Dead zones** use `GetInteriorFromEntity ~= 0` plus two tunnel coordinates from memory. If the radio
  dies somewhere it should not, `RadioCfg.IndoorsIsDead = false` isolates it.
- **Defense event timers are `SetTimeout`**, not persisted. A restart during one cancels it silently.
- **diag3 had a parity bug**: its string stripper ran `'` before `"`, so an apostrophe inside a
  double-quoted string flipped every quote after it and hid config keys. One combined pass now.
- **Not built / parked from P2** (needs assets, a live creator, or in-game iteration): full character
  editor (illenium still broken — Deferred), layered clothing with condition/dirt, persistent scars,
  saved outfits, prone/lean/vault, paired emotes, box-carry animation, drag-drop inventory changes
  (ox_inventory owns it), per-item custom art beyond ox's stock icons.
