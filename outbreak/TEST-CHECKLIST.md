# TEST CHECKLIST — v0.17.0 overnight build (2026-09-14)

Walk it top to bottom. **★ = built blind** (sound, animation, voice or a native name I could not verify
from here). Mark each ✓ / ✗ and `/bug` anything that fails so the position and note land in
`outbreak_debug/bugs.log`. Boot first with `setr ob_debug 1` and your `outbreak.admin` / `outbreak.dm` aces.

## 0 · Deploy + boot
- [ ] `02-copy-resources` → `27 resources`; `04-paste-ins -Only items -Force` → managed block replaced; `07-update-cfg -Apply` → `28 outbreak_ ensure lines`, no lost lines
- [ ] Boot: `outbreak_chat` after binds, `outbreak_loadscreen` started, `outbreak_supply` + `outbreak_director` after dm, `outbreak_ambience` after wheel; `Inventory has loaded 349 items`; no red
- [ ] ★ Connecting shows the **DEAD STATE** loading screen (rules, tips, progress bar), not the Qbox one
- [ ] MOTD appears in chat + a top notify ~6 s after your character loads

## 1 · P0 — downed access
- [ ] `/ob_kit` then `/ob_down` → you go down (unconscious). **T opens chat.** Type `/ooc testing` → grey bracketed OOC line for everyone
- [ ] **G opens the downed wheel**: Distress, Radio, Vitals, OOC hint, DIRECTOR (if DM). Prompt line at the bottom names the keys
- [ ] `/ob_wound right_leg gunshot` then `/ob_down` → **incapacitated**; timer reads **5:00**
- [ ] With a splint: **E** → 20 s "Splinting yourself…" → up at 20 % health. Also via wheel → Splint yourself
- [ ] `/ob_give adrenaline_shot 1`, go down incapacitated, wheel → **Adrenaline** → up at 10 %, fatigue −40
- [ ] **F6** while down: with a tuned radio → "Mayday sent on channel N"; a second player on that channel gets a flashing red blip + MAYDAY radio text with your street. Without a radio → "You scream for help", players within 250 m get the blip, noise spikes
- [ ] **F10** opens the Director menu while down (DM)
- [ ] Admin: `/announce hello` → styled red banner in chat + top notify for everyone
- [ ] ★ `/ob_give mumble_pill 1`, use it → "Voice reset. Mumble was connected, now connected." Admin: `/voicereset <id>` does the same to them. (Whether it fixes a real dead-mic case: test when one happens)

## 2 · P1 — the walkie
- [ ] Radio in pockets, N → **the radio screen** (LCD, SIG/BAT bars, TX/RX). Type `4` Enter → CH 04, arm raises briefly, squelch click ★
- [ ] `]` / `[` step channels without the screen. `/radio 7` tunes from chat. No radio in pockets → "You don't have a radio."
- [ ] ★ Hold CapsLock → **hand radio prop appears, arm up**, TX lights on the screen, click; release → arm down, release click + static tail
- [ ] ★ Second player keys on your channel → hiss under their voice, RX + their name on the screen, **their voice is distorted** (radio-FX submix), `((radio))` floats over their head within 25 m
- [ ] ★ Same at range edge (>1 km, or `RadioCfg.Handheld.range = 200` to test) → rougher static loop, "((radio: weak))"
- [ ] Walk into an interior (a claimed house with an interior, or a store) → SIG bars drop; keying → "No signal. Too deep." Both sides indoors = near-silent
- [ ] BAT bars fall over 45 min; spare batteries now drop from house drawers and tool chests (`/ob_scan` a toolchest, search it a few times)
- [ ] `/ob_voicereset` prints Mumble before/after in F8 with debug on

## 3 · P3 — admin console (F10 → Admin)
- [ ] **Player panel** lists everyone with HP/food/water/rest, tags (INFECTED, downed, ghost, god), coords, radio ch. Per player: Heal (full reset), Feed, Revive, Freeze/Unfreeze, Teleport to, Bring, Spectate, Give (search), Voice reset
- [ ] **Noclip** (`/noclip`): WASD + Space/Ctrl, Shift fast; body frozen for others; off restores collision
- [ ] **God**: visible, `/ob_zombie 5` cannot hurt you; off restores. Separate from ghost
- [ ] **Ghost**: second player cannot see you; zombies ignore you; you are semi-transparent to yourself; off restores
- [ ] **Spectate** a nearby player → their camera; `/spectate` stops. Far player → the "teleport first" message
- [ ] **Teleport to waypoint** lands you on the ground at the map marker. **Saved locations** menu works. `/coords` → notify + clipboard has `vec4(...)`
- [ ] **Entity gun**: aim a prop / vehicle / ped, click → gone (networked ones via server)
- [ ] **Zombie controls**: spawn one at cursor, horde at cursor, clear 60 m, freeze/release AI
- [ ] **Vehicle kit**: spawn, then damage it, Repair → fixed; Refuel → 100 %; Delete
- [ ] **Give (search)**: type "band" → bandage from ox's full catalogue
- [ ] Every action is a row in `outbreak_dm_log`

