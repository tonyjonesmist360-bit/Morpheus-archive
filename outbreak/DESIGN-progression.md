# Progression backbone — outbreak_intel + outbreak_opportunities

Status: **DESIGN + FIVE implemented chains (camp horde defense; Route 14 bus on vehicles v2; Chiliad repeater on the radio range model; the buried cache on outbreak_weapons; the island on boats in vehicles v2 + Cayo Perico). Untested.**

## 1. File / resource structure

```
resources/[outbreak_progression]/            ← held; ensure only after review
  outbreak_intel/
    fxmanifest.lua
    shared/config.lua                       -- states, categories, presentation rules
    data/intel.lua                          -- STATIC CATALOG of every intel record (id → definition)
    server/intel.lua                        -- per-character intel store, discovery API, validation
    server/sources.lua                      -- discovery sources: document items, radio, arrival, NPC, environment
    client/intel.lua                        -- presentation (area blips, exact blips, landmark text), arrival reports
    client/journal.lua                      -- journal open/close, NUI bridge, pad navigation relay
    html/journal.html                       -- Field Journal NUI (Rumors / Confirmed / Active / Completed)
  outbreak_opportunities/
    fxmanifest.lua
    shared/config.lua                       -- opportunity states, stage rules
    server/registry.lua                     -- registerOpportunity(def), state machine, persistence, log
    server/entities/camps.lua               -- minimal survivor-camp world entity (stats, DB). Future home of the camp system.
    server/chains/camp_defense.lua          -- IMPLEMENTED: Grapeseed camp horde defense
    server/chains/armored_bus.lua           -- IMPLEMENTED: Route 14 bus (consumer of outbreak_vehicles v2)
    server/chains/weapons_cache.lua         -- IMPLEMENTED: the buried cache (consumer of outbreak_weapons)
    server/chains/repeater.lua              -- IMPLEMENTED: Chiliad repeater (consumer of outbreak_radio range model)
    server/chains/island.lua                -- IMPLEMENTED: the island (Cayo Perico via SetIslandHopperEnabled; boats; enclave; lighthouse repeater)
    client/opportunities.lua                -- stage-driven client behaviour: delivery targets, wave spawning, decoy point, kill reports
    client/chains/camp_defense.lua          -- client half of the implemented chain
sql/migrations/003_progression.sql
```

Two resources only. Chains are *data + handlers registered into the registry*, not resources.

## 2. Database schema (003_progression.sql)

```sql
outbreak_intel            (citizenid, intel_id, state, reliability, source, discovered_at, updated_at, PRIMARY KEY (citizenid, intel_id))
outbreak_opportunities    (opp_id PK, state, stage, data LONGTEXT, started_at, resolved_at, outcome, cooldown_until BIGINT)
outbreak_opp_participants (opp_id, citizenid, role, contributions LONGTEXT, PRIMARY KEY (opp_id, citizenid))
outbreak_opp_log          (id AI PK, opp_id, event, citizenid, data LONGTEXT, at TIMESTAMP)
outbreak_camps            (camp_id PK, population, food, water, meds, ammo, power, defenses, morale, threat, state, data LONGTEXT)
```
Intel is **per character** (what *you* know). Opportunities and camps are **world state** (shared). Participation joins the two.

## 3. Contracts

### outbreak_intel — server exports
| Export | Signature | Notes |
|---|---|---|
| `discover` | `(src, intelId, reliability, source) → newState` | idempotent, only moves *up*; server validates `source` against the catalog's `sources` list |
| `confirm` | `(src, intelId, source) → bool` | requires catalog allows confirmation from that source |
| `setState` | `(src, intelId, state) → bool` | for `active/completed/failed`; only callable with `source='opportunity'` (opportunities resource) |
| `obsolete` | `(intelId, reason)` | world-level: marks the record obsolete for **everyone** who has it |
| `getIntel` | `(src) → { [intelId] = {state, reliability, source, ...} }` | |
| `hasIntel` | `(src, intelId, minState) → bool` | |
Events out (server→client): `outbreak:intel:update` (src, intelId, record) · `outbreak:intel:journal` (full journal payload on open)
Events in (client→server): `outbreak:intel:arrived` (intelId) — server re-checks distance · `outbreak:intel:openJournal`

