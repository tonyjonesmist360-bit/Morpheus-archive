-- outbreak_debug/client/shakedown.lua — the in-game F9 TEST MENU. Every entry: what to do, what
-- you should see, PASS / FAIL. Marks write to the server log (shakedown.log, JSON lines) and to a
-- readable shakedown-results.md; both are what Claude reads tomorrow.
-- Keys while open (passive, you keep playing): ▲▼ select · P pass · F fail · N note · L export
-- M = mouse mode: the panel takes the cursor so the PASS / FAIL buttons work; Esc or M gives it back.
-- TEST-GUIDE.md is generated from this table (tools/gen_test_guide.py) - edit here, never there.
local open, sel, mouse = false, 1, false
local Steps = {
  -- ── 0 BOOT ──
  { sec = '0 Boot', id = 'B1', label = 'Server ONLINE, no red outbreak_* lines', cmd = 'watch the txAdmin console during boot', expect = '33 outbreak_ resources start clean' },
  { sec = '0 Boot', id = 'B2', label = 'Client joined, F8 clean', cmd = 'connect, open F8', expect = 'no red lines; no "Invalid key name"' },
  { sec = '0 Boot', id = 'B4', label = 'Test mode', cmd = '/testmode (or F10 -> Admin -> Test mode), then ob_needs 0 0 0 and stand next to a zombie', expect = 'bars refill and stay full; health never drops; zombies and raiders ignore you; you see yourself translucent; a friend does not see you. /testmode off restores' },
  { sec = '0 Boot', id = 'B3', label = 'No qbx_vehiclekeys warning', cmd = 'search the boot log for [OB-VEH]', expect = 'no red "qbx_vehiclekeys is running" line (if there is one, stop it and tell me)' },
  -- ── 1 CORE MECHANICS (protected list) ──
  { sec = '1 CORE MECHANICS', id = 'K1', label = 'Enter / exit a car as driver', cmd = 'walk to an unlocked car, F', expect = 'you get in; F again gets you out. Repeat on 3 cars' },
  { sec = '1 CORE MECHANICS', id = 'K2', label = 'Enter as passenger', cmd = 'stand at a passenger door, hold F', expect = 'you take the passenger seat, not the wheel' },
  { sec = '1 CORE MECHANICS', id = 'K3', label = 'Locked car: pry then enter', cmd = 'ob_give crowbar_tool 1; find a locked car (ob_vehera live, restart outbreak_vehicles to get some); Pry the door', expect = 'pry minigame, door opens, you can enter' },
  { sec = '1 CORE MECHANICS', id = 'K4', label = 'Punch', cmd = 'fists out, ob_zombie 1, swing', expect = 'punches land; zombie reacts; no frozen arms' },
  { sec = '1 CORE MECHANICS', id = 'K5', label = 'Punch while crouched', cmd = '/crouch, then swing', expect = 'you stand for the hit and re-crouch ~1.5 s after' },
  { sec = '1 CORE MECHANICS', id = 'K6', label = 'Weapon draw / holster', cmd = 'knife on hotbar 1: press 1, press 1 again', expect = 'draws, holsters; TAB shows it equipped/unequipped' },
  { sec = '1 CORE MECHANICS', id = 'K7', label = 'Fire a gun', cmd = 'ob_give WEAPON_PISTOL 1; ob_give ammo-9 24; equip, shoot', expect = 'shots fire; noise dot goes red; no JAMMED text above 30% condition' },
  { sec = '1 CORE MECHANICS', id = 'K8', label = 'Sprint / jump / climb', cmd = 'ob_needs 100 100 100; Shift, Space, vault a fence', expect = 'all three work' },
  { sec = '1 CORE MECHANICS', id = 'K9', label = 'Sprint cut when exhausted', cmd = 'ob_needs 100 100 10; hold Shift', expect = 'no sprint (jog only); ob_needs 100 100 100 -> sprint again. UNVERIFIED native: if sprint still works, mark FAIL and tell me' },
  { sec = '1 CORE MECHANICS', id = 'K10', label = 'Swim', cmd = 'walk into the sea, swim, climb out', expect = 'normal swimming, no stuck state' },
  { sec = '1 CORE MECHANICS', id = 'K11', label = 'Ragdoll / get up', cmd = 'jump off something ~4 m high', expect = 'ragdoll, get up, walk. If you go DOWN it is the wound system, not a bug' },
  { sec = '1 CORE MECHANICS', id = 'K12', label = 'Ladder', cmd = 'climb any ladder (billboards, roofs)', expect = 'up and down' },
  { sec = '1 CORE MECHANICS', id = 'K13', label = 'Cover', cmd = 'Q against a wall', expect = 'cover taken and left' },
  { sec = '1 CORE MECHANICS', id = 'K14', label = 'Pad: D-pad Up opens inventory', cmd = 'controller, D-pad Up', expect = 'inventory opens (the radio used to eat this button)' },
  -- ── 2 UI + BODY SCAN ──
  { sec = '2 UI + BODY SCAN', id = 'U1', label = 'HUD layout at 1080p', cmd = 'look', expect = 'bars bottom-left, faint body beside them, noise dot + eye above, compass top-centre; nothing overlaps' },
  { sec = '2 UI + BODY SCAN', id = 'U2', label = 'Scratch shows on the body', cmd = 'ob_wound left_arm scratch', expect = 'left arm region rust and throbbing on HUD and F1; Bleeding moodle' },
  { sec = '2 UI + BODY SCAN', id = 'U3', label = 'Hover + click to treat', cmd = 'F1, hover the arm, then click it (have a bandage: ob_give bandage 2)', expect = 'tooltip: Scratch - Open and bleeding. Treat with: ripped sheet or bandage. Click -> panel closes, bandage anim, region goes dim' },
  { sec = '2 UI + BODY SCAN', id = 'U4', label = 'Broken leg = limp until splinted', cmd = 'ob_wound right_leg fracture; walk; ob_give splint 1; treat', expect = 'leg region blood + cross; you LIMP (injured walk); after splint you walk normally' },
  { sec = '2 UI + BODY SCAN', id = 'U5', label = 'Torso wound = sprint drains', cmd = 'ob_wound torso laceration; sprint', expect = 'sprint cuts out after ~3 s, repeatedly; bandage it -> holds' },
  { sec = '2 UI + BODY SCAN', id = 'U6', label = 'Arm wound = sights sway', cmd = 'ob_wound right_arm gunshot; aim the pistol', expect = 'camera hand-shake while aiming; bandage -> still' },
  { sec = '2 UI + BODY SCAN', id = 'U7', label = 'Bruise from fists, painkillers fix', cmd = 'have a friend punch you (or ob_wound head bruise); ob_give painkillers 1; use them', expect = 'amber region; painkillers -> "Treated: head"; region clears' },
  { sec = '2 UI + BODY SCAN', id = 'U8', label = 'Wrong item, wrong wound', cmd = 'with only a bandage, ob_wound left_leg fracture, use the bandage', expect = '"Nothing on you needs that" - bandage NOT consumed' },
  { sec = '2 UI + BODY SCAN', id = 'U9', label = 'Every menu ESC-closes', cmd = 'F1, J, N, G, F10, K, F9 M-mode: open each, Esc', expect = 'each closes; cursor never sticks; text prompts never linger' },
  { sec = '2 UI + BODY SCAN', id = 'U10', label = 'No debug text', cmd = 'look at the screen with /ob_hud OFF', expect = 'no coordinates / fps / OB-lines on screen' },
  -- ── 3 ECONOMY / LOOTING ──
  { sec = '3 ECONOMY / LOOTING', id = 'E1', label = 'Shelves are theft', cmd = 'Sandy 24/7, aim at chips/water on a shelf', expect = 'target reads STEAL (mask icon); each take ripples the noise dot; about 1 in 8 "A can hits the floor" with a big ripple' },
  { sec = '3 ECONOMY / LOOTING', id = 'E2', label = 'Force the register', cmd = 'aim at the till', expect = '"Force the register", pry anim, loud ripple, old money comes out' },
  { sec = '3 ECONOMY / LOOTING', id = 'E3', label = 'Dead money', cmd = 'use the Old Money item', expect = '"$N, more or less." Nothing to buy anywhere. Drag to a friend to trade' },
  { sec = '3 ECONOMY / LOOTING', id = 'E4', label = 'Vending machine', cmd = 'aim at a soda machine', expect = '"Break into the machine", loud, water/beans/old money' },
  { sec = '3 ECONOMY / LOOTING', id = 'E5', label = 'No shopping anywhere', cmd = 'walk up to the 24/7 counter and any ox shop point', expect = 'no "Open shop" / buy menu. If one appears, tell me where (needs ox_inventory/data/shops.lua blanked)' },
  { sec = '3 ECONOMY / LOOTING', id = 'E6', label = 'Map key', cmd = 'open the map; then G -> Map key', expect = 'no shop / bank / clothing / ammunation / LS Customs blips; the legend names every blip you can see; hovering a blip on the map shows its name' },
  { sec = '3 ECONOMY / LOOTING', id = 'E7', label = 'SANDY 24/7 CLEANUP', cmd = 'console: ob_scene_clear 1960.5 3740.6 32.3 45  then walk there', expect = 'the parked car and the barricade props are gone; console names a backup file; store door works, shelves STEAL-able' },
  { sec = '3 ECONOMY / LOOTING', id = 'E8', label = 'Cleanup survives a restart', cmd = 'restart the server, revisit the 24/7', expect = 'still gone (nothing respawns them)' },
  -- ── 4 STORY + FACTIONS ──
  { sec = '4 STORY + FACTIONS', id = 'S1', label = 'Journal opens on J', cmd = 'J', expect = 'six tabs: Rumors, Confirmed, Active, Completed, Objectives, Factions; Esc closes' },
  { sec = '4 STORY + FACTIONS', id = 'S2', label = 'Factions tab', cmd = 'J -> Factions', expect = 'Military Remnant / Boneyard raiders / The Enclave, each with a standing word, a bar and a blurb' },
  { sec = '4 STORY + FACTIONS', id = 'S3', label = 'Enlist', cmd = 'ob_tp zancudo_gate (or F10 -> Saved locations) -> armory target -> Enlist with the Remnant -> confirm', expect = 'job military, radio jumps to channel 7, F1 Faction row says military, ★ on the Factions tab' },
  { sec = '4 STORY + FACTIONS', id = 'S4', label = 'Walk out costs standing', cmd = 'armory -> Walk out on the Remnant', expect = 'standing -25, unemployed again; re-enlist inside 30 min refused' },
  { sec = '4 STORY + FACTIONS', id = 'S5', label = 'Join the Boneyard', cmd = 'raider cache at the Sandy boneyard -> Join the Boneyard', expect = 'job raider, channel 13; soldiers hostile if outbreak_military is ever enabled' },
  { sec = '4 STORY + FACTIONS', id = 'S6', label = 'Chain 1 rumour to journal', cmd = 'tune channel 4, wait for the Grapeseed rumour, drive into the area', expect = 'yellow area blip -> journal entry moves from Rumors to Confirmed' },
  { sec = '4 STORY + FACTIONS', id = 'S7', label = 'Director tools still work', cmd = 'F10 -> Story -> document / opportunity', expect = 'document lands in pockets; reading it adds a journal entry' },
  -- ── 5 TEN ADDITIONS ──
  { sec = '5 TEN ADDITIONS', id = 'T1', label = '1 Locational treatment', cmd = 'ob_wound left_leg fracture + ob_wound torso bite; use a bandage, then a splint', expect = 'bandage goes to the torso, splint to the leg; each notifies the part' },
  { sec = '5 TEN ADDITIONS', id = 'T2', label = '2 Infection from a dirty wound', cmd = 'ob_wound torso bite, leave it 20 min (or set dirtyMinutes = 1 in needs config and restart outbreak_needs)', expect = '"The bite on your torso has gone bad." -> infected; antibiotics inside the hour -> "Caught it early."' },
  { sec = '5 TEN ADDITIONS', id = 'T3', label = '3 Crew', cmd = 'G -> Crew -> Start a crew; friend within 6 m -> Invite nearest', expect = 'they get a dialog; on accept: top-left panel lists both with a health line; blue CREW blip on the map' },
  { sec = '5 TEN ADDITIONS', id = 'T4', label = '4 Shared pins', cmd = 'G -> Crew -> Pin here "water"', expect = 'yellow PIN: water (name) blip on BOTH maps; Clear pins removes it' },
  { sec = '5 TEN ADDITIONS', id = 'T5', label = '5 Compass', cmd = 'turn the camera; set a waypoint; hold a safehouse key', expect = 'cardinals slide, N in rust; blue "waypoint" tick, bone "home" tick, amber pin ticks with labels' },
  { sec = '5 TEN ADDITIONS', id = 'T6', label = '6 Vehicle persistence', cmd = 'F10 -> Vehicle kit -> Spawn (search) Rebel; drive, dent it, put beans in the trunk; note fuel; restart the server', expect = 'car is where you left it, dented, same fuel, beans still in the trunk, your key still opens it' },
  { sec = '5 TEN ADDITIONS', id = 'T7', label = '7 Trunk + glovebox', cmd = 'stand at the back of a car -> Open the trunk; sit in it -> G -> Glovebox', expect = 'Trunk 25 slots; glovebox 5; a locked car you hold no key for says Locked' },
  { sec = '5 TEN ADDITIONS', id = 'T8', label = '8 Workbench', cmd = 'ob_give plank 2; ob_give nails 1; ob_give hammer_tool 1; ob_give workbench 1; G -> Set something down -> workbench; target it', expect = '"Use the workbench" -> Barricade kit; a house door -> Barricade consumes the kit (no planks needed). K alone shows field recipes only' },
  { sec = '5 TEN ADDITIONS', id = 'T9', label = '9 First ten minutes', cmd = '/tutorial (or a brand-new character)', expect = '8 numbered lines at the top in order; a sound per step; step 7 sets a waypoint to the nearest safehouse and ends when you reach it' },
  { sec = '5 TEN ADDITIONS', id = 'T10', label = '10 Journal as quest log', cmd = 'J -> Objectives', expect = 'guide steps (done/open) and your settlement needs listed; Factions tab per S2' },
  -- ── 8 SHEET 3 BUGFIXES ──
  { sec = '8 BUGFIXES', id = 'G1', label = 'Gun store: weapons free to take', cmd = 'Sandy Shores Ammunation, walk to the rack (zone may need /ob_site_here if the marker is off)', expect = '"Take weapons off the rack" target; items land in pockets' },
  { sec = '8 BUGFIXES', id = 'G2', label = 'No licence, no money', cmd = 'same store, look for any shop prompt at the counter', expect = 'none. No "Open shop", no licence text, Old Money untouched' },
  { sec = '8 BUGFIXES', id = 'G3', label = 'Ammo safe', cmd = 'the safe zone behind the counter', expect = '"Force the ammo safe" -> pin sweep -> ammo / pistol / weapon kit; loud ripple' },
  { sec = '8 BUGFIXES', id = 'G4', label = 'Gun store shopkeeper gone', cmd = 'look behind the counter', expect = 'no ped selling anything' },
  { sec = '8 BUGFIXES', id = 'N1', label = 'Bank NPC gone', cmd = 'Fleeca Legion Square, walk in', expect = 'no teller, no bank prompt' },
  { sec = '8 BUGFIXES', id = 'N2', label = 'Bank menu unavailable', cmd = 'any ATM or bank counter, press E', expect = 'nothing opens' },
  { sec = '8 BUGFIXES', id = 'N3', label = 'Bank is a loot location', cmd = 'the vault room zone', expect = '"Crack the vault" target' },
  { sec = '8 BUGFIXES', id = 'N4', label = 'Vault pin sweep', cmd = 'do it', expect = 'pin sweep (4-5 pins), Old Money x40-120, maybe a document; a loud ripple' },
  { sec = '8 BUGFIXES', id = 'L1', label = 'House loot no longer at the door', cmd = 'Grove St house door menu', expect = '"Search inside" note only; no Kitchen/Bathroom/Bedroom entries at the door' },
  { sec = '8 BUGFIXES', id = 'L2', label = 'Interior spots exist', cmd = 'Go inside, look around the entry', expect = 'five "Search ..." zones: kitchen counter, bedroom drawers, bathroom cabinet, living room shelves, office desk (seeded near the entry)' },
  { sec = '8 BUGFIXES', id = 'L3', label = 'Move a spot to the real kitchen', cmd = 'walk to the kitchen counter: /ob_spot grove_house house Kitchen counter', expect = '"Moved: Kitchen counter"; the zone is now there for everyone, and after a restart' },
  { sec = '8 BUGFIXES', id = 'L4', label = 'Place bedroom / bathroom / living / office', cmd = '/ob_spot grove_house house Bedroom drawers ; /ob_spot grove_house medical Bathroom cabinet ; ... (repeat per interior house)', expect = 'each moves; /ob_spot_del <id> removes one' },
  { sec = '8 BUGFIXES', id = 'L5', label = 'Prompt shows the location name', cmd = 'aim at a spot', expect = '"Search kitchen counter" (not "Search")' },
  { sec = '8 BUGFIXES', id = 'L6', label = 'Find shows where + journal', cmd = 'search it; then J -> Objectives', expect = '"Kitchen counter: canned beans x2" notify; the same line under Objectives as a recent find' },
  { sec = '8 BUGFIXES', id = 'L7', label = 'Exterior-only house keeps a named door menu', cmd = 'Sandy bungalow door', expect = 'Search the house -> Kitchen cupboards / Bathroom cabinet / Bedroom drawers still work, finds named' },
  { sec = '8 BUGFIXES', id = 'L8', label = 'Picked clean respects tuning', cmd = 'search twice; ob_tune set loot.respawnMinutes 1; wait a minute; search', expect = 'refused, then allowed after the change (no restart)' },
  -- ── 9 OPS / INFRASTRUCTURE ──
  { sec = '9 OPS', id = 'O1', label = 'Tuning live', cmd = 'console: ob_tune ; ob_tune set zombies.maxPerPlayer 30', expect = 'list prints; within a minute more zombies around you; ob_tune reset' },
  { sec = '9 OPS', id = 'O2', label = 'Schedules re-read', cmd = 'ob_tune set director.everyMin 1 ; ob_tune set director.everyMax 2 ; server stats', expect = 'schedules line shows director 1-2 min; a pass fires within ~3 min (logs kind:director)' },
  { sec = '9 OPS', id = 'O3', label = 'Admin suite', cmd = '/time set 23 ; /weather set THUNDER ; /spawn mob runner 3 ; /trigger encounter rumor_food ; /settle morale 10 ; /loot reset', expect = 'each acts and answers in chat' },
  { sec = '9 OPS', id = 'O4', label = 'Logs', cmd = 'console: logs ; logs kind:admin ; event log', expect = 'today\'s lines, format date | src:name:cid | kind | json' },
  { sec = '9 OPS', id = 'O5', label = 'Server stats', cmd = 'server stats', expect = 'players, uptime, memory, loop avg/worst lateness, schedules' },
  { sec = '9 OPS', id = 'O6', label = 'Restart warning', cmd = 'console: restart_warn 5', expect = 'banner + notify + radio static line; logs kind:ops' },
  { sec = '9 OPS', id = 'O7', label = 'Mute', cmd = '/mute <friend id> 1 test ; they type in chat and key the radio', expect = 'chat refused, radio silent, unmuted after a minute' },
  { sec = '9 OPS', id = 'O8', label = 'Kick / ban / unban', cmd = '/ban <friend id> 1 test ; they reconnect ; /unban <name>', expect = 'dropped with the reason; refused for a minute; then in' },
  { sec = '9 OPS', id = 'O9', label = 'Hotfix reload', cmd = '/hotfix reload outbreak_minigames', expect = 'that resource restarts; you keep playing' },
  { sec = '9 OPS', id = 'O10', label = 'Restore preview (offline)', cmd = 'PowerShell: ops\\restore-backup.ps1 then -Date <today>', expect = 'lists backups; preview names what would move aside' },
  -- ── 10 AUTHORITY (Q1 / Q2) ──
  { sec = '10 AUTHORITY', id = 'A1', label = 'Pin sweep still works (token round-trip)', cmd = 'force a padlocked crate / a locked house', expect = 'minigame plays; on win the stash opens as before; F8 clean' },
  { sec = '10 AUTHORITY', id = 'A2', label = 'Forged result does nothing', cmd = 'F8: TriggerServerEvent("outbreak:wi:forced", <crate id>)  (find the id with Look closer / ob_state)', expect = 'nothing opens; with ob_debug 1 the console prints an [OB-AUTH] refusal' },
  { sec = '10 AUTHORITY', id = 'A3', label = 'Zombie wound still lands (witness)', cmd = 'get scratched by a zombie', expect = 'Scratch/Bite lands as before. If it does NOT, tell me: weaponDamageEvent may be silent for NPC melee and the health witness must carry it' },
  { sec = '10 AUTHORITY', id = 'A4', label = 'Forged wound refused', cmd = 'F8: TriggerServerEvent("outbreak:server:wound", "head", "gunshot") while untouched', expect = 'no wound; logs kind:needs.woundRejected has a line' },
  { sec = '10 AUTHORITY', id = 'A5', label = 'Fists are bruises whatever is claimed', cmd = 'friend punches you', expect = 'bruise, never a laceration' },
  { sec = '10 AUTHORITY', id = 'A6', label = 'Battery / parts are skill checks', cmd = 'dead-battery car, Install battery', expect = 'pry minigame first (unless mechanics >= 5), then the swap' },
  { sec = '10 AUTHORITY', id = 'A7', label = 'Strip a car', cmd = 'unclaimed running car -> Pull the battery / Strip engine parts', expect = 'check, then the item in pockets and the car dead / part missing' },
  { sec = '10 AUTHORITY', id = 'A8', label = 'Too fast is refused', cmd = 'ask a friend to spam-win a minigame with a macro (or set pins very high and win instantly)', expect = 'refused; logs kind:minigame.reject shows "too fast"' },
  -- ── 6 PRIOR SHEET ──
  { sec = '6 PRIOR SHEET', id = 'P1', label = 'Walkie: screen, channel keys, prop + anim, hiss', cmd = 'N; ] and [; CapsLock', expect = 'radio screen; channel steps; radio in hand while talking; hiss at range' },
  { sec = '6 PRIOR SHEET', id = 'P2', label = 'Admin: noclip / god / spectate / entity gun', cmd = 'F10 -> Admin', expect = 'each works and turns off cleanly' },
  { sec = '6 PRIOR SHEET', id = 'P3', label = 'Vehicle era + keys', cmd = 'F10 -> Vehicle kit -> World era; Spawn; Give me the key', expect = 'era switches; spawns carry a key; Give me the key unlocks and fixes the car you aim at' },
  { sec = '6 PRIOR SHEET', id = 'P4', label = 'Settlement ledger + cooking', cmd = 'claim a house, Door -> Settlement', expect = 'stock bars, residents, cook' },
  { sec = '6 PRIOR SHEET', id = 'P5', label = 'Sleep, tap, rain catcher', cmd = 'Door -> Sleep; Fill from the tap; place a rain catcher in RAIN', expect = 'per TEST-CHECKLIST 9b' },
  { sec = '6 PRIOR SHEET', id = 'P6', label = 'The Tide', cmd = 'wait ~90 s after joining', expect = 'radio line + red radius; HUD THE TIDE inside it' },
  { sec = '6 PRIOR SHEET', id = 'P7', label = 'Sneak: eye + suspicion + distraction', cmd = 'crouch near a zombie at night; throw a can', expect = 'HIDDEN/NOTICED/SEEN; zombies walk to the can' },
  { sec = '6 PRIOR SHEET', id = 'P8', label = 'Quiet kill', cmd = 'knife, stealth, behind an unseen zombie, E', expect = '[E] quiet kill prompt, takedown, no ripple' },
  -- ── 7 LEGACY SMOKE (still valid) ──
  { sec = '7 Legacy', id = 'A1', label = 'Anim dictionaries', cmd = '/ob_animcheck', expect = '0 missing' },
  { sec = '7 Legacy', id = 'A2', label = 'Prop models', cmd = '/ob_models prop_tool_bench02,prop_barrel_02a', expect = 'all ok (tell me any INVALID)' },
  { sec = '7 Legacy', id = 'C1', label = 'Creator opens on first join', cmd = 'new character', expect = 'illenium creator (known broken: see SHAKEDOWN-NOTES Deferred)' },
  { sec = '7 Legacy', id = 'H2', label = 'Search spots + picked-clean', cmd = 'search a dumpster twice', expect = 'loot then refusal' },
  { sec = '7 Legacy', id = 'H4', label = 'Claim -> key; storage needs key', cmd = 'claim, drop key', expect = 'refused w/o key' },
  { sec = '7 Legacy', id = 'M2', label = 'Crate storage + padlock + force', cmd = 'place crate', expect = 'stash; pin sweep' },
  { sec = '7 Legacy', id = 'D1', label = 'Unconscious wakes at 2 min', cmd = '/ob_down', expect = 'veil, wake' },
  { sec = '7 Legacy', id = 'D2', label = 'Incapacitated; self-splint', cmd = 'get shot; E', expect = 'red veil' },
  { sec = '7 Legacy', id = 'D5', label = 'Permadeath: epitaph, /fallen, corpse', cmd = 'let critical expire', expect = 'all three' },
  { sec = '7 Legacy', id = 'R2', label = 'Radio channel filter', cmd = '/ob_radio 9 test on channel 4', expect = 'NOT received' },
  { sec = '7 Legacy', id = 'G1', label = 'Controller: Up inv, Down wheel, Left radio, B cancel', cmd = 'pad', expect = 'all four' },
}