## 4 · P4 — test infrastructure
- [ ] `/ob_hud` → five overlay lines top-left (coords/street, fps/tick/interior/zone, noise/zombies/radio, speed/state/hp, time/weather). Again → off
- [ ] `/bug the door menu did not open` → "Bug logged"; `outbreak_debug/bugs.log` has a JSON line with your position

## 5 · P5 — polish
- [ ] ★ **Ambience**: outdoors, a low wind bed; louder at night; quieter indoors or in a car. With zombies within 60 m, distant groans every ~20–55 s, more with more of them
- [ ] Weather over an hour is mostly overcast/fog/rain; `ob_weather CLEAR` still works
- [ ] ★ Discord shows "Surviving Sandy Shores · N survivors" (text-only until `AmbienceCfg.Discord.appId` is set)
- [ ] Nights: blackout as before (the timecycle darkening is **off** by default — `AmbienceCfg.NightTimecycle` is nil because the name was unverified)

## 6 · P6 — settlement defense event
- [ ] Claimed house with 2 residents (F10 → Story → Settlement +2). Put 20 `ammo-9` and 2 planks in the stockpile
- [ ] F10 → Story → **DEFENSE EVENT now** (or `/ob_defend sandy_bungalow`) → radio warning, "They are coming to …" notify, flashing red blip on the door, **THEY ARE COMING 4:00** countdown at the top
- [ ] At 0:00 → "They are at the door", a horde of ~14 on the nearest keyholder, countdown **HOLD THE DOOR 3:00**
- [ ] Stay alive within 60 m of the door until 0:00 → "It held." ledger line: rounds spent, a part used; morale +8; radio "held"
- [ ] Repeat and walk away / die → "Overrun." best food/water/medicine gone, barricade −1, morale −15, maybe a resident lost; radio "went dark"
- [ ] Restart mid-event → event silently cancels (known: timers are not persisted)

## 7 · P7 — residents you can see
- [ ] Walk to a settlement with residents → up to 4 peds around the door within 55 m, doing scenarios; **Talk to <name>** gives a line
- [ ] F10 → Settlement morale −45 → within a few seconds the bodies rebuild: slumped/impatient/drinking, lines turn dark
- [ ] Walk 75 m away → they despawn; back → they return

## 8 · Starter kit + backup
- [ ] Fresh character: beans, knife (`WEAPON_KNIFE`), clean water in pockets on top of the scenario kit
- [ ] Elevated PowerShell: `ops\install-backup-task.ps1 -RunNow` → task registered, backup runs, `verify-backup.ps1` prints **PASS** (23 tables in the dump, `server.cfg` + ≥20 `[outbreak]` files in the zip). Add `-RestoreTest` for the scratch-DB restore

## 9 · P2 — the partial
- [ ] Inventory: beans/water/bandage/radio/bread/soda tiles show ox's stock icons ★ (blank tile = that name is not in your ox_inventory `web/images`; tell me which)
- [ ] `/walkstyle` → menu; `injured` works (confirmed clipset); try the others — any that say **INVALID** are names from memory, tell me which
- [ ] `/crouch` (or wheel → Crouch) → crouched clipset ★; again → normal

## 9b · v0.18 — sleep, water sources, the Tide
- [ ] Door → **Sleep** (keyholder) → screen fades black, "Sleeping [E] wake up", rest pose ★; after 4 min → "You slept." fatigue full, hunger −8, thirst −10. E early → partial credit (server pays by elapsed time)
- [ ] Sleep with a zombie spawned within 60 m (`/ob_zombie 1` from a friend) → "Something is outside." and you are up
- [ ] Interior house: **Bed — sleep** target 2 m left of the entry point (opposite the wardrobe) does the same
- [ ] Door → **Fill from the tap** → 4 s pour anim → 1 murky water; fifth draw in the same hour → "Dry. It coughs air."
- [ ] `/ob_give rain_catcher 1`, wheel → Set something down → ★ a barrel prop (or the fallback bag if `prop_barrel_02a` is wrong — tell me). `ob_weather RAIN`; each entropy tick (10 min, or set `tickMinutes = 1`) adds 1 murky water to it, cap 8. Open it like a crate
- [ ] ~90 s after the first player joins, radio: "...they are moving through <area>..." and a **red radius** on the map; F1 → World → The Tide names it; HUD strip shows **THE TIDE** in rust when you stand in it; zombie density there is ~2×. `/ob_tide` moves it (debug)
- [ ] A settlement inside the Tide gets defense events far more often (probe weight ×3) — F10 → Director pass while your house is in the red

