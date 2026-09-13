# Integration report — v0.12 (slice + services; all five progression chains)

Labels: **IMPL** = written to the documented API, parses, integration points wired ·
**PARTIAL** = core path written, an edge or dependency is stubbed ·
**MOCK** = placeholder behaviour standing in for a real system ·
**UNTESTED** = every file. Nothing here has executed on FXServer. Static verification: Lua 5.4 syntax on all 131 script files; NUI JavaScript parsed with node; cross-resource events/exports/callbacks/config/manifests/items/SQL/start-order checked by `tools_diag.py` + `tools_diag2.py` (0 errors, 0 warnings at seal).

## [outbreak] — the slice

### outbreak_core
| File | Status | Provides | Consumes |
|---|---|---|---|
| `shared/config.lua` | IMPL | `OutbreakCfg` | — |
| `client/zombies.lua` | IMPL / UNTESTED | **tick bus** `outbreak:tick`; exports `getTick, getZombies, nearestZombie, countZombies, spawnZombieAt`; population; aggro; variants; weather mods; `outbreak:client:infected`, `outbreak:client:horde` | `outbreak_noise:getNoise` (pcall), `GlobalState.obWeather`, `outbreak_skills:hasTrait` (pcall), `outbreak:event:horde` |
| `server/director.lua` | IMPL | **world events service** exports `scheduleEvent, fireEvent, cancelEvent`; `GlobalState.obDebug` | `outbreak_radio:transmit` (pcall) |
Notes: `ResurrectPed` path (headshot-only) PARTIAL/unverified. Per-client population is a documented limitation.

### outbreak_needs — authoritative character state
| File | Status | Provides | Consumes |
|---|---|---|---|
| `shared/config.lua` | IMPL | `NeedsCfg` incl. wounds, bone map | — |
| `client/needs.lua` | IMPL / UNTESTED | sensor (hits→`outbreak:server:wound`, 15 s `needsTick`), effector (move rate, fever, encumbrance); exports `getNeeds, isBleeding, getWounds` | `outbreak:tick`, `ox_inventory:GetPlayerWeight/MaxWeight` (pcall) |
| `server/needs.lua` | IMPL / UNTESTED | store + `Player.state.needs`; exports `consume, treatWound, getNeeds, getWounds, reset`; events `needsTick, wound, infect, rest`; `outbreak:client:needsState`, `loadNeeds` | MySQL `outbreak_needs`, `outbreak_skills:hasTrait(src)` (pcall) |
Notes: bone-ID→part map is from memory (PARTIAL — verify `GetPedLastDamageBone` IDs). `GetWeapontypeGroup` fall/vehicle hashes PARTIAL.

### outbreak_noise
| `client/noise.lua` | IMPL | `getNoise()`, `outbreak:hud:noise`; in: `outbreak:noise:spike` | `outbreak:tick`, skills exports (pcall) |
No loop of its own. IMPL.

### outbreak_hud
| `client/hud.lua` | IMPL | NUI relay for needs + noise | `outbreak:hud:update`, `outbreak:hud:noise`, `NeedsCfg` (shared from needs) |
| `html/index.html` | IMPL / UNTESTED (JS not parsed) | vitals, moodles incl. wounds, noise ripple | — |

### outbreak_items — single useable registry + loot service
| `data/ox_items_snippet.lua` | IMPL | item defs (paste-in) | ox_inventory |
| `server/items.lua` | IMPL | useables; `outbreak:server:treat`, `treatOther`; `outbreak:anim:play` | `outbreak_needs:consume/treatWound`, skills (pcall) |
| `server/loot.lua` | IMPL | `outbreak:server:search`; exports `search, roll, isSearched`; **persistent cooldowns** | MySQL `outbreak_loot`, `Player.state.scavLevel` |
| `client/loot.lua` | IMPL | ox_target on container models | `outbreak_emotes:action` |
| `shared/loot_config.lua` | IMPL | tables | — |

