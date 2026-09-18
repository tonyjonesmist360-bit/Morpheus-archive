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

## 8 BUGFIXES

| # | Test | Do | Expect |
|---|---|---|---|
| G1 | Gun store: weapons free to take | Sandy Shores Ammunation, walk to the rack (zone may need /ob_site_here if the marker is off) | "Take weapons off the rack" target; items land in pockets |
| G2 | No licence, no money | same store, look for any shop prompt at the counter | none. No "Open shop", no licence text, Old Money untouched |
| G3 | Ammo safe | the safe zone behind the counter | "Force the ammo safe" -> pin sweep -> ammo / pistol / weapon kit; loud ripple |
| G4 | Gun store shopkeeper gone | look behind the counter | no ped selling anything |
| N1 | Bank NPC gone | Fleeca Legion Square, walk in | no teller, no bank prompt |
| N2 | Bank menu unavailable | any ATM or bank counter, press E | nothing opens |
| N3 | Bank is a loot location | the vault room zone | "Crack the vault" target |
| N4 | Vault pin sweep | do it | pin sweep (4-5 pins), Old Money x40-120, maybe a document; a loud ripple |
| L1 | House loot no longer at the door | Grove St house door menu | "Search inside" note only; no Kitchen/Bathroom/Bedroom entries at the door |
| L2 | Interior spots exist | Go inside, look around the entry | five "Search ..." zones: kitchen counter, bedroom drawers, bathroom cabinet, living room shelves, office desk (seeded near the entry) |
| L3 | Move a spot to the real kitchen | walk to the kitchen counter: /ob_spot grove_house house Kitchen counter | "Moved: Kitchen counter"; the zone is now there for everyone, and after a restart |
| L4 | Place bedroom / bathroom / living / office | /ob_spot grove_house house Bedroom drawers ; /ob_spot grove_house medical Bathroom cabinet ; ... (repeat per interior house) | each moves; /ob_spot_del <id> removes one |
| L5 | Prompt shows the location name | aim at a spot | "Search kitchen counter" (not "Search") |
| L6 | Find shows where + journal | search it; then J -> Objectives | "Kitchen counter: canned beans x2" notify; the same line under Objectives as a recent find |
| L7 | Exterior-only house keeps a named door menu | Sandy bungalow door | Search the house -> Kitchen cupboards / Bathroom cabinet / Bedroom drawers still work, finds named |
| L8 | Picked clean respects tuning | search twice; ob_tune set loot.respawnMinutes 1; wait a minute; search | refused, then allowed after the change (no restart) |

## 9 OPS

| # | Test | Do | Expect |
|---|---|---|---|
| O1 | Tuning live | console: ob_tune ; ob_tune set zombies.maxPerPlayer 30 | list prints; within a minute more zombies around you; ob_tune reset |
| O2 | Schedules re-read | ob_tune set director.everyMin 1 ; ob_tune set director.everyMax 2 ; server stats | schedules line shows director 1-2 min; a pass fires within ~3 min (logs kind:director) |
| O3 | Admin suite | /time set 23 ; /weather set THUNDER ; /spawn mob runner 3 ; /trigger encounter rumor_food ; /settle morale 10 ; /loot reset | each acts and answers in chat |
| O4 | Logs | console: logs ; logs kind:admin ; event log | today's lines, format date | src:name:cid | kind | json |
| O5 | Server stats | server stats | players, uptime, memory, loop avg/worst lateness, schedules |
| O6 | Restart warning | console: restart_warn 5 | banner + notify + radio static line; logs kind:ops |
| O7 | Mute | /mute <friend id> 1 test ; they type in chat and key the radio | chat refused, radio silent, unmuted after a minute |
| O8 | Kick / ban / unban | /ban <friend id> 1 test ; they reconnect ; /unban <name> | dropped with the reason; refused for a minute; then in |
| O9 | Hotfix reload | /hotfix reload outbreak_minigames | that resource restarts; you keep playing |
| O10 | Restore preview (offline) | PowerShell: ops\\restore-backup.ps1 then -Date <today> | lists backups; preview names what would move aside |

## 10 AUTHORITY

| # | Test | Do | Expect |
|---|---|---|---|
| A1 | Pin sweep still works (token round-trip) | force a padlocked crate / a locked house | minigame plays; on win the stash opens as before; F8 clean |
| A2 | Forged result does nothing | F8: TriggerServerEvent("outbreak:wi:forced", <crate id>)  (find the id with Look closer / ob_state) | nothing opens; with ob_debug 1 the console prints an [OB-AUTH] refusal |
| A3 | Zombie wound still lands (witness) | get scratched by a zombie | Scratch/Bite lands as before. If it does NOT, tell me: weaponDamageEvent may be silent for NPC melee and the health witness must carry it |
| A4 | Forged wound refused | F8: TriggerServerEvent("outbreak:server:wound", "head", "gunshot") while untouched | no wound; logs kind:needs.woundRejected has a line |
| A5 | Fists are bruises whatever is claimed | friend punches you | bruise, never a laceration |
| A6 | Battery / parts are skill checks | dead-battery car, Install battery | pry minigame first (unless mechanics >= 5), then the swap |
| A7 | Strip a car | unclaimed running car -> Pull the battery / Strip engine parts | check, then the item in pockets and the car dead / part missing |
| A8 | Too fast is refused | ask a friend to spam-win a minigame with a macro (or set pins very high and win instantly) | refused; logs kind:minigame.reject shows "too fast" |

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
Generated 2026-09-18 by tools/gen_test_guide.py from shakedown.lua (105 steps). Edit the Lua, rerun the script.
