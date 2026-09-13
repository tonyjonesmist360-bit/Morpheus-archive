# OUTBREAK PACK — v0.9-slice

> **Status: vertical slice, UNTESTED on FXServer.** Read in this order:
> `ARCHITECTURE.md` → `MANIFEST.md` → `INSTALL-WALKTHROUGH.md` → `server.cfg.additions` →
> **`SMOKE-SCRIPT.md` (first evening, top to bottom)** → `FIRST_BOOT_CHECKLIST.md` → `INTEGRATION_REPORT.md` → `KNOWN_LIMITATIONS.md` → `CONFIG.md` → `KEYBINDS.md` → `ops/OPS.md`
>
> `resources/[outbreak]` = the slice (17 resources + debug). `resources/[outbreak_extended]` = HELD; do not ensure
> until the checklist passes. SQL lives in `sql/migrations/`.

## Appendix: feature notes from the build log (pre-cohesion pass; superseded where they conflict with ARCHITECTURE.md)

End-of-world RP server pack that doubles as a single-player survival game.
Built for **QBox (qbx_core)** or **QBCore** with the **ox** stack.

## What's in the box

| Resource | What it does |
|---|---|
| `outbreak_core` | **Variants**: shamblers (70%), *runners* after dark (fast, night only), *bloaters* (slow, tanky, burst into an infectious cloud on death — noise 60), *screamers* (one shriek calls a mini-horde and pegs the noise meter). **Weather with teeth**: rain masks your noise 40%, thunder masks more but frenzies them every 90s, fog thickens spawns 50%. Ambient population replaced with zombies. Shamble walk, sight/sound aggro, gunfire attracts, night surges, timed horde events, infection roll on every hit. Police dispatch fully disabled. |
| `outbreak_needs` | Hunger / thirst / fatigue decay (sprinting burns faster), bleeding, staged infection (Anxious → Queasy → Fever → Critical). Antibiotics buy time; a bite is still a death sentence. Saves per character to MySQL. |
| `outbreak_hud` | Minimal NUI HUD: four thin vitals bars bottom-left, Zomboid-style moodle column on the right edge (Hungry / Thirsty / Exhausted / Bleeding / infection stage). |
| `outbreak_items` | Starter item set (canned food + opener, murky vs purified water, MREs, bandages vs ripped sheets, antibiotics, planks/nails/hammer, radios). Searchable world props — dumpsters, vending machines, tool chests, med stations — with loot tables and 30-min respawn. |
| `outbreak_housing` | **Rebuilt v2 — no apps, no money.** A claim puts a physical *safehouse key* item in your pocket; owners cut spare keys and hand them to friends. Keys open the stash, the door, and the barricade menu. Eight houses: shacks are door-and-stash; the big ones (Grove St, Sandy trailer, Rockford mansion, Murrieta Heights, Eclipse Towers) teleport into real GTA interiors via bob74_ipl. Barricades now render as plank props. Dead owners' houses go back on the market. Claimable safehouses with ox_inventory stashes, 3-level barricading (costs planks + nails + hammer), and a **30% "occupied" roll** on first visit — hostile squatters inside. |
| `outbreak_radio` | Phones blocked. Handheld radio item (needs a battery) tunes pma-voice channels 1–99. Horde events push static warnings to anyone tuned in. |
| `outbreak_down` | **Permadeath** (config `DeathMode`: permadeath / losegear / keep). Bleed out and: everything you carried becomes a body-bag stash where you fell (24h, everyone can loot it), your name and days-survived go on the memorial wall (`/fallen`), the whole server hears it on the radio, your safehouse claims release, and you get *THIS IS HOW YOU DIED* before being sent back to make a new survivor. Dead characters cannot be reloaded. **PvP on**: search a downed player's pockets. Two-stage downed system. **Unconscious** (melee, fists, zombie swipes): black tunnel-vision veil, you wake in 2 min at 35% health, or a friend shakes you awake — but a second KO within 5 min escalates. **Incapacitated** (bullets, explosions, wrecks): red pulsing veil, 10-min bleed-out, a friend stabilizes with a bandage, or press E to self-splint (costs a splint — the solo-play lifeline). Bleed out and you respawn "dragged somewhere" at one of three triage points. Downed state syncs via statebags so every other script can react to it. |
| `outbreak_raiders` | The chase faction. While you're driving, the director rolls ambushes — raider trucks appear behind you and **PIT, ram, and box you in** (they carry only melee weapons; they will not shoot). Once your car is crawling they bail out swinging. Knock you out and they spend 8 seconds going through your pockets: up to 4 slots, food/meds/fuel first, but they always leave your radio. Then they drive off and leave you alive. Escape by distance, by outlasting them (4 min), or by fighting back. 15-min cooldown per player. |
| `outbreak_spawn` | Apocalypse spawn flow — replaces apartments/multichar spawn selectors. Fresh survivors wake at one of five story spots ("You wake on a motel floor in Sandy Shores...") with a starter kit: 2 ripped sheets, murky water, a marked map scrap. Cash and bank wiped to zero — barter economy only. Returning characters load where they logged out. |
| `outbreak_vehicles` | Vehicle survival. Every parked car rolls its state **deterministically** (same wreck for every player, every visit): 55% locked (pry with a crowbar — loud), 40% dead battery, 2–35% fuel. Siphon with a hose into a gas can (fuel stored as item metadata), swap batteries, repair engines with parts. Fuel burns while driving. Idle near zombies and they smash the window — 50% they drag you straight out of the seat. A running truck becomes a prized possession. |
| `outbreak_noise` | The Zomboid heart: one 0–100 noise meter. Crouching ~4, walking 14, sprinting 42, engines 25–65 by speed, horn 80, suppressed shot 45, unsuppressed 92, prying doors spikes it. Zombie senses scale from **half range when silent to 2.5× when loud**. HUD shows a ripple indicator above your vitals. Other scripts feed it via the `outbreak:noise:spike` event. |
| `outbreak_minigames` | NoPixel-style skill checks, three original games exported for any script to call. **Pin sweep** (locks): a marker orbits a lock face, tap E in the notch — each pin the notch shrinks and speeds up. **Pry meter** (crowbars): land E in a drifting sweet spot, 3 pulls, 2 misses jams it. **Wire splice** (hotwiring): memorize the wire order, key it back 1–4. Wired in: prying car doors plays pry, keyless cars need a splice to start (once per vehicle), and forcing a stranger's safehouse plays pin sweep — **their barricade level adds pins**. Failing is loud: every miss spikes the noise meter. |
| `outbreak_world` | The grid is down. Server-synced clock — one in-game day per real hour — rolling weather fronts, and a **blackout**: no streetlights, no building glow, headlights still work. Night with a dead grid changes everything. |
| `outbreak_craft` | Field crafting on K (or /craft): 2 ripped sheets → bandage, plank + sheet → splint, scrap + tape (+hammer, not consumed) → engine parts. |
| `outbreak_faction` | **Police converted to Military.** Two player factions defined for qbx_core (paste `data/jobs_snippet.lua` over the police job): *Military Remnant* (5 ranks; friendly to checkpoint soldiers, private radio channel 7, seeded armory stash at Fort Zancudo, fatigues via illenium-appearance outfit) and *Raider* (3 ranks; shot on sight at checkpoints, channel 13, cache at the Sandy boneyard). Assign with `/setfaction <id> military 2`. |
| `outbreak_stations` | Gas stations after the fall. Ten stations, each rolled deterministically: 55% dry, 30% trickle (8–22% per pull, then 6 hours dry), 15% dead pump — wire a car battery with a splice minigame to bring it back to trickle. Searchable shop shelves with station loot. Siphoning stays king. |
| `outbreak_emotes` | Survival emotes that *do* things, layered over `scully_emotemenu`'s full RP library: **rest** (fatigue recovers 3x, you are very killable), **listen** (kneel 4s → how many are near and which way), **whistle** (noise 70 — pull them off a friend or onto one), mourn, hands up, kneel, guard, scout, weld (loud), and more. F3 / D-pad Down. |
| `outbreak_binds` | Every keyboard *and* controller bind in one file; see `KEYBINDS.md`. Reclaims the dead phone/radio-station buttons on the pad. |
| `outbreak_broadcast` | **Radio as storytelling.** Channel 1 loops the Emergency Broadcast System (it cuts off mid-sentence). Channel 9 is a numbers station reading grid digits to a supply cache — 30% of the time it's raider bait. Distress calls hit random channels naming a real street: a pinned survivor with a horde on them and a reward, or a trap. Tune in or miss it. |
| `outbreak_camps` | Three **raider camps** — the chase crews' home bases, garrisoned loot-fortresses whose guards *do* shoot. Clear the perimeter, pry the cache, come back in 45 minutes and it's regarrisoned. Plus **military convoys** rolling Zancudo↔Sandy every 30–60 min: shadow it, ambush it, kill the driver, pick the truck's lock, and listen to channel 7 light up. |
| `outbreak_identity` | **Every survivor is a person.** Fresh characters run illenium-appearance's full creator (face, body, hair, clothes), then answer *WHO WERE YOU*: a callsign, a former life (nurse, mechanic, burglar, nobody special...), a one-line description others see with `/look`, two strengths and one flaw from a Zomboid-style trait list (Thick Skinned, Light Eater, Graceful, Clumsy, Weak Stomach, Fast Learner...). `/me` draws emote text over your head. Wardrobes inside every interior — free, no shops. `/outfitcheck` cycles clothing to hunt clipping during the shakedown; see `data/illenium_config_notes.md`. |
| `outbreak_map` | World dressing: sandbags and barriers at every checkpoint, wreck clusters and work barriers on the highways out of the city, quarantine signage. Kills trains, ambient planes, boats, garbage trucks. **`/scuff <note>`** logs your coordinates and a note to the DB and console — the crew tags map problems in-game, `/scufflist` prints the punch list. |
| `outbreak_skills` | Zomboid skills that grow with use: **mechanics** (repairs, batteries, hotwires → faster repairs), **medicine** (bandaging, splinting, stabilizing → faster, stronger), **stealth** (sneaking near the dead → quieter feet), **fitness** (sprinting), **scavenging** (searching → better loot odds). Traits set starting levels and XP rates. `/skills`. |
| `outbreak_military` | Three military checkpoints (Zancudo gate, LSIA quarantine, Sandy airfield). Soldiers guard, fight zombies, and open fire if you approach armed. No police anywhere. The **Quartermaster** stands at the Sandy Airfield post — barter-only trades (canned goods → antibiotics, fuel → radio batteries, map intel → purification tabs). No cash, no credit. |