### outbreak_intel — client exports
`getIntel()`, `openJournal()`, `closeJournal()`

### outbreak_opportunities — server exports
| Export | Signature |
|---|---|
| `registerOpportunity` | `(def)` — chains call at start; def = { id, title, intel = {...}, stages = {...}, solutions = {...}, onStage, onResolve, solo = {...}, cooldownMinutes, stub } |
| `get` | `(oppId) → record` |
| `advance` | `(oppId, stage, by, data) → bool` (validated against def.stages order) |
| `resolve` | `(oppId, outcome, data)` |
| `fail` | `(oppId, reason)` |
| `participants` | `(oppId) → {citizenid → role}` |
| `contribute` | `(oppId, src, key, amount) → total` |
| `getCamp` / `modifyCamp` | `(campId) → stats` / `(campId, deltas, reason)` (entities/camps.lua) |
Events out: `outbreak:opp:state` (-1, oppId, record) · `outbreak:opp:stage` (-1, oppId, stage, data) · `outbreak:opp:wave` (src, oppId, wave)
Events in (validated): `outbreak:opp:join`, `outbreak:opp:deliver(oppId, item)`, `outbreak:opp:decoyPing(oppId, noise)`, `outbreak:opp:waveReport(oppId, wave, kills)`, `outbreak:opp:choose(oppId, solutionId)`

### Integrations — all soft (pcall'd exports / events), none are `dependencies`
| Need | How |
|---|---|
| inventory | `exports.ox_inventory` (server RemoveItem/AddItem/GetItemCount) |
| radio | `exports.outbreak_radio:transmit(ch, title, text, target)` |
| zombies | client `exports.outbreak_core:spawnZombieAt/countZombies/nearestZombie`; server `exports.outbreak_core:fireEvent` |
| noise | client `exports.outbreak_noise:getNoise()`; `outbreak:noise:spike` |
| factions | `exports.outbreak_faction:addRep/getRep` |
| injuries | reads `Player(src).state.downState`; `exports.outbreak_needs:getWounds` |
| housing | `exports.outbreak_housing` (future: camp safehouse). Not used by chain 1 |
| vehicles | `Entity(veh).state` (extended; bus chain, stub) |
| world | `GlobalState.obTime/obWeather` |
| emotes | `exports.outbreak_emotes:action` |
| skills | `exports.outbreak_skills:grantXP/getLevel` |

Hard `dependencies` in manifests: `ox_lib`, `oxmysql`, `outbreak_core` (tick bus), `outbreak_intel` ← `outbreak_opportunities`.

## 4. State transition rules

### Intel (per character)
```
undiscovered ─→ rumor ─→ partial ─→ confirmed ─→ active ─→ completed
      │           │         │           │           └─→ failed
      └───────────┴─────────┴───────────┴──────────────→ obsolete   (world-level, any time)
```
- Only upward moves; a `discover` at a lower level than current is a no-op.
- `partial` = you know *where roughly* or *what* but not both. `confirmed` = exact coordinates in hand OR server-verified arrival within `def.area.radius` OR a catalog-listed confirming source.
- `active`/`completed`/`failed` are set **only** by outbreak_opportunities when the linked opportunity starts/resolves for participants (non-participants keep `confirmed`).
- `obsolete` is world-level (`obsolete(intelId)`), e.g. a camp that no longer exists. Obsolete intel stays in the journal, greyed, in Completed Discoveries.
- Reliability is orthogonal: `rumor | credible | confirmed`. Rumor-reliability intel may be a trap; the catalog flags `trap = true` and the presentation never reveals it.

