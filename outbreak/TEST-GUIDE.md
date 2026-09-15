# TEST-GUIDE — the F9 run (v0.22)

Keep this beside you. **F9** opens the same list in game; **M** gives it the mouse so the PASS / FAIL buttons
work, **Esc** or **M** hands the mouse back. Passive keys: ▲▼ select, **P** pass, **F** fail, **N** note, **L** export.
Results land in `resources/[outbreak]/outbreak_debug/shakedown-results.md` (readable) and `shakedown.log`
(raw). Paste the .md to Claude. `/bug <text>` from anywhere appends to `bugs.log`.

## Setup before you start
- `setr ob_debug 1` is in the cfg (F9 refuses without it). `ob_kit` gives the whole slice kit.
- **Second player** for T3/T4 (crew), U7 (a punch), K2 (passenger). Solo: mark those with a note.
- **Infection test (T2)** needs a zombie wound left 20 minutes. To shorten: `NeedsCfg.Infection.dirtyMinutes = 1`
  in `outbreak_needs/shared/config.lua`, `restart outbreak_needs`, then set it back.
- **Vehicle persistence (T6)** needs a server restart mid-run. Do it after T8 so nothing else is half-done.
- **Sandy 24/7 cleanup (E7)** is a console command: `ob_scene_clear 1960.5 3740.6 32.3 45`. It writes a backup
  (`outbreak_worlditems/cleared-*.json`); `ob_scene_restore <file>` undoes it.
- **Model names** (`ob_models`), walk styles, sprite ids and anim clips are from memory. Anything INVALID:
  note it on the step. That is a name fix, not a system failure.
- Every mark is timestamped and attributed, so two people can test at once.

## Run order
Boot → Core mechanics → UI + body scan → Economy / looting → Story + factions → Ten additions → Prior sheet → Legacy.
Core mechanics first on purpose: if K1 or K4 fail, stop and tell me before anything else.



## 0 Boot

| # | Test | Do | Expect |
|---|---|---|---|
| B1 | Server ONLINE, no red outbreak_* lines | watch the txAdmin console during boot | 33 outbreak_ resources start clean |
| B2 | Client joined, F8 clean | connect, open F8 | no red lines; no "Invalid key name" |
| B3 | No qbx_vehiclekeys warning | search the boot log for [OB-VEH] | no red "qbx_vehiclekeys is running" line (if there is one, stop it and tell me) |

## 1 CORE MECHANICS

| # | Test | Do | Expect |
|---|---|---|---|
| K1 | Enter / exit a car as driver | walk to an unlocked car, F | you get in; F again gets you out. Repeat on 3 cars |
| K2 | Enter as passenger | stand at a passenger door, hold F | you take the passenger seat, not the wheel |
| K3 | Locked car: pry then enter | ob_give crowbar_tool 1; find a locked car (ob_vehera live, restart outbreak_vehicles to get some); Pry the door | pry minigame, door opens, you can enter |
| K4 | Punch | fists out, ob_zombie 1, swing | punches land; zombie reacts; no frozen arms |
| K5 | Punch while crouched | /crouch, then swing | you stand for the hit and re-crouch ~1.5 s after |
| K6 | Weapon draw / holster | knife on hotbar 1: press 1, press 1 again | draws, holsters; TAB shows it equipped/unequipped |
| K7 | Fire a gun | ob_give WEAPON_PISTOL 1; ob_give ammo-9 24; equip, shoot | shots fire; noise dot goes red; no JAMMED text above 30% condition |
| K8 | Sprint / jump / climb | ob_needs 100 100 100; Shift, Space, vault a fence | all three work |
| K9 | Sprint cut when exhausted | ob_needs 100 100 10; hold Shift | no sprint (jog only); ob_needs 100 100 100 -> sprint again. UNVERIFIED native: if sprint still works, mark FAIL and tell me |
| K10 | Swim | walk into the sea, swim, climb out | normal swimming, no stuck state |
| K11 | Ragdoll / get up | jump off something ~4 m high | ragdoll, get up, walk. If you go DOWN it is the wound system, not a bug |
| K12 | Ladder | climb any ladder (billboards, roofs) | up and down |
| K13 | Cover | Q against a wall | cover taken and left |
| K14 | Pad: D-pad Up opens inventory | controller, D-pad Up | inventory opens (the radio used to eat this button) |

## 2 UI + BODY SCAN