## Install (your PC, localhost)

1. **FXServer**: grab the latest Windows artifact from the FiveM
   artifacts page, unzip to `C:\FXServer\server`.
2. **License key**: free from keymaster.fivem.net (needed even for LAN).
3. **Database**: install MariaDB (or XAMPP). Create a database `outbreak`.
4. **txAdmin recipe**: run `FXServer.exe`, txAdmin opens in your browser —
   pick the **QBox** recipe (or QBCore). It installs the framework,
   `ox_lib`, `oxmysql`, `ox_inventory` for you.
5. Add these if the recipe didn't include them: `ox_target`, `pma-voice`.
6. Copy this pack's `resources/[outbreak]` folder into your server's
   `resources/` folder.
7. Run `sql/outbreak.sql` against your database (HeidiSQL/phpMyAdmin).
8. Paste `data/ox_items_snippet.lua` contents into
   `ox_inventory/data/items.lua`.
9. Append `server.cfg.additions` to your `server.cfg`.
10. **Phase A conversions** (do once): paste `outbreak_faction/data/jobs_snippet.lua`
    over the `police` entry in `qbx_core/shared/jobs.lua`. Comment out
    `qbx_medical` and `qbx_ambulancejob` (outbreak_down owns death now) and
    `qbx_police` (outbreak_faction owns the military job). Keep `mm_radio` —
    outbreak_radio will hand it the UI and gate it behind batteries.