### Presentation rules (no free GPS)
| Intel has | Player sees |
|---|---|
| `coords` (exact) | a blip |
| `area = {center, radius}` | a translucent radius blip, no centre marker |
| `landmark` text | journal text only |
| `frequency` | journal text; tuning to it is the discovery |
| `photo` | journal image panel (bundled asset key) |
| `clue` | journal text |

### Opportunity (world)
```
dormant ─→ available ─→ active ─→ stage 1..n ─→ resolved(outcome)
                           │                └─→ failed(reason)
                           └─→ expired  (window passed, nobody engaged)   → cooldown → dormant/obsolete
```
- `available` when the def's `intel.trigger` is `confirmed` for ≥1 character.
- `active` on first `join` (or automatic for time-boxed events like a horde warning).
- Stages advance only in the def's declared order; `advance` from a wrong stage is rejected and logged.
- Every resolution writes `outcome` + consequences via the def's `onResolve` and marks participants' intel `completed/failed`.

## 5. Persistence & restart
- Intel store: in-memory per online player, loaded on `PlayerLoaded`, saved on every transition (write-through) — no timer.
- Opportunities: registry writes `state/stage/data` on every transition (write-through). On resource start, every registered def restores its record; `active` records call `def.onRestore(record)` so a chain can resume (camp defense resumes with remaining timer computed from `data.deadline` epoch, not from a timer object).
- Camps: write-through on `modifyCamp`.
- Log table is append-only (audit + future journal narration).
- Client rebuilds blips/zones from the journal payload on join and on every `outbreak:intel:update`.
- Nothing that matters lives only in a `SetTimeout`. Timers are epochs in `data`.

## 6. Anti-exploit / server validation
| Surface | Rule |
|---|---|
| Discovery via items | the document item is removed server-side on use; intelId comes from item metadata set at loot time by the server |
| Discovery via arrival | client sends `arrived(intelId)`; server recomputes distance from `GetEntityCoords(GetPlayerPed(src))` to `def.area.center` |
| Discovery via radio | server-originated only (`transmit` handler calls `discover`); client cannot claim a transmission |
| Deliveries | `RemoveItem` server-side; player must be within `def.deliveryRadius` of the camp; per-item caps per stage |
| Kill reports | client-reported (only clients see ped deaths). Capped at `wave.size` per wave *per opportunity* (not per player), rate-limited, and cross-checked: total accepted ≤ spawned. Documented trust gap #4 |
| Decoy/lure | server checks the player is inside the decoy point for `lure.seconds` via repeated pings ≤ 1/s with `noise ≥ threshold`; noise value is client-reported → trust gap; mitigated by requiring the horde count near camp (reported by the *camp-side* client) to drop |
| Stage advance | only the server's own chain handlers call `advance`; the client can only `join`, `deliver`, `choose`, `decoyPing`, `waveReport` |
| Rewards / rep / camp stats | server only |
| Intel state `active/completed/failed` | only `source='opportunity'` |
| Journal | read-only view of server payload |

## 7e. Testing checklist (boats + chain 5)
- [ ] S1 Three marina wrecks exist on start (Chumash, LS marina, Paleto); each rolls locked/dead/fuel/part like a car; class 14 marks `boat`
- [ ] S2 A gas can refuses a boat; a marine can refuses a car; siphoning a boat needs a marine can
- [ ] S3 Boat at speed in THUNDER: warning + fuel burn doubled (server)
- [ ] I1 With the Chiliad relay lit, tune 16 → `island_maritime` rumor (frequency intel, no marker); harbourmaster's desk at Chumash → charts document → read → area (600 m, no centre) + `marine_chart` item; arrival at the marina → confirmed → opportunity available
- [ ] I2 Join → stage 3; get the dinghy running with ≥ 60% marine fuel; "Set out on the bearing" refuses in THUNDER/RAIN/FOGGY, refuses without charts/fuel; in CLEAR → stage 4, Cayo Perico streams in, lighthouse blip
- [ ] I3 Cross (~7 km); step off the boat on the beach or far dock → `island_landing` discovered, stage 5, THE LIGHT transmits; 10% the raider net mentions the boat
- [ ] I4 Enclave of six at the beach camp; journal: **negotiate** (costs 2 antibiotics + 4 bandages, enclave rep +10) / **force** (they fight; enclave −20, civilian −8) / **quiet** (24 h later THE LIGHT warns you) → the Far Dock becomes claimable → stage 6
- [ ] I5 Lighthouse: coil + battery → `cayo` repeater active (14 km): island ↔ mainland radio works; resolved; radio line to everyone
- [ ] I6 Night on the island: washed-up infected on the beach every 10 min; restart → island state, dock claim, repeater persist