## 9c · v0.19 — sneak: visibility, suspicion, the eye, distractions
- [ ] HUD: an **eye** beside the noise dot with a word under it. Standing in daylight: UNSEEN. Crouched (Ctrl stealth or /crouch) and still at night: HIDDEN. Sprinting with a flashlight at night: EXPOSED. F1 → World → Visibility shows the number
- [ ] `/ob_zombie 1` at ~20 m in daylight, stand still in its view → it **turns to face you**, the eye opens, NOTICED, then SEEN and it charges (~3 s). Break line of sight before SEEN → the eye closes again
- [ ] Same at night, crouched, fog (`ob_weather FOGGY`, `ob_time 23`) → you can get within ~5 m before it notices; inside 6 m it charges regardless
- [ ] Sprint straight at one → instant (noise still works as before)
- [ ] Wheel → **Throw a distraction** with a soda/beer in pockets → can arcs out ★, lands, zombies within 40 m walk to it and stand there; your own noise barely moves. No can → "Nothing to throw."
- [ ] Stealth skill levels reduce both noise and visibility (skills panel)

## 9d · v0.20 — quiet kill
- [ ] **Engine takedown first:** Ctrl stealth, knife out, walk up behind an UNSEEN/NOTICED zombie, melee. Does GTA's own takedown animation play? (Free if yes; tell me either way)
- [ ] **Scripted:** same approach → `[E] quiet kill` prompt appears on the right only when: stealth/crouched + blade/blunt in hand + within 1.7 m + behind it + not SEEN. Step in front → prompt goes
- [ ] E → you snap to its back, ★ takedown animation (or a plain stab if both dicts are INVALID — F8 says which), it drops, **noise dot does not ripple**, "Quiet."
- [ ] With `HeadshotOnly = true` it stays down (quiet kills are exempt from the get-back-up)
- [ ] Runner at night → "It twists out of your grip", half health, noise, it fights you. Bloater → "Not that one."
- [ ] Skills → stealth XP +10 per quiet kill

## 9f · v0.22 — see TEST-GUIDE.md (generated) and press F9
The overnight-sheet-2 run lives in `TEST-GUIDE.md`, generated from the F9 table. Sections below stay for reference.

## 9e · v0.21 — vehicles: era, keys, admin list
- [ ] Boot log: no red `[OB-VEH] qbx_vehiclekeys is running` line. If there is one, `stop qbx_vehiclekeys` in the console and retry the next line; if that fixes entry, comment its ensure out of server.cfg (your call, tell me)
- [ ] Walk up to 5 parked ambient cars: ~4 open. Sit in one → no "No keys — press [E]" prompt on more than half of them (keys in the ignition); the rest need the splice. `ob_debug 1` prints `[OB-VEH]` lines on register
- [ ] F10 → Admin → Vehicle kit → **Spawn (search)** → type "reb" → Rebel. It appears beside you, "Spawned. The key is in your pocket.", a Vehicle Key item with the plate; door opens, engine runs, ox_target → Lock / unlock works
- [ ] **Spawn by model name** → `kamacho` (DLC) → spawns if the server has it, else "Unknown vehicle model"
- [ ] Aim at any ambient car → Vehicle kit → **Give me the key** → key in pocket, it unlocks and runs, fuel ≥ 80
- [ ] Vehicle kit → **World era** → live → "Vehicle era: live"; `restart outbreak_vehicles` → the same 5 cars now: ~3 locked, batteries dead, tanks near empty. Switch back to early
- [ ] Console: `ob_vehera` (no arg) prints the current era
- [ ] (v0.20.2) `/crouch`, then swing at a zombie → you stand for the hit and re-crouch ~1.5 s after

## 10 · Still v0.16 (if not yet walked)
- [ ] `SMOKE-SCRIPT.md §14` S1–S8: settlement ledger, cooking, consumption, morale behaviours, stranger, rumour, F1 Home column
