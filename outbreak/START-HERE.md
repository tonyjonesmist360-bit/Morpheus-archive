# START HERE — Outbreak v0.26.0 — THE YARD (mechanics faction)

**Deploy:** robocopy into the pack, `02-copy-resources`, `07-update-cfg -Apply` (one new ensure line), `08-disable-commerce -Jobs -Apply`
(qbx_customs is now stopped: the Yard replaces it), restart. F9 section **12 THE YARD** (9 steps).

## What changed since v0.25.0

| | |
|---|---|
| **The Yard** | Beeker's Garage at Harmony is a faction: a Foreman (clipboard) and two hands who shoot the dead. Standing with `mechanics` sits beside the other three in the journal. Channel 9. |
| **Delivery jobs** | Foreman → *Take a delivery job*: a car spawns at one of six pickups with your key, a route blip, a 20-minute clock. Get in and the route flips to the Yard. Park inside and step out: the server judges it. +15 standing, +5 more if the engine is untouched, -5 for a wreck, -3 for dropping it. |
| **Raider chase** | Once the car is 350 m from the pickup, three jobs in four spawn two raider cars behind you, drivers chasing, riders shooting. They break off past 400 m or after four minutes. |
| **Free repairs and mods** | Foreman → *Repairs & mods* with the car in the Yard: repair at *wary*, six resprays at *neutral*, engine / brakes / transmission at *trusted*, armour and turbo at *kin*. No money anywhere. Mods are saved with keyed cars and re-applied after a restart. |

Unverified: the Yard, foreman and pickup coordinates; models `s_m_y_xmech_02`, `s_m_m_autoshop_01/02`; scenarios WORLD_HUMAN_CLIPBOARD / WORLD_HUMAN_WELDING.

---

# v0.25.0 — REPAIRS FROM THE FIRST F9 RUN

**Deploy:** extract, robocopy into `C:\Outbreak\pack`, `02-copy-resources`, `08-disable-commerce -Jobs` (preview) then `-Apply`, restart.
No migration, no cfg change, no new items. F9 section **11 v0.25** (17 steps). `qbx_customs` is now KEPT by the commerce script (car mods stay).

## What changed since v0.24.4

| | |
|---|---|
| **Radio channels** | A radio powers up on **channel 1 (emergency)**. Other channels must be found: **SCAN** (S on the screen, `/radioscan`) locks onto a live one (someone on it, main comms 4, a faction net); joining a faction hands you its net; ▲▼ step known channels only; an unknown channel is "Nothing on N." Known channels persist per character. |
| **Faction posts** | A **Sergeant + 5 marines at the Zancudo gate** and a **Warlord + 4 raiders at the boneyard**. Guards shoot the dead and ignore you unless you are the other side. The recruiter is the target: Enlist / Walk out / Armory / Talk. The old sphere zones stay. |
| **Bolingbroke** | A **pool of 50** (server-counted, persisted in `pools.json`, `ob_pool prison 50` refills). No respawn past the pool. Cleared: cafeteria stores, infirmary, two tower safes each with a guard on top, and the cell block claimable as a safehouse. |
| **Map places** | Named blips for 16 stores, 8 clothing stores (free change + rack loot), 6 barbers (**5 Old Money**), 4 mechanics, gun stores, vaults, medical stations, workbenches, the prison. Legend lists them. Coordinates from memory: `/coords` on the real spot and tell me. |
| **More of everything** | 9 new safehouse doors, 3 more medical stations (Mount Zonah, St Fiacre, Harmony van), 7 workbench sites as zones, 6 more vending models. |
| **Not built** | Mechanics faction with deliveries and raider chases (next build, needs the caravan pattern). qbx_customs prices need its own config edited to zero. |

---

# v0.24.0 — BUILD QUEUE Q1 + Q2 (server authority)

**Deploy:** extract, `robocopy` into `C:\Outbreak\pack`, `02-copy-resources`, restart the server (no cfg, no migration, no items).
F9 section **10 AUTHORITY** (A1–A8). Q0's in-game half (`/ob_animcheck`, `/ob_models`, `/ob_walk`, the tuning evening) is still yours.

## What changed since v0.23.0