| # | Test | Do | Expect |
|---|---|---|---|
| U1 | HUD layout at 1080p | look | bars bottom-left, faint body beside them, noise dot + eye above, compass top-centre; nothing overlaps |
| U2 | Scratch shows on the body | ob_wound left_arm scratch | left arm region rust and throbbing on HUD and F1; Bleeding moodle |
| U3 | Hover + click to treat | F1, hover the arm, then click it (have a bandage: ob_give bandage 2) | tooltip: Scratch - Open and bleeding. Treat with: ripped sheet or bandage. Click -> panel closes, bandage anim, region goes dim |
| U4 | Broken leg = limp until splinted | ob_wound right_leg fracture; walk; ob_give splint 1; treat | leg region blood + cross; you LIMP (injured walk); after splint you walk normally |
| U5 | Torso wound = sprint drains | ob_wound torso laceration; sprint | sprint cuts out after ~3 s, repeatedly; bandage it -> holds |
| U6 | Arm wound = sights sway | ob_wound right_arm gunshot; aim the pistol | camera hand-shake while aiming; bandage -> still |
| U7 | Bruise from fists, painkillers fix | have a friend punch you (or ob_wound head bruise); ob_give painkillers 1; use them | amber region; painkillers -> "Treated: head"; region clears |
| U8 | Wrong item, wrong wound | with only a bandage, ob_wound left_leg fracture, use the bandage | "Nothing on you needs that" - bandage NOT consumed |
| U9 | Every menu ESC-closes | F1, J, N, G, F10, K, F9 M-mode: open each, Esc | each closes; cursor never sticks; text prompts never linger |
| U10 | No debug text | look at the screen with /ob_hud OFF | no coordinates / fps / OB-lines on screen |

## 3 ECONOMY / LOOTING

| # | Test | Do | Expect |
|---|---|---|---|
| E1 | Shelves are theft | Sandy 24/7, aim at chips/water on a shelf | target reads STEAL (mask icon); each take ripples the noise dot; about 1 in 8 "A can hits the floor" with a big ripple |
| E2 | Force the register | aim at the till | "Force the register", pry anim, loud ripple, old money comes out |
| E3 | Dead money | use the Old Money item | "$N, more or less." Nothing to buy anywhere. Drag to a friend to trade |
| E4 | Vending machine | aim at a soda machine | "Break into the machine", loud, water/beans/old money |
| E5 | No shopping anywhere | walk up to the 24/7 counter and any ox shop point | no "Open shop" / buy menu. If one appears, tell me where (needs ox_inventory/data/shops.lua blanked) |
| E6 | Map key | open the map; then G -> Map key | no shop / bank / clothing / ammunation / LS Customs blips; the legend names every blip you can see; hovering a blip on the map shows its name |
| E7 | SANDY 24/7 CLEANUP | console: ob_scene_clear 1960.5 3740.6 32.3 45  then walk there | the parked car and the barricade props are gone; console names a backup file; store door works, shelves STEAL-able |
| E8 | Cleanup survives a restart | restart the server, revisit the 24/7 | still gone (nothing respawns them) |

## 4 STORY + FACTIONS

| # | Test | Do | Expect |
|---|---|---|---|
| S1 | Journal opens on J | J | six tabs: Rumors, Confirmed, Active, Completed, Objectives, Factions; Esc closes |
| S2 | Factions tab | J -> Factions | Military Remnant / Boneyard raiders / The Enclave, each with a standing word, a bar and a blurb |
| S3 | Enlist | ob_tp zancudo_gate (or F10 -> Saved locations) -> armory target -> Enlist with the Remnant -> confirm | job military, radio jumps to channel 7, F1 Faction row says military, ★ on the Factions tab |
| S4 | Walk out costs standing | armory -> Walk out on the Remnant | standing -25, unemployed again; re-enlist inside 30 min refused |
| S5 | Join the Boneyard | raider cache at the Sandy boneyard -> Join the Boneyard | job raider, channel 13; soldiers hostile if outbreak_military is ever enabled |
| S6 | Chain 1 rumour to journal | tune channel 4, wait for the Grapeseed rumour, drive into the area | yellow area blip -> journal entry moves from Rumors to Confirmed |
| S7 | Director tools still work | F10 -> Story -> document / opportunity | document lands in pockets; reading it adds a journal entry |

## 5 TEN ADDITIONS

