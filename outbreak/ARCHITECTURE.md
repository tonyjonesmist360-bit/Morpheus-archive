# OUTBREAK — Architecture & Dependency Map

Written *before* the cohesion refactor. This is the contract every resource
is patched to obey. Anything not on this map is a bug.

## Layers

```
[foundation]  qbx_core (qb-core bridge) · ox_lib · oxmysql · ox_inventory · ox_target · pma-voice · illenium-appearance
      │
[services]    outbreak_core ──── zombie population + tick bus + world events
              outbreak_noise ─── world noise (single number)
              outbreak_needs ─── character state (needs, wounds, infection)  ← authoritative store
              outbreak_down ──── injury/downed/death
              outbreak_housing ─ persistent properties
              outbreak_radio ─── radio messages
              outbreak_faction ─ faction reputation
              outbreak_items ─── item definitions + useables + loot
              outbreak_identity  who you are (traits feed skills)
              outbreak_skills ── progression (reads traits, grants xp)
      │
[presentation] outbreak_hud (NUI relay) · outbreak_wheel (action wheel) · outbreak_emotes (synced anims) · outbreak_binds (inputs) · outbreak_minigames
      │
[extended — HELD, not started until the slice boots]
              vehicles · craft · military · stations · raiders · camps · broadcast · map · world*
              (*world stays in the slice: night survival needs the synced clock)
```

## Authoritative services — who owns what

| Concern | Owner | Store | Read by others via |
|---|---|---|---|
| **Player condition tick** (sprinting, stealth, in-vehicle, speed, near-zombie count) | `outbreak_core` client | in-memory | event `outbreak:tick` (client, every 500ms, ONE loop) |
| **Zombie population** | `outbreak_core` client (per-area owner) | `zombies[]` registry | export `outbreak_core:getZombies()` / `nearestZombie(radius)` — nobody else scans `GetGamePool('CPed')` |
| **World events** (hordes, future convoys/caches) | `outbreak_core` server `director` | in-memory schedule | export `outbreak_core:scheduleEvent(name, minutes, payload)` + event `outbreak:event:<name>` |
| **World noise** | `outbreak_noise` client | `noise` number | export `getNoise()` + event `outbreak:noise:spike` (in) + `outbreak:hud:noise` (out) |
| **Character state** (hunger, thirst, fatigue, infection, wounds by body part, bleeding) | `outbreak_needs` — **server is authoritative store**, client is sensor + effector | MySQL `outbreak_needs` (JSON), mirrored to `LocalPlayer.state.needs` | export `getNeeds()` (client) · server export `getNeeds(src)` · event `outbreak:client:consume` (in, from server only) |
| **Wounds** | `outbreak_needs` | part of character state | server event `outbreak:server:wound` (client-detected hit → server stores) · treatment via `outbreak:server:treat(part)` |
| **Downed / death** | `outbreak_down` | `Player(src).state.downState` statebag (server-set) | statebag read by wheel, raiders, PvP search |
| **Properties** | `outbreak_housing` server | MySQL `outbreak_houses`, `outbreak_loot` | callbacks `outbreak:houseInfo`, key items are the ACL |
| **Radio messages** | `outbreak_radio` server | none | export `outbreak_radio:transmit(channel, title, text, targetSrc?)` → client filters by pma channel |
| **Faction reputation** | `outbreak_faction` server | MySQL `outbreak_reputation` | exports `getRep(src, faction)`, `addRep(src, faction, delta, reason)` |
| **Interaction targeting** | `ox_target` (foundation) + `outbreak_wheel` (contextual) | — | every resource registers targets through ox_target; the wheel aggregates *state-driven* actions |
| **Item definitions** | `outbreak_items/data/ox_items.lua` — the ONLY item list | ox_inventory | useables registered in `outbreak_items/server` only |
| **Inputs** | `outbreak_binds` — the ONLY `RegisterKeyMapping` calls | — | commands dispatched to owners |
| **Animations** | `outbreak_emotes` | — | export `action(name, durationMs)` — every progress-bar action calls this; animations on player peds replicate natively |
| **Settlements** (residents, morale, ledger, consumption debt) | `outbreak_supply` server | MySQL `outbreak_settlements` | exports `getSettlement(id)`, `settlements()`, `homeOf(src)`, `keyholders(id)`, `addResident`, `takeUnits`, `modify`, `log` · callbacks `outbreak:supply:model`, `outbreak:supply:home` · push `outbreak:supply:update` |
| **Stockpile levels** | nobody — a read-model over the ox stash `safehouse_<id>` | ox_inventory | `outbreak_supply` reads the stash and removes real items; never mirrors it. See DESIGN-supply.md |
| **World nudges** (stranger, rumours, probes, unrest) | `outbreak_director` server | MySQL `outbreak_director_log` | export `evaluate()`; rides `outbreak_core:scheduleEvent('director')` |
| **House read model** | `outbreak_housing` | — | new exports `getHouse(id)` → `{owner, barricade}`, `houses()` → `{id, label, door}`, `damageBarricade(id, n)` |
| **Defense events** | `outbreak_director` server | in-memory (`SetTimeout` stages; a restart mid-event cancels it) | export `defend(id)`; event `outbreak:director:defense(house, stage, data)` to all clients |
| **Resident bodies** | `outbreak_supply` client (cosmetic) | `GlobalState.obSettlements` (door, label, names, residents, morale — no stock) | spawned/despawned from the core tick, throttled 3 s |
| **Downed inputs** | `outbreak_down` client | — | per-frame disable of body controls only; chat, wheel, radio, F10, distress stay live. `SetPlayerControl(false)` is gone. |
| **Distress** | `outbreak_down` server | — | `outbreak:server:distress(street, state)` → radio MAYDAY with origin + `outbreak:client:distressPing` to channel listeners, or a 250 m scream |
| **OOC / announce** | `outbreak_chat` server | — | `/ooc`, `/announce` (ace outbreak.admin) via `chat:addMessage` inline templates |
| **Voice reset** | `outbreak_radio` | — | `outbreak:client:voiceReset` (item `mumble_pill`, `/voicereset [id]`, `/ob_voicereset`) |
| **Radio presentation** | `outbreak_radio` client `fx.lua` + NUI | — | prop/arm on `pma-voice:radioActive`, submix + hiss on `pma-voice:setTalkingOnRadio`, dead zones reported on the channel heartbeat and applied server-side both ways |
| **Admin state** | `outbreak_dm` server | statebags `obGod`, `obGhost` | other clients hide ghosted peds via the statebag handler |