### outbreak_housing — persistent properties
| `shared/config.lua` | IMPL / coords UNVERIFIED | houses, spots, stories | — |
| `server/housing.lua` | IMPL | keys-as-ACL; claim, cutKey, stash, barricade, forcedEntry (see limitation 1), houseSearch, `characterDied` release | MySQL `outbreak_houses`, `outbreak_items:search` |
| `client/housing.lua` | IMPL | door menu (claim / shelter / search / storage / barricade / key / force), interiors (teleport), barricade props, wardrobe target | `outbreak_minigames:play`, `outbreak_emotes:action`, `outbreak:noise:spike` |
Notes: `prop_ld_planks01` model name PARTIAL (falls back to crate).

### outbreak_radio — radio message service
| `server/radio.lua` | IMPL | export `transmit(ch, title, text, target)`; battery drain heartbeat; radio useable | ox_inventory |
| `client/radio.lua` | IMPL / mm_radio PARTIAL | channel dialog, filter incoming by pma channel, phone disabled; export `getChannel` | pma-voice exports, `mm_radio` (pcall, API guessed) |

### outbreak_down — injury/downed/death
| `shared/config.lua` | IMPL | `DeathMode, PvP`, timers, respawn points | — |
| `client/down.lua` | IMPL / UNTESTED | death intercept (100 ms loop, allowed), unconscious/incapacitated/**critical**, self-splint, adrenaline, station targets + blips, recovering debuff (tick), corpses, `/fallen`, ox_target on players, **carry/drag/load/unload** via statebags | `outbreak_emotes:loopAction/stopAction`, `Player.state.downState` (client-set, replicated) |
| `server/down.lua` | IMPL | help/stabilize, **incapExpired → critical**, **stationTreat** (items, distance, medicine-level odds), adrenaline useable, `/ob_revive` (ace), load/unload, bledOut (corpse stash, memorial, permadeath logout), searchDowned, carry, callbacks `memorial, corpses` | MySQL, `exports.qbx_core:Logout` (pcall), `outbreak_skills:grantXP`, fires `outbreak:server:characterDied` |
| `html/down.html` | IMPL | veils, timer, epitaph | — |
Notes: attach offsets for carry/drag are MOCK-grade (will need tuning). `goDown` re-entry after detach PARTIAL.

### outbreak_spawn
| `shared/config.lua` | IMPL | 3 scenarios | — |
| `server/spawn.lua` | IMPL | first-spawn detection, money wipe, kit, starting needs, time/weather, delayed radio | `outbreak_needs:consume`, `outbreak_world:setTime/Weather`, `outbreak_radio:transmit` |
| `client/spawn.lua` | IMPL | fade-in + story | — |

### outbreak_identity
| `client/identity.lua` | IMPL / illenium API PARTIAL | creator call, WHO WERE YOU dialog, `/look`, `/me`, `/wardrobe`, `/outfitcheck` | illenium exports (pcall) |
| `server/identity.lua` | IMPL | store, `outbreak:server:traitsSet`, `/me` relay | MySQL `outbreak_identity` |
| `data/illenium_config_notes.md` | doc | — | — |

### outbreak_skills
| `server/skills.lua` | IMPL | exports `hasTrait(src), getLevel(src), grantXP`; `scavLevel` statebag; trait starts | MySQL, identity traits |
| `client/skills.lua` | IMPL | exports `getLevel, hasTrait, effects`; passive XP via tick; `/skills` | `outbreak:tick` |

### outbreak_faction
| `server/faction.lua` | IMPL | **reputation service** `getRep/addRep`; faction stashes; `/setfaction` | MySQL `outbreak_reputation` |
| `client/faction.lua` | IMPL | relationship groups by job, faction targets | illenium (pcall) |
| `data/jobs_snippet.lua` | IMPL | paste-in | qbx_core |
Reputation is IMPL but **unused by the slice** (no producer/consumer yet) — present as a service only.

### outbreak_emotes
| `shared/emotes.lua` | IMPL / dict names PARTIAL | emotes + `Actions` | — |
| `client/emotes.lua` | IMPL | emotes, `/e`, exports `play, stop, action, loopAction, stopAction`; `outbreak:anim:play` | `outbreak:tick`, rest→`outbreak:server:rest` |

### outbreak_wheel
| `client/wheel.lua` | IMPL / UNTESTED | contextual `lib.registerRadial`; treat self/other, help/pulse/carry/drag/search downed, radio, listen, emotes, surrender, vitals, skills | needs, core, emotes, down statebags, ox_inventory `Search` (pcall) |

### outbreak_binds
| `client/binds.lua` | IMPL | the only `RegisterKeyMapping`s; kb + pad | commands owned elsewhere |

### outbreak_minigames
| `client/main.lua`, `html/index.html` | IMPL / UNTESTED | export `play(game, opts)` (pinsweep, pry, splice) | — |

### outbreak_world
| `server/world.lua` | IMPL | GlobalState clock/weather/blackout; exports `setTime, setWeather` | — |
| `client/world.lua` | IMPL | applies time/weather/blackout | GlobalState |

### outbreak_debug
| `server/debug.lua`, `client/debug.lua` | IMPL | test commands + menu (ace + `ob_debug`) | every service export |

### Added after the slice (all IMPL / UNTESTED unless noted)
| Resource | Status | Notes |
|---|---|---|
| `outbreak_weapons` | IMPL | catalog, per-weapon noise, jams, repair, legendary attention, flare beacon. ox weapon API names PARTIAL (limitation 18) |
| `outbreak_worlditems` | IMPL | place/take/storage/notes/shelves + entropy. Prop model names PARTIAL (limitations 19–20); server object natives assumed |
| `outbreak_dm` | IMPL | director menu, scenes, audit log. Client-side spawns for the director's own scenes |
| `outbreak_radio` range model | IMPL | reach matrix, repeaters, base stations, garbling. pma-voice event name PARTIAL (limitation 16) |
| `outbreak_vehicles` v2 (extended) | IMPL | server-authoritative; claimed vehicles persist/respawn. Class profile client-reported once |
| `outbreak_intel` (progression) | IMPL | per-character store, sources, journal (kb + pad relay) |
| `outbreak_opportunities` (progression) | IMPL | registry, camps entity, chains 1–5 IMPL (island on boats + Cayo Perico) |

## [outbreak_extended] — HELD
vehicles (fuel client-side: MOCK persistence), craft (IMPL), military (IMPL; Quartermaster), stations (IMPL), raiders (IMPL; PIT behaviour PARTIAL), camps (IMPL), broadcast (PARTIAL — still uses its own `radioMsg` event; must be re-pointed to `outbreak_radio:transmit` and core `scheduleEvent` before enabling), map (IMPL).
All extended resources still reference the pre-refactor `outbreak:client:consume` client event in places (vehicles, none critical) — **not wired to the new needs API**; that is the first task when they're unheld.

## Cross-cutting
- Single tick bus: IMPL (noise, needs, skills, emotes subscribe; nothing else polls the player).
- Zombie registry: IMPL in slice. Extended `vehicles`/`camps`/`identity` still contain `GetGamePool('CPed')` scans → PARTIAL (identity's `/listen` is in emotes and uses core export; vehicles/camps are held).
- Server authority: see ARCHITECTURE.md audit. Two documented trust gaps (forced entry, wound reports).
- Restart persistence in the slice: needs+wounds+infection, identity, skills, houses (owner/barricade/visited), loot cooldowns, memorial, corpses (24 h), reputation. Keys are ox_inventory items (persisted by ox). NOT persisted: hotwired/battery vehicle states (extended), active hordes.
