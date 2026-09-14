# First-boot test checklist — the vertical slice

Preconditions: INSTALL-WALKTHROUGH.md Parts 1–6 done (stock Qbox boots), then:
`001_slice.sql` applied · items snippet pasted · jobs snippet pasted · `server.cfg.additions` appended · competing resources disabled · `setr ob_debug 1` · you are in `group.admin`.

Record PASS / FAIL / NOTES per line. Copy console errors verbatim.

## Boot
- [ ] B1 Server reaches ONLINE with zero `outbreak_*` script errors in the server console (yellow warnings OK)
- [ ] B2 F8 client console: no `outbreak_*` errors on join
- [ ] B3 `ensure` order: no "dependency not found" lines

## 1. Create a survivor
- [ ] C1 illenium creator opens on first join; can pick face, hair, clothes; closing saves
- [ ] C2 "WHO WERE YOU" dialog appears; callsign, former life, 2 strengths + 1 flaw accepted
- [ ] C3 `/skills` shows traits; `handy`/`first_aider` start at level 2
- [ ] C4 relog: no creator, no dialog (identity persisted)

## 2. Spawn scenario
- [ ] S1 Wake at the motel (or `ob_scenario`), story text shows, kit is in inventory
- [ ] S2 Cash and bank are 0
- [ ] S3 HUD: four bars bottom-left, moodle column empty, noise dot visible
- [ ] S4 Time/weather match scenario

## 3. Radio
- [ ] R1 Use `radio_handheld` (needs battery) → channel dialog (or mm_radio) → tuned
- [ ] R2 The scenario transmission arrives ~20 s after spawn (only if tuned, any channel)
- [ ] R3 `/ob_radio 0 test` arrives; `/ob_radio 5 test` arrives only if on channel 5

## 4. Search a property
- [ ] P1 Walk to Sandy Shores Bungalow (`/ob_tp sandy_bungalow`); door target appears
- [ ] P2 Occupant OR story text on first visit
- [ ] P3 "Search the house" → 3 spots → search anim plays → loot or "Nothing useful"
- [ ] P4 Second search of the same spot: "Already picked clean"
- [ ] P5 `restart outbreak_items` → still "Already picked clean" (persisted)

## 5. Noise vs zombies
- [ ] Z1 Zombies exist in the streets; shamble; no police, no traffic
- [ ] Z2 Crouch-walk past one at 15 m: not noticed. Sprint past: chased
- [ ] Z3 Fire a gun: noise ripple goes red, zombies converge
- [ ] Z4 `/ob_zombie 3` spawns three next to you
- [ ] Z5 Wheel (**G**) → Listen reports count and direction  *(there is no `/listen` command — the wheel is the only path)*

## 6. Wounds
- [ ] W1 Get scratched/bitten → "Scratch — left arm" style notify, Bleeding + open-wound moodles
- [ ] W2 G → Treat → pick the wound → treat anim → wound closes, moodle clears, bandage consumed
- [ ] W3 `/ob_wound right_leg fracture` → movement slowed; splint clears it
- [ ] W4 Bite: infection notify sometimes; `Anxious` moodle appears

## 7. Find the kit
- [ ] K1 Dumpster/vending/toolchest/medstation targets exist and search works
- [ ] K2 Eat beans (needs opener), drink water, take antibiotics — anims play, bars move
- [ ] K3 Purify: tabs + dirty → clean

## 8/9. Occupant or story, claim or shelter
- [ ] H1 Claim the bungalow → `safehouse_key` item appears with house metadata
- [ ] H2 Open storage with key; drop key → storage refuses
- [ ] H3 Cut spare key → give to a friend → they can open storage
- [ ] H4 Grove St house: "Shelter inside" works without claim; interior loads; "Leave" returns
- [ ] H5 Barricade with 2 planks + nail + hammer → level 1, planks render at door

## 10. Survive a night + restart
- [ ] N1 `/ob_time 22` → blackout (no streetlights), runners appear
- [ ] N2 Rest emote recovers fatigue (bar rises while resting)
- [ ] N3 `/ob_persist`, note the values → `restart` server → relog → `/ob_state` matches (needs, wounds, infection), key still in inventory, house still owned, barricade level intact, skills intact