| | |
|---|---|
| **Q1 · minigame tokens** | Every skill check asks the server first and hands a token back with the result; the server refuses missing, reused, wrong-target, too-fast or stale results (`KNOWN_LIMITATIONS` #1 closed). Vehicle batteries and parts are skill checks now (mechanics ≥ 5 waives), and unclaimed cars can be **stripped** for a battery or engine parts. |
| **Q2 · witnessed wounds** | A wound report needs server-visible damage in the last 2 s (OneSync weapon damage event or a ped health drop); unarmed hits are bruises whatever the client says (#2 closed). `/ob_wound` still works through a debug path. |
| **Q0** | Offline part done (Deferred list re-read, see SHAKEDOWN-NOTES). The rest needs the server. |

---

# v0.23.0 — SHEET #3 BUGFIXES + INFRASTRUCTURE 1–5

**Deploy:** extract, `robocopy` into `C:\Outbreak\pack`, then `02-copy-resources` → `03-apply-migrations` (new `009_house_spots.sql`, 24 tables)
→ `04-paste-ins -Only all` (items + **shops: replaces ox_inventory/data/shops.lua with an empty table — no Ammunation, no cashier, no licence**)
→ `08-disable-commerce` (preview, then `-Apply`: comments the recipe's bank / shop / vehiclekeys ensure lines out)
→ `07-update-cfg -Apply` (two new ensure lines at the top of Layer 0) → start. F9 has new sections **8 BUGFIXES** and **9 OPS**.

## What changed since v0.22.0

| | |
|---|---|
| **Bugfix 1 · gun stores** | No shop, no licence, no money: the shops file is blanked by the paste-in. Ammunation racks and safes are **loot sites** (`LootCfg.Sites`, sphere zones, coordinates from memory — `/ob_site_here` prints a corrected line). Racks: melee, the odd pistol/shotgun, 9 mm, gun oil. Safes: pin-sweep, ammo, weapon kit. |
| **Bugfix 2 · banks** | `08-disable-commerce.ps1` comments the bank resource out of the recipe cfg (name list in the header; add the real one with `-Extra`). Bank vaults are loot sites: pin-sweep, old money by the armful, the odd document. Map key already hides bank blips. |
| **Bugfix 3 · house loot inside** | Houses with an interior are searched **inside** at named spots (`Search kitchen counter`…), ox_target zones from `outbreak_house_spots`. Seeded five per interior around the entry; walk to the real counter and `/ob_spot <house> <table> <name>` moves one. Door menu for interior houses now says *Search inside*. Exterior-only houses keep their named door menu. Every find is announced with **where** and lands in the journal (Objectives → recent finds). |
| **1 · Tuning** | `outbreak_tuning`: 33 knobs in `tuning.json`, `ob_tune set key value` live (schedules re-read their minutes; consumers read `GlobalState.obTune`). `BALANCE-TUNING.md`. |
| **2 · Admin suite** | `time set`, `weather set`, `spawn mob`, `trigger encounter`, `settle morale/residents`, `loot reset`, `event log`, `server stats`, `hotfix reload`. `ADMIN-COMMANDS.md`. |
| **3 · Logging** | `outbreak_log`: daily files `logs/YYYY-MM-DD.log`, `date | src:name:cid | kind | json`; `/logs kind:faction player:12 date: text:`. Hooked: joins/drops, faction join/leave/standing, deaths, house claims, loot, DM actions, director actions, admin commands, moderation, tuning. |
| **4 · Performance** | 1 s heartbeat measures server loop lateness; alert over `ops.perfAlertMs`; `server stats`; a `perf.report` log line every 6 h. Per-resource CPU stays txAdmin's job (not readable from Lua). |
| **5 · Backups** | `ops/restore-backup.ps1 -Date YYYYMMDD -Apply` (files moved aside, DB dumped first, undoable); retention 7 days. |
| **6 · Restart** | warnings at 60/15/5/1 min before `ops.restartHour`, flush at 0. **Needs you:** set txAdmin's restart schedule to the same hour. |
| **9 · Moderation** | `mute/unmute/kick/ban/unban/bans` with `bans.json` and `mod.*` log lines. Mute blocks chat, radio PTT and voice. |
| **10 · Hotfix** | `hotfix reload <resource>` = a logged single-resource restart. |

**Not built (by design):** infra 7 doc is in; 8 leaderboards skipped (fun, later). Sheet #4 lanes: not started — see the summary for the recommendation.

---

# v0.22.0 — OVERNIGHT SHEET #2

**Deploy:** extract, `robocopy` into `C:\Outbreak\pack`, then `02-copy-resources` → `04-paste-ins -Only items` (three new
items) → `07-update-cfg -Apply` (five new ensure lines) → start the server. No new migration. **Then:** `TEST-GUIDE.md`
beside you, **F9** in game.

## What changed since v0.21.0

| | |
|---|---|
| **Core mechanics protected** | `CORE-MECHANICS.md`: the protected list, the review rule, the hook inventory and every root cause found (vehicle entry, punch, pad inventory button, the sprint cut that never worked). F9 section 1 covers all of it. |
| **Body scan** | A silhouette beside the HUD bars and a large one in F1. Regions: healthy / **bruised** (amber) / **bleeding** (rust, throb) / **broken** (blood + cross) / treated (dim). Hover in F1 = what is wrong + what treats it; click = treat with what you carry. Wired: leg break **limps** until splinted, arm wound **shakes the sights**, torso wound **cuts your sprint**. Fists now bruise; **painkillers** treat bruises; bandage/splint/painkillers are usable straight from the inventory and go to the worst matching wound. Wrong item on the wrong wound is refused, not consumed. |
| **Infection from wounds** | A zombie scratch/bite is *dirty*; left untreated 20 min it turns ("has gone bad"). Antibiotics inside the first hour **cure**; later they only slow. Antibiotics stay rare medical loot. |
| **Story wired in** | `outbreak_intel` + `outbreak_opportunities` are ensured (five chains, journal on **J**). Journal gained **Objectives** (guide steps + your settlement's needs) and **Factions** (standing bars) tabs. |
| **Factions** | Enlist / walk out at the Zancudo armory; Join / leave the Boneyard at the raider cache. Rep gates it, leaving costs 25, 30-min cooldown. Three standings (Remnant, Boneyard, Enclave) with words: hostile → wary → neutral → trusted → kin. |
| **Dead money** | `old_cash` exists, drops from tills / vending / houses / trash, trades between players by drag, buys nothing. Using it: "$N, more or less." |
| **Stores are looting** | Shelves say **STEAL** with noise per take and a 12 % dropped-can spike. Tills: **Force the register** (pry anim, loud). Vending: **Break into the machine**. **Needs you:** if any ox "Open shop" point survives, blank `ox_inventory/data/shops.lua` (E5). |
| **Map key** | New `outbreak_mapkey`: vanilla shop / bank / clothing / ammunation / LSC blips removed every 10 s (sprite ids unverified); `/mapkey` (wheel → Map key) lists every blip the pack draws. |
| **Sandy 24/7** | Console `ob_scene_clear 1960.5 3740.6 32.3 45` removes the roadblock props (they were persisted `__prop` world items from the *Raider roadblock* scene run at the motel spawn) and the unclaimed car; writes `cleared-*.json`; `ob_scene_restore <file>` undoes. F10 → Spawn → **Clear scene here (40 m)** for DMs. Nothing in the pack re-creates them on restart. |
| **Crews** (3, 4) | New `outbreak_group`: G → Crew → start / invite nearest / pins / leave. Top-left crew panel (name, health line, DOWN/BLEEDING/INFECTED/distance). Blue member blips, yellow labelled pins, crew-only. `/crew`, `/pin <label>`. |
| **Compass** (5) | Top-centre strip: cardinals follow the camera (N in rust), ticks for crew pins, your waypoint and home. Rides on the HUD's existing per-frame loop at 10 Hz — no new loop. |
| **Vehicles** (6, 7) | Any car a key was cut or handed out for **persists**: position, fuel, state, body + engine damage. **Trunk** (stand at the back) and **glovebox** (seated, wheel or `/glovebox`) are ox stashes keyed by plate, so cargo persists too. Locked = key required. |
| **Workbench** (8) | `outbreak_craft` ensured. K = field recipes. Tool benches / a placed `workbench` item: Molotov, **barricade kit** (one level, the door accepts it instead of planks + nails), key blank, padlock. Craft sound. |
| **First ten minutes** (9) | Eight guided steps on a fresh character (move, pockets, drink, wheel, F1, radio, reach the nearest safehouse — waypoint set — claim). Sound per step. `/tutorial` replays, `/tutorial off` stops. |
| **F9 TEST MENU** | 71 steps in 8 sections, each with Do / Expect; **M** = mouse mode with PASS / FAIL / NOTE buttons; results to `shakedown-results.md`. `TEST-GUIDE.md` is generated from the same table. |

**Unverified names this build** (F9 will tell): map sprite ids, `prop_tool_bench02` and the other bench models, `move_m@injured`
as the limp, `SetPlayerSprint` persistence, `CHECKPOINT_PERFECT` / `MEDAL_UP` / `PICK_UP` sound names, blip sprite 1 for crew and pins.

---

## v0.21.0 — What changed since v0.20.0

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
