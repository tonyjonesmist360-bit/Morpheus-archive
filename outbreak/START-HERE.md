# START HERE — Outbreak v0.21.0

## What changed since v0.20.0

| | |
|---|---|
| **Vehicles: era** | `setr ob_veh_era early` (new cfg line, default early). **early** = day one: 15 % locked, 10 % dead battery, 5 % missing part, 30–80 % fuel, and 60 % still have the **keys in the ignition** (unlocked, runs, no splice). **live** = the old scavenging numbers. Switch when the crew joins: cfg line, `ob_vehera live` in the console, or F10 → Admin → Vehicle kit → World era. Only cars seen for the first time after the switch roll the new table; a restart re-rolls every unclaimed car. |
| **Keys on spawn** | Every DM-spawned vehicle drops a `vehicle_key` (plate in metadata) in your pocket and starts unlocked, hotwired, battery ok, 80 % fuel. Vehicle kit → **Give me the key** does the same for the car you sit in or aim at (and fixes its state). **Lock / unlock** added. If `qbx_vehiclekeys` is running, every key we hand out is mirrored to it (export name unverified) and the boot log says in red that it should be commented out. |
| **Admin vehicle list** | 100+ base-game models in a searchable picker, grouped by pickup / SUV / van / truck / service / military / bike / boat. **Spawn by model name** takes any model. |
| **Crouch melee** | (v0.20.2) attacking while crouched drops the crouch for the swing and re-crouches after. Zombies no longer cancel their own attacks (aggro flag). |

Deploy: `02-copy-resources` then `07-update-cfg -Apply` (one new `setr` line), restart `outbreak_vehicles` and `outbreak_dm`. Checklist: `TEST-CHECKLIST.md §9e`.

---

## v0.20.0 — What changed since v0.19.0

| | |
|---|---|
| **Quiet kill** | Stealth/crouched + a blade or blunt + behind an unseen zombie inside 1.7 m → `[E] quiet kill`: snap to its back, takedown, no noise, stays down under headshot-only. Bloaters never; runners and brutes struggle (half damage, noise 20, they turn on you). Stealth XP. GTA's own engine takedown is untouched and may also fire — test both. |

Deploy: `02-copy-resources` only. Checklist: `TEST-CHECKLIST.md §9d`.

---

## v0.19.0 — What changed since v0.18.0

| | |
|---|---|
| **Sneak** | A second sense number, **visibility** (posture, motion, light, weather, interior, stealth skill), scales zombie sight range. Zombies that see you build **suspicion** — they turn to face you before they charge — so there is a window to break line of sight. Inside 6 m it is instant. HUD **eye**: HIDDEN / UNSEEN / NOTICED / SEEN / EXPOSED. Wheel → **Throw a distraction** (soda/beer can) lures every zombie within 40 m to where it lands. |

Deploy: `02-copy-resources` only (no items, no cfg change). Checklist: `TEST-CHECKLIST.md §9c`.

---

## v0.18.0 — What changed since v0.17.0

| | |
|---|---|
| **Sleep** | Door → Sleep, or the bed inside an interior. Four minutes black, fatigue to full, costs food and water; E, damage or a zombie within 60 m wakes you. Server pays by elapsed time. |
| **Water sources** | Door → Fill from the tap: murky water, 4 per house per hour. New `rain_catcher` placeable (tool-chest loot): fills with murky water while it rains, cap 8. Boiling already exists — the loop closes. |
| **The Tide** | One roaming super-horde on a mob area: radio warning, red radius on the map, ~2× density there, `THE TIDE` on the strip, F1 row. Moves every 20–40 min. Settlements inside it get probed ×3. `/ob_tide` moves it. |

Deploy: `02-copy-resources`, `04-paste-ins -Only items -Force` (rain catcher), `07-update-cfg -Apply` (no cfg change, harmless). Items: **350**.
Checklist: `TEST-CHECKLIST.md §9b`.

---

## v0.17.0 — What changed since v0.16.0 (2026-09-14 overnight build sheet)

**Walk `TEST-CHECKLIST.md` top to bottom.** Every feature from the sheet is in it, in test order, with the expected result and an
*unverified* flag where I could not see or hear it from here.