local function push(action) SendNUIMessage({ action = action, steps = Steps, sel = sel - 1, mouse = mouse }) end
local function setMouse(on)
  mouse = on and true or false
  SetNuiFocus(mouse, mouse); if mouse then SetNuiFocusKeepInput(false) end
  push('update')
end
local function toggle()
  if not GlobalState.obDebug then lib.notify({ title = 'Test menu is debug-only.', description = 'setr ob_debug 1', type = 'inform' }) return end
  open = not open
  if open then push('open'); setMouse(false) else setMouse(false); SendNUIMessage({ action = 'close' }) end
end
local function mark(status, note, idx)
  if idx then sel = idx end
  local s = Steps[sel]; if not s then return end
  s.status = status; if note and note ~= '' then s.note = note end
  push('update')
  TriggerServerEvent('outbreak:shakedown:mark', s.id, s.label, status, s.note or '', s.sec)
  PlaySoundFrontend(-1, status == 'pass' and 'CHECKPOINT_PERFECT' or 'CHECKPOINT_MISSED', 'HUD_MINI_GAME_SOUNDSET', true)
  if sel < #Steps then sel = sel + 1; push('update') end
end
local function askNote(idx)
  if idx then sel = idx end
  local s = Steps[sel]; if not s then return end
  local i = lib.inputDialog('Note for ' .. s.id, { { type = 'textarea', label = 'What happened / the console line', required = true } })
  if i then s.note = i[1]; push('update'); TriggerServerEvent('outbreak:shakedown:mark', s.id, s.label, s.status or 'note', i[1], s.sec) end