## Loop budget (the "no duplicate monitors" rule)

Exactly these client loops exist in the slice:

1. `outbreak_core` **tick** (500 ms) — samples the player once, emits `outbreak:tick`
2. `outbreak_core` **spawner** (2.5 s) — population
3. `outbreak_core` **aggro** (1.5 s) — senses (reads noise export, weather statebag)
4. `outbreak_core` **population zeroing** (0 ms, natives only)
5. `outbreak_needs` **survival tick** (15 s) — decay + effects, consumes `outbreak:tick` samples
6. `outbreak_down` **death intercept** (100 ms) — must be fast
7. `outbreak_world` **clock/weather** (2 s)
8. `outbreak_housing` **barricade render** (event-driven, no loop)

Server-side schedules (all through `outbreak_core:scheduleEvent`, so they only fire with players online): `horde`, `supplyTick` (10 min), `director` (30–60 min). `outbreak_worlditems` entropy keeps its own 10-min thread (pre-dates the scheduler).

Removed by this pass: noise's own sampling loop (→ tick subscriber), needs' encumbrance loop (→ tick), skills' sneak loop (→ tick), emotes' movement-cancel loop (→ tick), identity/vehicles/camps `GetGamePool` scans (→ core export).

## Statebags (server-set unless noted)

- `Player(src).state.downState` — `nil | 'unconscious' | 'incapacitated' | 'critical'`
- `Player(src).state.recovering` — epoch until the post-station debuff ends (client-set)
- `Player(src).state.carrying` / `carriedBy` — carry/drag/load pipeline
- `Player(src).state.needs` — mirror of character state (server-set on save)
- `Player(src).state.scavLevel` — scavenging level for loot odds
- `Player(src).state.carriedBy` — carry/drag
- `Entity(veh).state.veh` — **server-set** read model `{plate, fuel, battery, hotwired, locked, part, claimed, noise}` (vehicles v2)
- `GlobalState.obTime / obWeather / obBlackout` — world
- `Player(src).state.obGhost` — director ghost (server-set by `outbreak_dm`); `outbreak_core`'s aggro loop skips ghosted players
- `GlobalState.obDebug` — debug mode (convar `ob_debug`)