| | |
|---|---|
| **P0** | Downed players keep chat, wheel (a downed set), F10, radio, distress (F6 / pad X / `/ob_distress`), `/ooc`. Self-splint works (E, or the wheel). Adrenaline from the wheel. Bleed-out 5 min. `mumble_pill` + `/voicereset`. **`outbreak_chat` new.** |
| **P1** | The walkie: prop + raised arm on key-up, squelch/static/hiss (synthesized, `tools/gen_audio.py`), radio-FX voice submix, the handheld's own screen (N), `]`/`[` channel step, dead zones (interiors + two tunnels) both ways, battery bars, `((radio))` over talkers, batteries in loot. |
| **P2 (partial)** | Item icons mapped to ox_inventory's stock images (unverified names). `/walkstyle` picker that says INVALID instead of failing silently. `/crouch`. The rest of P2 is **parked** — see the summary. |
| **P3** | F10 → **Admin**: player panel, noclip/flight, god, real ghost (hidden for everyone, NPCs ignore), spectate, teleport to waypoint / saved / player, `/coords`, entity gun, zombie controls, vehicle kit, searchable give, announce, voice reset. |
| **P4** | `/ob_hud` overlay, `/bug` → `outbreak_debug/bugs.log`, `TEST-CHECKLIST.md`. |
| **P5** | **`outbreak_loadscreen`** (stops the recipe one), MOTD on every load, Discord presence, moodier weather weights, **`outbreak_ambience`** (wind, distant groans). |
| **P6 / P7** | The Director's probe is a staged **defense event** (warning → 4 min prep → wave → held/overrun with real consequences). **Residents you can see** at any settlement door, scenarios and lines by morale. |
| **Kit / ops** | Every scenario starts with beans, a knife, clean water. `ops/install-backup-task.ps1 -RunNow` registers and verifies the nightly backup; `ops/verify-backup.ps1`. |
| **Tooling** | `tools_diag3.py` string-parity bug fixed (a `"Don't"` inside double quotes was hiding config keys). |

**Deploy:** extract over `C:\Outbreak\pack`, then with the server stopped: `02-copy-resources`, `04-paste-ins -Only items -Force`
(icons + the pill), `07-update-cfg -Apply` (three new ensures + `stop loadscreen`). No new migrations. Expect **28** `outbreak_`
ensure lines and `Inventory has loaded 349 items`. Rollback per feature: comment its `ensure`; for the loadscreen also delete
`stop loadscreen`.

---

## v0.16.0 — What changed since v0.15.0 (2026-09-14, autonomous build)

| | |
|---|---|
| **+ `outbreak_supply`** | Settlements. The house stash is the stockpile; residents eat from it; spoilage; four recipes at the door; morale that becomes behaviour (disputes, drinking, leaving with a note). Ledger on the door menu + `/ob_home`. **Migration 008.** |
| **+ `outbreak_director`** | World Director every 30–60 min: stranger at the door (recruit), food/medicine rumours on the radio, probes at weak houses, word from home, safehouse tips. DM → Story → "run a pass now". |
| **✎ status panel / HUD** | F1 gains a Home column; the world strip gets one `HOME …` token. |
| **✎ `outbreak_items`** | 3 cooked items + useables — **re-run `04-paste-ins.ps1`**, it now refreshes the managed block. |
| **✎ `outbreak_housing`** | read-only `getHouse` / `houses` exports; Settlement entry on the door menu. |
| **✎ `outbreak_dm`** | Director pass + settlement residents/morale tools. |
| **✎ setup** | `07-update-cfg.ps1` (replaces a stale cfg block), `04` refreshes items, 24 slice resources, 23 tables. `tools_luac.py` — a real Lua parser pass; run it with the other three. |
| **✎ `outbreak_core`** | `hotZone` forward-declared (was nil in `currentZone`). |

Read `DESIGN-supply.md`, then run **SMOKE-SCRIPT §14**. Deploy: extract over `C:\Outbreak\pack`, then
`02-copy-resources`, `03-apply-migrations`, `04-paste-ins`, `07-update-cfg -Apply` — all with
`-Base "C:\Outbreak\txData"` — then restart. Rollback for the two new resources is two `#`s in
`server.cfg` (`ensure outbreak_supply`, `ensure outbreak_director`); nothing else depends on them.

---

## Original first-boot notes (v0.13.3)

Everything needed for the first-ever boot is in this folder.

## What changed since v0.13.2

| | |
|---|---|
| **+ `INSTALL-WALKTHROUGH.md`** | Was referenced by three docs but **missing from the zip**. Reconstructed as Parts 1–7, verified against the live Qbox recipe. |
| **+ `setup/`** | Seven PowerShell scripts that do Parts 6 and 7 for you. |
| **+ `SHAKEDOWN-NOTES.md`** | The pre-boot audit: what was fixed, what was verified, what is deferred. |
| **✎ `outbreak_spawn/server/spawn.lua`** | **Fix PB-1.** `player.Functions.SetMoney` does not exist in Qbox. Would have killed the whole first-join flow. |
| **✎ `outbreak_faction/fxmanifest.lua`** | **Fix PB-4.** Never loaded oxmysql; errored on every connect. |

