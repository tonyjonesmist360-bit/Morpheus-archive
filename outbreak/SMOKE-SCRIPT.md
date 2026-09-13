# SMOKE SCRIPT — first evening, top to bottom

One guided sequence. Every step has the command to type and the one thing to watch. Keep the server console
and F8 open. `setr ob_debug 1` and your ace group must be set (server.cfg.additions). Record the first FAIL
and its console lines; keep going past it where you can.

Legend: 🖥 server console · F8 client console · ▶ do · 👁 expect

**Panel:** press **F9** — the same steps as a live checklist on the right of the screen. ▲▼ select, **P** pass, **F** fail, **N** note (paste the console line), **L** write the summary. Or type `/pass W2`, `/fail H3 storage refused with key`. Everything goes to `outbreak_debug/shakedown.log`; paste that file to Claude at the end (or mid-run, whenever you're stuck) — it carries every mark, note, resource state, and boot event in one place.

## 0 · Boot (5 min)
▶ Start in txAdmin. 🖥 watch the ensure lines.
👁 No red `outbreak_*` lines. Yellow warnings fine. Any "dependency not found" → start-order problem; paste it.
▶ `connect localhost`. F8 open.
👁 No red `outbreak_*` lines on join.

## 1 · Instrument the world FIRST (10 min) — this pass kills the "name from memory" bugs before they cost time
▶ `/ob_animcheck` → 👁 "0 missing"; otherwise F8 lists which anim dicts are wrong → note them, we fix in one patch.
▶ `/ob_models prop_ld_planks01,prop_gaslamp_01,prop_cs_hand_radio,prop_cs_body_bag,prop_worklight_03b,prop_mil_crate_01,v_ret_ml_sweet1,v_ret_ml_chips1,v_ret_ml_bread01,prop_ecola_can`
   → 👁 all "ok"; INVALID ones get replaced.
▶ Walk into the nearest 24/7. `/ob_walk` on, aim along the shelves, `/ob_walk` off. F8 shows real shelf model names → we correct `WorldItemsCfg.Shelves`.
▶ `/ob_scan 6` inside a house → real cupboard/drawer prop names for future search spots.

## 2 · Survivor (5 min)
👁 Creator opened on join (face/clothes), then WHO WERE YOU (callsign, former life, 2 strengths, 1 flaw).
▶ `/skills` → 👁 traits listed; `handy` = Mechanics 2.
▶ Relog → 👁 no creator, no dialog.

## 3 · Spawn + HUD + radio (5 min)
👁 Motel floor, story text, kit in TAB. Vitals bars bottom-left, noise dot above them, no moodles yet.
▶ Use the radio (needs battery) → tune 4. 👁 within ~20 s the scenario transmission arrives (top of screen).
▶ `/ob_radio 0 hello` → 👁 arrives. `/ob_radio 9 test` → 👁 does NOT arrive (wrong channel).

## 4 · Noise + zombies (10 min)
▶ Crouch-walk (Ctrl) toward a shambler at 15 m → 👁 not noticed, dot small. Sprint → 👁 chased, ripple.
▶ `/ob_zombie 3` → 👁 three appear. Shoot once → 👁 ripple red, they converge.
▶ Wheel (G) → Listen → 👁 count + direction.
▶ `/ob_time 23` → 👁 blackout, runners appear. `/ob_weather THUNDER` → 👁 every ~90 s they surge.

## 5 · Wounds (10 min)
▶ Let one scratch you → 👁 "Scratch — <part>", Bleeding + open-wound moodles, HUD.
▶ G → Treat (1) → pick it → 👁 treat anim, wound closes, bandage gone.
▶ `/ob_wound right_leg fracture` → 👁 slowed. Splint via wheel → 👁 cleared.
▶ Get bitten a few times → 👁 eventually "The wound burns" + Anxious moodle. `/ob_state` 🖥 shows infected=true.

## 6 · Property (15 min)
▶ `/ob_tp sandy_bungalow`. Door target → 👁 occupant fight OR story text.
▶ Search the house → 3 spots → 👁 loot or "Nothing useful"; again → "Already picked clean".
▶ `restart outbreak_items` 🖥 → search again → 👁 STILL picked clean (persisted).
▶ Claim → 👁 `safehouse_key` in TAB with house metadata. Open storage. Drop the key → 👁 storage refuses.
▶ `/ob_tp grove_house` → Shelter inside (no claim) → 👁 interior loads; Leave → back out.
▶ Barricade (2 planks, nails, hammer) → 👁 level 1, planks at the door.

## 7 · Mutable world (10 min)
▶ G → Set something down → beans → 👁 ghost, Q/R, E → bottle on the ground. Target → Take → back.
▶ Place a crate → Open → stash; Padlock it → 👁 "Padlocked"; Force → pin sweep.
▶ `/writenote hello` → place it → target → Read → 👁 your text + your name.
▶ In the 24/7: Grab a shelf item → 👁 "Grabbing item…", ADDED ×1, prop gone. `restart` server later → 👁 still gone.

## 8 · Vehicles v2 (if ensured) (15 min)
▶ Walk to a parked car → F8 `Entity(<veh>).state.veh` (or just try the door) → 👁 locked/dead/fuel rolled.
▶ Pry (crowbar) → unlock. Sit in → 👁 reasons cycle: battery → part → fuel → splice. Splice → 👁 hotwired.
▶ Drive 2 min → 👁 fuel drops. Siphon into a can → pour into another car → 👁 transfers.
▶ `key_blank` → Cut a key → claimed. `restart` server → 👁 car is where you left it, fuel intact.

## 9 · Downed → critical → station (15 min, two people ideal)
▶ `/ob_down` → 👁 unconscious veil, wakes at 2 min.
▶ Bullets/fall → 👁 incapacitated veil, 10-min timer; E self-splint works with a splint.
▶ Let it expire → 👁 CRITICAL (black veil, 30 min). Friend: wheel → Carry → near car → Load → drive to Sandy Medical → Unload → station target → treat → 👁 wakes, "recovering" (no sprint).
▶ Solo: `/ob_give adrenaline_shot 1`, go incapacitated, use it → 👁 up at 10%.
▶ Let critical expire → 👁 epitaph, `/fallen` has the name, body bag lootable, character can't reload. `/ob_revive <id>` pulls a stuck player out.

## 10 · Restart persistence (10 min)
▶ `/ob_persist` 🖥 note values → `restart` server → relog → `/ob_state` 🖥 → 👁 needs/wounds/infection match; key, house, barricade, skills, placed items, taken props all intact.

## 11 · Director (5 min)
▶ F10 → Scenes → Helicopter crash → 👁 wrecks, MAYDAY, cache, dead marines, horde 45 s later. World → Ghost → 👁 invisible/invincible.
▶ 🖥 `outbreak_dm_log` has rows.

## 12 · Progression (if ensured) (20 min)
▶ Tune 4, wait ≤ 9 min → 👁 Grapeseed rumor, J → Rumors, radius blip east of Grapeseed (no centre).
▶ Drive into it → 👁 Confirmed; camp visible. `/ob_opp warn camp_defense_grapeseed` → 👁 Active with countdown.
▶ Deliver planks at the gate → 👁 defenses rise; `/ob_opp wave camp_defense_grapeseed` → 👁 wave from the south, guards fight.
▶ `/ob_opp part armored_bus`, `/ob_opp kit repeater`, `/ob_opp pages weapons_cache`, `/ob_opp kit island` seed the other chains for later evenings.

## 13 · Controller (5 min)
▶ Pad: D-pad Up inventory, Down wheel, Left radio, B cancel; journal D-pad nav; wheel select.

STOP. Paste every red line and every FAIL. That's the patch list.