## 7d. Testing checklist (weapons + chain 3)
- [ ] W1 `data/weapons_snippet.lua` merged: pistol shows condition in ox tooltip; condition drops per magazine; melee drops per hit and breaks at 0
- [ ] W2 `/condition` reads the held weapon; `gun_oil` +25, `weapon_kit` → 100 (server-set durability)
- [ ] W3 At <30% a pistol jams sometimes: attack disabled, "JAMMED — E", clear anim 2.5 s
- [ ] W4 Noise ripple: knife swing ~15, pistol 92, suppressed pistol 45, shotgun 100 (catalog-driven, not flat)
- [ ] W5 Signal pistol: red flare → noise 100, radio line to everyone in 2.5 km (garbled by range), horde of 8 on the shooter
- [ ] W6 Ammo scarcity: houses give pistol rounds rarely, tool chests shotgun rarer, rifle rounds only from convoys/camps/cache
- [ ] W7 Carrying a legendary doubles raider ambush rolls (debug print in raiders director)
- [ ] K1 `/ob_opp pages weapons_cache` → three documents; read 1 and 2 (partial, journal clues), read 3 (exact coords, blip). Reading 3 without 1–2: "a page is missing", opportunity not startable
- [ ] K2 Join → footlocker stash seeded (one random legendary + its ammo + oil + dog tags); patrol of 2 marines walks the road near the pylon
- [ ] K3 Dig at the pylon → stage 3; noise > 55 within 80 m makes the patrol walk toward you
- [ ] K4 Choose **dig**, pry (4 pins) → stash opens → resolved `dug`; a miss spikes noise 75
- [ ] K5 Alt: choose **military** before opening → rep +15, cut items, weapon appears in the Zancudo armory stash, pages obsolete, resolved `military`

## 7c. Testing checklist (radio range + chain 4)
- [ ] R1 Two players on channel 5, 200 m apart: clear. 1.2 km apart: audible but quiet (volume override). 2 km: static notify, no voice
- [ ] R2 Same test in THUNDER: quality drops ~0.3; standing on a hill helps
- [ ] R3 `Player.state.radioReach` on each client shows the other's server id → quality
- [ ] R4 Place `radio_base` inside a claimed house → from within 30 m of it you reach 6 km
- [ ] R5 Zancudo mast (active by default) only helps two *military*-job players inside 2.5 km of it
- [ ] R6 `/ob_radio 0 test` still arrives everywhere (no origin); a chain transmission with an origin arrives garbled at long range, missing beyond the floor
- [ ] C1 Walk to the Chiliad summit tower → `repeater_tower` confirmed (discovery), blip grey "(dead)"
- [ ] C2 Sign on at the tower; `/ob_opp kit repeater`; fit 2 batteries + coil → stage 3; journal offers "Boot it now" / "Boot it in daylight" (daylight refused at night; must be at the tower)
- [ ] C3 Boot: horde 20 (or 10 by day); tower blip; zombies hugging the tower ≥ 30 s cumulative → BOOT FAILED, coil consumed, back to stage 2
- [ ] C4 Hold 3 minutes → RELAY ONLINE: blip green, `GlobalState.obRepeaters.chiliad.active`, rep +8, relay transmission; restart → still active
- [ ] C5 With the relay active, R1's 2 km test inside the 9 km Chiliad circle is now clear
- [ ] C6 Within 12–25 min of the relay going live, players tuned to channel 16 get the `island_maritime` rumor (journal Rumors: frequency 16, no marker)