Both fixes are in the resource files in this zip. Copy them in and you have them.

## Read in this order

1. `CLAUDE.md` — the rules for the evening
2. `ARCHITECTURE.md` — the ownership contract
3. `KNOWN_LIMITATIONS.md` — the 23 things already expected to be wrong
4. `SMOKE-SCRIPT.md` — the evening, top to bottom
5. **`INSTALL-WALKTHROUGH.md`** — if the server is not installed yet ← **you are here tonight**
6. `SHAKEDOWN-NOTES.md` — what the pre-boot pass already found

## The setup, in one screen

**Yours (~45 min, cannot be scripted):** INSTALL-WALKTHROUGH Parts 1–5.

1. FXServer artifact (LATEST RECOMMENDED) → `C:\FXServer\server\`, create `C:\FXServer\txData\`
2. Server key from **portal.cfx.re** (Keymaster retired 2026-08-04)
3. **MariaDB 11.8 LTS standalone MSI — not XAMPP.** Root password, UTF8, install as service. `CREATE DATABASE outbreak;`
4. Run `FXServer.exe` → `localhost:40120` → PIN → recipe **Remote URL**:
   `https://raw.githubusercontent.com/Qbox-project/txAdminRecipe/main/qbox.yaml`
   → point it at database **`outbreak`** (the same one — oxmysql has a single connection)
5. **Boot stock Qbox and connect before touching anything.** Then `status` in the console, copy your
   identifier, add `add_principal identifier.<yours> group.admin` to `<BASE>\permissions.cfg`. Stop the server.

**Mine (~5 min, server stopped):**

```powershell
cd C:\outbreak-pack
powershell -ExecutionPolicy Bypass -File .\setup\00-preflight.ps1     # read-only: where am I?
powershell -ExecutionPolicy Bypass -File .\setup\RUN-ALL.ps1 -DryRun  # preview every change
powershell -ExecutionPolicy Bypass -File .\setup\RUN-ALL.ps1          # do it
```

That covers Part 6 (disable the nine competing resources + npwd) and Part 7 (copy resources, migrations
001–007, the two paste-ins, append the start order), then re-runs preflight to prove it worked.

**Then:** start the server, `connect localhost`, F8 open — and go to `SMOKE-SCRIPT.md` **section 1 first**.
`/ob_animcheck`, `/ob_models`, `/ob_walk` resolve limitations #8, #19 and #20 in two minutes and make every
later section cheaper.

## The scripts

| Script | Does | Part |
|---|---|---|
| `00-preflight.ps1` | Read-only status of all five setup questions | — |
| `01-disable-competing.ps1` | Nine resources → `[disabled]`, comment three npwd lines. `-Revert` undoes it | 6 |
| `02-copy-resources.ps1` | Copies the three groups, verifies 21 resources **and both pre-boot fixes** | 7.1 |
| `03-apply-migrations.ps1` | Applies 001–007, verifies 21 tables | 7.3 |
| `04-paste-ins.ps1` | items.lua + jobs.lua, marker-guarded and brace-checked | 7.4 |
| `05-append-cfg.ps1` | Appends the start order, verifies it landed after `ensure [qbx]` | 7.5 |
| `RUN-ALL.ps1` | 01→05 in order, then preflight | 6–7 |

Common flags: `-Base <path>` if auto-detect can't pick your `.base`, `-DryRun` to preview, `-Force` to skip
prompts. Every file is backed up with a timestamp before it is touched, and every script is safe to re-run —
`02-copy-resources.ps1` is also how you deploy a patch mid-shakedown.

## Three things that will bite

- **PowerShell treats `[qbx]` as a wildcard**, not a folder name. Any command touching a bracketed path needs
  `-LiteralPath` or it fails with "cannot find path". The scripts handle it; hand-typed commands often don't.
- **`04-paste-ins.ps1` edits ox_inventory.** A malformed `items.lua` takes ox_inventory down and the server
  with it. If the server won't boot right after that step, restore the `.bak` beside the file.
- **Removing `qbx_medical` / `qbx_police` may upset other `[qbx]` job resources.** Expected. Collect the
  resource names from the Part 6 boot; don't fix by guessing.

## Ops, later

`ops/OPS.md` covers backups, scheduled restarts and the whitelist. **Edit `ops/backup.bat` line 8** — it
hardcodes `MariaDB 11.4`; set it to the version you actually installed or backups fail silently.

Before the crew joins: `setr ob_debug 0` and drop `ensure outbreak_debug`.