end
-- passive mode: keys polled while open. M flips to mouse mode (buttons), Esc / M flips back.
CreateThread(function()
  while true do
    Wait(0)
    if not open then Wait(300) goto continue end
    if IsControlJustPressed(0, 244) or IsDisabledControlJustPressed(0, 244) then setMouse(not mouse) end   -- M
    if mouse then goto continue end
    if IsControlJustPressed(0, 172) then sel = math.max(1, sel - 1); push('update') end        -- up arrow
    if IsControlJustPressed(0, 173) then sel = math.min(#Steps, sel + 1); push('update') end   -- down arrow
    if IsControlJustPressed(0, 199) then mark('pass') end                                      -- P
    if IsControlJustPressed(0, 49) then mark('fail') end                                       -- F
    if IsControlJustPressed(0, 249) then askNote() end                                          -- N
    if IsControlJustPressed(0, 182) then TriggerServerEvent('outbreak:shakedown:export') end   -- L
    ::continue::
  end
end)
RegisterNUICallback('mark', function(d, cb) cb('ok'); if d and d.status and d.index then mark(d.status, nil, d.index + 1) end end)
RegisterNUICallback('select', function(d, cb) cb('ok'); if d and d.index then sel = d.index + 1; push('update') end end)
RegisterNUICallback('note', function(d, cb) cb('ok'); if d and d.index then setMouse(false); askNote(d.index + 1) end end)
RegisterNUICallback('export', function(_, cb) cb('ok'); TriggerServerEvent('outbreak:shakedown:export') end)
RegisterNUICallback('unfocus', function(_, cb) cb('ok'); setMouse(false) end)
RegisterCommand('shakedown', toggle, false)
RegisterCommand('pass', function(_, a) if a[1] then for i, s in ipairs(Steps) do if s.id == a[1]:upper() then sel = i end end end; mark('pass', table.concat(a, ' ', 2)) end, false)
RegisterCommand('fail', function(_, a) if a[1] then for i, s in ipairs(Steps) do if s.id == a[1]:upper() then sel = i end end end; mark('fail', table.concat(a, ' ', 2)) end, false)
exports('steps', function() return Steps end)
-- client errors: forward the ones we can see (resource script errors surface here on some builds)
AddEventHandler('onClientResourceStart', function(res) if res:find('^outbreak_') then TriggerServerEvent('outbreak:shakedown:event', 'client-start', res) end end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then SetNuiFocus(false, false) end end)