11. **Disable competing systems**: remove/comment `qbx_spawn` + apartments
    resources (outbreak_spawn replaces them), and disable qb-hud if present
    (outbreak_hud replaces it; the framework's own hunger/thirst is pinned
    to 100 automatically so only outbreak_needs governs survival).
12. Start the server, launch FiveM, press F8 → `connect localhost`.

**Single player:** that's it — you're alone on your own server.
**Friends join:** forward port 30120 (TCP+UDP) or use a VPN like Tailscale/ZeroTier and give them your IP.

## Honest status

This is a **skeleton build** — real logic throughout, but it has never
touched a live FXServer. Expect a shakedown session: native quirks,
event-name mismatches with your exact framework version (QBox uses the
qb-core bridge, which these scripts assume), and coordinates worth
tuning. Marked `TODO`s: headshot-only mode, radio static audio,
warning barks at checkpoints, plank props for barricades, a crouch/rummage
anim on the robbing raider, and a hogtie/carry option for downed players.

## Tuning knobs (all in shared/config.lua files)
- Zombie density, night multiplier, infection chance → `outbreak_core`
- Decay rates, infection timeline, fatal-bite toggle → `outbreak_needs`
- Loot tables & respawn → `outbreak_items`
- Occupied chance, barricade costs, house list → `outbreak_housing`
- Checkpoint locations & aggression → `outbreak_military`