## Mutable world (outbreak_worlditems)
- [ ] M1 Wheel → Set something down → pick beans → ghost follows your aim, Q/R rotate, E places → a bottle prop sits where you put it; `restart` server → still there
- [ ] M2 Target it → Take → back in your pockets (with metadata intact, e.g. a half-full gas can)
- [ ] M3 Place a crate → Open → it's a 20-slot stash; padlock it → others see "Padlocked"; Force → pin sweep; miss spikes noise
- [ ] M4 /writenote, place the note on a door → another player targets it → Read shows your text and your name
- [ ] M5 Place a `document` you haven't read → another player reads it → they get the intel, the paper stays
- [ ] M6 Take a wall lantern (curated map prop) → item in pockets, prop gone for everyone, `restart` → still gone; after 48 h it's back
- [ ] M7 Inside a claimed house, a stranger without a key cannot Take your placed items
- [ ] M8 Entropy: a crate left unlocked outside near a road → within 6 h a raider note appears beside it and stock is missing (debug: shorten `checkHours`)
- [ ] M9 Entropy: junk placed inside Silo Farm by a stranger → after 2 h it's in the camp cache and channel 4 complains
- [ ] M10 Walk into a 24/7: shelf sweets/chips/bread/cans show **Grab**; grab one → "Grabbing item..." → ox notifies ADDED ×1, that prop is gone for everyone, `restart` → still gone
- [ ] M11 Shelf goods are edible (chips spike noise 25; stale bread can make you sick); an emptied store stays empty for 36 h (8 h if a camp is near)
- [ ] M12 Force a restock (debug: shorten `ShelfRestock.hours`) while standing in the store → a survivor walks in, kneels at the shelf, the prop is back

## Director menu (outbreak_dm)
- [ ] X1 With `outbreak.dm` ace: F10 (or wheel → DIRECTOR) opens; without it: "Not a director" and no wheel entry
- [ ] X2 Spawn → Horde / Zombies / Survivors with a line (Talk target shows it) / Raiders / Military / Vehicle (managed if vehicles v2 is on) / Cache crate; Clear my spawns removes them
- [ ] X3 Story → Radio transmission with a range garbles for far players; Plant a note is readable by others; Hand a document; Opportunity control; Camp stats; Rep; Repeater toggle
- [ ] X4 World → Time / Weather / Give / Revive / Teleport / Bring / Ghost (invisible + invincible, toggles back)
- [ ] X5 Scenes → "Helicopter crash" at your position: wreck props, MAYDAY, wreckage cache, two dead marines, then a horde 45 s later; "Schedule a scene" fires after N minutes
- [ ] X6 Every action lands in `outbreak_dm_log` with actor + payload

## Downed / death
- [ ] D1 `/ob_down` → unconscious veil + timer; wakes at 2 min
- [ ] D2 Friend: wheel → Shake awake / Carry / Drag / Search pockets
- [ ] D3 Incapacitated timer expires with `DeathMode=permadeath` → **CRITICAL** (black veil, 30-min timer), NOT death
- [ ] D4 Friend: wheel → Carry → near a car → Load into vehicle → drive to Sandy Medical → Unload → station target "Treat a critical patient" (2 bandages + antibiotics) → patient wakes, `recovering` (no sprint, slow) for 2 h
- [ ] D5 Failed station attempt halves the timer, does not kill
- [ ] D6 Solo: `/ob_give adrenaline_shot`, go down, use it while incapacitated → up at 10%; using it while NOT incapacitated is refused
- [ ] D7 Critical timer expires → epitaph → memorial `/fallen` → corpse bag lootable → character cannot reload
- [ ] D8 `/ob_revive <id>` from an admin pulls a glitched player out of any state

## Settlement & World Director (outbreak_supply / outbreak_director) — v0.16.0
- [ ] S1 Door → Settlement on a claimed house: 7 bars, residents 0/4, `/ob_home` opens it too
- [ ] S2 Items in storage move the bars; murky water shows as "unboiled" and does not count
- [ ] S3 Cook → Boil / Stew / Noodles / Meat: inputs + one plank gone from storage, outputs appear, ledger line, pouring anim
- [ ] S4 DM → Settlement +2 residents; with `TickMinutes = 2` a meal disappears per few ticks; HUD `HOME LOW` → `HOME FOOD`
- [ ] S5 DM morale −45: within 3 ticks a dispute / drinking / leaving line; on leaving a readable note prop at the door and residents −1
- [ ] S6 DM → World Director pass with food stocked: stranger walks to the door; Take them in → resident +1; Send away → wanders off
- [ ] S7 Food empty → Director pass → OVERHEARD rumour on the radio naming a real store; `outbreak_director_log` row
- [ ] S8 F1 Home column agrees with the ledger; survives a restart

## Wheel & binds
- [ ] G1 G opens the wheel; contents change with state (wounds, downed neighbor)
- [ ] G2 Controller: D-pad Down = wheel, Up = inventory, Left = radio, B = cancel
- [ ] G3 T hands up, X cancels, ` whistles (noise spikes)