## 7b. Testing checklist (vehicles v2 + chain 2)
- [ ] V1 Walk near any parked car → within 2 s its statebag `veh` appears; locked/dead/fuel rolled; same car same roll after `restart outbreak_vehicles`
- [ ] V2 Pry (crowbar) → unlock; ~15% of cars hand you a `vehicle_key` from the glovebox
- [ ] V3 Driver seat: reasons cycle (battery → part → fuel → splice); splice → `hotwired`
- [ ] V4 Drive 2 min → fuel drops in the statebag (server burn); idle burns ~25% as fast; a bus burns ~2.4x a compact
- [ ] V5 Siphon into a can → can metadata rises, vehicle fuel falls; use the can next to another car → transfers
- [ ] V6 Hotwired + `key_blank` → "Cut a key" → `claimed`; lock/unlock with the key; `restart` server → the car is where you left it, with your fuel
- [ ] V7 Noise: same speed, a bus/military truck reads louder on the ripple than a compact
- [ ] B1 `/ob_opp part armored_bus` gives both documents + an alternator; read the photo (partial), read the manifest (area blip, no centre); drive into the area → confirmed → journal shows the opportunity available
- [ ] B2 Join at the journal → the bus exists at the depot (locked, dead, dry, missing part); stage 2
- [ ] B3 Fit the alternator → stage 3 auto-advances within 10 s; battery + fuel + splice → stage 4
- [ ] B4 Cut a key, park within 40 m of a claimed safehouse → resolved `restored`, rep, radio line; restart → bus still there
- [ ] B5 Alt: choose **Trade** before stage 4 → bus becomes raider property, Boneyard cache opens, civilian rep −4, manifest intel obsolete
- [ ] B6 Alternator also from the Quartermaster (3 engine parts) and seeded into the Quarry cache when cleared

## 7. Testing checklist (chain 1)
- [ ] I1 Tune to ch 4 after boot → within 5 min "Grapeseed" rumor arrives → journal Rumors shows it with a **radius blip east of Grapeseed, no centre**
- [ ] I2 Drive into the radius → arrival → journal moves it to Confirmed Locations; camp blip appears; camp NPCs present
- [ ] I3 `restart outbreak_intel` → journal identical
- [ ] O1 With ≥1 confirmed, the warning transmission arrives on ch 4 (`/ob_opp warn camp_defense_grapeseed` to force) → Active Opportunities shows the countdown
- [ ] O2 Deliver 4 planks + 2 nails at the camp gate → camp `defenses` rises; barricade props appear; participants recorded
- [ ] O3 Deliver 1 gas can → `power` rises → floodlights (blackout exception) at the camp
- [ ] O4 Timer hits 0 → waves spawn from the south entry; NPC guards fight; kill reports accepted ≤ wave size
- [ ] O5 Clean outcome: camp stats up, rep +15, radio announces, intel `completed`, journal Completed Discoveries
- [ ] O6 Solo: choose **Lure** → decoy point blip 250 m south → whistle/horn there ≥ 30 s → horde redirects → outcome `lured`, rep +10
- [ ] O7 Choose **Evacuate** → camp state `abandoned`, rep +5, intel `obsolete` for everyone
- [ ] O8 Ignore it entirely → `expired` → camp `overrun` (population 0, state overrun), rep −10 for anyone who had it confirmed, intel `obsolete`
- [ ] O9 `restart outbreak_opportunities` mid-preparation → countdown continues from the epoch, contributions intact
- [ ] O10 Stub chains appear in the journal as "Unavailable — not built" and `/ob_opp start armored_bus` is refused with a logged reason
- [ ] J1 Journal: J opens; arrows/Tab/Enter/Esc navigate; on pad, D-pad + A/B navigate via the Lua relay; four tabs render; empty states render