| # | Test | Do | Expect |
|---|---|---|---|
| T1 | 1 Locational treatment | ob_wound left_leg fracture + ob_wound torso bite; use a bandage, then a splint | bandage goes to the torso, splint to the leg; each notifies the part |
| T2 | 2 Infection from a dirty wound | ob_wound torso bite, leave it 20 min (or set dirtyMinutes = 1 in needs config and restart outbreak_needs) | "The bite on your torso has gone bad." -> infected; antibiotics inside the hour -> "Caught it early." |
| T3 | 3 Crew | G -> Crew -> Start a crew; friend within 6 m -> Invite nearest | they get a dialog; on accept: top-left panel lists both with a health line; blue CREW blip on the map |
| T4 | 4 Shared pins | G -> Crew -> Pin here "water" | yellow PIN: water (name) blip on BOTH maps; Clear pins removes it |
| T5 | 5 Compass | turn the camera; set a waypoint; hold a safehouse key | cardinals slide, N in rust; blue "waypoint" tick, bone "home" tick, amber pin ticks with labels |
| T6 | 6 Vehicle persistence | F10 -> Vehicle kit -> Spawn (search) Rebel; drive, dent it, put beans in the trunk; note fuel; restart the server | car is where you left it, dented, same fuel, beans still in the trunk, your key still opens it |
| T7 | 7 Trunk + glovebox | stand at the back of a car -> Open the trunk; sit in it -> G -> Glovebox | Trunk 25 slots; glovebox 5; a locked car you hold no key for says Locked |
| T8 | 8 Workbench | ob_give plank 2; ob_give nails 1; ob_give hammer_tool 1; ob_give workbench 1; G -> Set something down -> workbench; target it | "Use the workbench" -> Barricade kit; a house door -> Barricade consumes the kit (no planks needed). K alone shows field recipes only |
| T9 | 9 First ten minutes | /tutorial (or a brand-new character) | 8 numbered lines at the top in order; a sound per step; step 7 sets a waypoint to the nearest safehouse and ends when you reach it |
| T10 | 10 Journal as quest log | J -> Objectives | guide steps (done/open) and your settlement needs listed; Factions tab per S2 |

## 6 PRIOR SHEET

| # | Test | Do | Expect |
|---|---|---|---|
| P1 | Walkie: screen, channel keys, prop + anim, hiss | N; ] and [; CapsLock | radio screen; channel steps; radio in hand while talking; hiss at range |
| P2 | Admin: noclip / god / spectate / entity gun | F10 -> Admin | each works and turns off cleanly |
| P3 | Vehicle era + keys | F10 -> Vehicle kit -> World era; Spawn; Give me the key | era switches; spawns carry a key; Give me the key unlocks and fixes the car you aim at |
| P4 | Settlement ledger + cooking | claim a house, Door -> Settlement | stock bars, residents, cook |
| P5 | Sleep, tap, rain catcher | Door -> Sleep; Fill from the tap; place a rain catcher in RAIN | per TEST-CHECKLIST 9b |
| P6 | The Tide | wait ~90 s after joining | radio line + red radius; HUD THE TIDE inside it |
| P7 | Sneak: eye + suspicion + distraction | crouch near a zombie at night; throw a can | HIDDEN/NOTICED/SEEN; zombies walk to the can |
| P8 | Quiet kill | knife, stealth, behind an unseen zombie, E | [E] quiet kill prompt, takedown, no ripple |

## 7 Legacy

| # | Test | Do | Expect |
|---|---|---|---|
| A1 | Anim dictionaries | /ob_animcheck | 0 missing |
| A2 | Prop models | /ob_models prop_tool_bench02,prop_barrel_02a | all ok (tell me any INVALID) |
| C1 | Creator opens on first join | new character | illenium creator (known broken: see SHAKEDOWN-NOTES Deferred) |
| H2 | Search spots + picked-clean | search a dumpster twice | loot then refusal |
| H4 | Claim -> key; storage needs key | claim, drop key | refused w/o key |
| M2 | Crate storage + padlock + force | place crate | stash; pin sweep |
| D1 | Unconscious wakes at 2 min | /ob_down | veil, wake |
| D2 | Incapacitated; self-splint | get shot; E | red veil |
| D5 | Permadeath: epitaph, /fallen, corpse | let critical expire | all three |
| R2 | Radio channel filter | /ob_radio 9 test on channel 4 | NOT received |
| G1 | Controller: Up inv, Down wheel, Left radio, B cancel | pad | all four |

---
Generated 2026-09-15 by tools/gen_test_guide.py from shakedown.lua (71 steps). Edit the Lua, rerun the script.