## Events — canonical list (slice)

Client → Server (validated server-side):
`outbreak:server:saveNeeds` (sensor sync), `outbreak:server:wound`, `outbreak:server:treat`, `outbreak:server:search`,
`outbreak:server:claimHouse`, `outbreak:server:cutKey`, `outbreak:server:openHouseStash`, `outbreak:server:barricade`, `outbreak:server:forcedEntry`,
`outbreak:server:incapExpired`, `outbreak:server:bledOut`, `outbreak:server:stationTreat`, `outbreak:server:loadPatient`, `outbreak:server:unloadPatient`, `outbreak:server:helpPlayer`, `outbreak:server:trySelfStabilize`, `outbreak:server:searchDowned`, `outbreak:server:carry`,
`outbreak:server:saveIdentity`, `outbreak:server:xp`, `outbreak:server:me`, `outbreak:server:chaseEnded` (ext)

Server → Client:
`outbreak:client:loadNeeds`, `outbreak:client:consume`, `outbreak:client:infected`, `outbreak:client:antibiotics`, `outbreak:client:horde`,
`outbreak:client:radioMsg`, `outbreak:client:revived`, `outbreak:client:respawn`, `outbreak:client:corpseSpawned`, `outbreak:client:thisIsHowYouDied`,
`outbreak:client:freshSpawn`, `outbreak:client:createSurvivor`, `outbreak:client:skills`, `outbreak:client:barricadeLevel`, `outbreak:client:me`, `outbreak:client:carried`,
`outbreak:client:survivalDamage` (server computes starvation/bleed/infection damage, client applies it — `SetEntityHealth` is client-only),
`outbreak:supply:update` (settlement model to keyholders), `outbreak:director:stranger` / `outbreak:director:strangerResolved`

Client → Server (v0.16): `outbreak:supply:hello`, `outbreak:supply:cook(houseId, recipeId)`, `outbreak:supply:dismiss(houseId, name)`, `outbreak:director:takeIn(encounterId)`, `outbreak:director:sendAway(encounterId)`

Client-local bus:
`outbreak:tick`, `outbreak:noise:spike`, `outbreak:hud:update`, `outbreak:hud:noise`, `outbreak:client:bleedCheck`, `outbreak:anim:play`

## Server-authority audit

| Operation | Authority | Notes |
|---|---|---|
| Inventory add/remove | server (ox_inventory) | all AddItem/RemoveItem calls are server-side |
| Loot rolls + cooldowns | server | cooldowns persisted (`outbreak_loot`) |
| House claim / keys / stash / barricade | server | key item is checked server-side on every open |
| Forced entry | **mixed** | minigame result is client-reported; server only opens the stash. Limitation #1 |
| Wounds | **mixed** | hit is client-detected (only the client sees `CEventNetworkEntityDamage`); server stores & rate-limits. Limitation #2 |
| Treatment | server | item removal + state change server-side |
| Death / permadeath / corpse | server | |
| Carry / drag | server | consent + statebag; attach executed by both clients |
| XP / traits | server | |
| Faction changes / reputation | server | ace-gated command |
| Fuel / battery / part / lock / key / claim | **server** (vehicles v2) | server burns fuel from `GetEntityVelocity`; every mutation validated; claimed vehicles persisted + respawned server-side |
| Cooking / residents / morale | server | key + `DoorRange` + stash contents checked server-side; the client only picks a recipe |
| Stranger take-in | server | server-issued encounter id with expiry; key + 20 m of the door checked; the ped is cosmetic |
