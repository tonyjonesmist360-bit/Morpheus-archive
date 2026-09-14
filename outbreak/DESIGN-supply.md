# Settlements, supply, morale, and the World Director — v0.16.0

Built 2026-09-14 from Tony's autonomous-work brief: *"scavenge → store → cook → consume → run low →
need drives the next run"*, stockpiles with visible levels, consumption by resident count, spoilage,
morale as behaviour, and a Director that nudges the world every 30–60 minutes. Everything ships with
its UI. Nothing here has run on FXServer yet — see the test section at the end.

## The one decision everything hangs on

**The stockpile is the house stash.** A settlement is a claimed safehouse; its stockpile is
`safehouse_<id>`, the ox_inventory stash `outbreak_housing` already registers. `outbreak_supply` never
stores stock — it *reads* the stash and turns item counts into category units through one table
(`SupplyCfg.Value`). Deposit and withdraw are therefore the stash UI the crew already knows, there is
no lossy "convert 3 beans into 3 food points" step, and the Director can reason about levels without
a second inventory to keep in sync.

```
player pockets ──(open storage)──> safehouse_<id> stash ──(read)──> units per category
                                         ▲    │                          │
                    cooking puts back ───┘    └── residents eat / spoilage removes ──> needs, morale, Director
```

## Ownership (additions to ARCHITECTURE.md)

| Concern | Owner | Store | Read by others via |
|---|---|---|---|
| Residents, morale, settlement log, debt/flags | `outbreak_supply` server | MySQL `outbreak_settlements` | exports `getSettlement(id)`, `settlements()`, `homeOf(src)`, `keyholders(id)` · callbacks `outbreak:supply:model(id)`, `outbreak:supply:home` · push `outbreak:supply:update` to keyholders |
| Stock levels | **not owned** — derived from the ox stash each read | — | same exports; `takeUnits(id, cat, units, 'scraps'|'best')` removes real items |
| Cooking | `outbreak_supply` server (`outbreak:supply:cook`) | consumes from / adds to the stash | validated: key + within `DoorRange` + inputs + fuel present |
| Claim / keys / barricade | `outbreak_housing` (unchanged) | `outbreak_houses` | new read-only exports `getHouse(id)`, `houses()` |
| World nudges | `outbreak_director` server | MySQL `outbreak_director_log` | export `evaluate()`; `/ob_director`; DM → Story → "run a pass now" |
| The stranger encounter | `outbreak_director` (server token, client body) | in-memory `pending[id]` with expiry | events `outbreak:director:stranger` → `takeIn` / `sendAway` → `strangerResolved` |

**Loops.** None on the client. Both server ticks go through `exports.outbreak_core:scheduleEvent`
(`supplyTick` every 10 min, `director` every 30–60 min), so they only run while someone is online
and the scheduler count in ARCHITECTURE stays at one. Offline time does not consume anything — the
world moves when someone is in it.

## Consumption, spoilage, cooking

- Per resident per day: food 2, water 2, medicine 0.1, fuel 0.5, comfort 0.5 (`PerResidentPerDay`).
  Ammo and materials are spent by events (probes, disputes), never by the clock.
- Each tick accrues *debt* per category; at ≥1 unit it removes real items. **Debt is capped at one
  day's worth**, so a restock after a dry spell is not eaten in a single tick.
- Residents eat **scraps first**: things that spoil, then the lowest-value items. Someone *leaving*
  takes the **best**.
- Spoilage is statistical: expected loss per tick = `count × tick_hours / Spoil[item]`. No per-item
  timestamps. Bread 24 h, hot stew 18 h, noodles 12 h, murky water 12 h, spoiled meat 6 h.
- Recipes take from the stockpile and put back into it, at the door, burning one `FuelItems` entry
  (plank or fuel can). A *hot* meal gives a morale bonus at most once per 30 minutes.
  Boil (2 murky → 2 clean) · Bean stew (beans + water → 2 stew) · Hot noodles · Cook the meat.
- Cooking animation reuses the verified `siphon` action (pouring). No new anim dictionary from memory.

## Needs = objectives

Per category the model gives `status ∈ {critical, low, ok, good}`, `days` (with residents) or
units-vs-reserve (without), `ask` = how many units to bring to reach `TargetDays` (3), and `pct`
for bars. Without residents nothing is *critical* — an empty new claim reads as objectives, not
alarms. Extra objectives: unboiled water, no barricade, rounds short of `max(10, residents×10)`,
room for more people, and "someone is asking for a beer" when comfort is empty and morale under 50.

## Morale → behaviour (`SupplyCfg.Morale`)

Per tick: −2 per critical food/water, −1 per low, +0.5 when fed, +1 when comfort ≥ residents/2,
−5 while starving. Events: hot meal +5, resident joined +3, left −8, died −12, held the door +4.
Rolled every tick while residents ≥ 1:

| Morale | Roll | What you see |
|---|---|---|
| < 45 | 15 % dispute | ledger line, a materials unit gone, "Shouting at home" notify |
| < 35 | 20 % drinking | the comfort stock gone, "Empty bottles by the door" |
| < 25 | 25 % leaving | residents −1, best food/water/bandage gone, **a note at the door** (`outbreak_worlditems:placeSystem`), others −5 |
| food out ≥ 2 ticks | starving | −5/tick; at 6 ticks (1 h) one resident dies |

## The Director (`DirectorCfg`)

For each settlement with a keyholder online, candidate nudges are scored (`Weights`) and gated by
per-house cooldowns (`Cooldowns`); one is picked by weighted random; `nothing` and `quiet` are always
candidates so quiet nights exist.

| Nudge | When | Does |
|---|---|---|
| `stranger` | residents < target, fed (≥2 days or ≥4 meals), morale ≥ 45 | a survivor ped walks to the door on the nearest keyholder's client; **Take them in** → `addResident`, **Send them away** → they leave. Expires in 10 min. |
| `rumor_food` / `rumor_medicine` | that category low/critical | radio, channel 0, naming the nearest store/clinic from `Rumors` |
| `probe` | residents ≥ 1 and (no barricade or ammo not good) | radio warning; a horde of 8 on the nearest keyholder within 200 m; `residents×2` rounds spent; morale +4 held / −3 not |
| `unrest` | residents ≥ 1, morale < 30 | "Word from home" notify to keyholders |
| `trader` | everything good | a rumour that someone is asking about your place |
| `safehouse` | no settlement exists at all | radio tip naming an unclaimed house |

Every action is a row in `outbreak_director_log` and a line in the settlement ledger.

## UI

- **Door menu → Settlement** (`outbreak_housing` adds the entry when supply is running) → ox_lib
  context: residents/morale progress row, one progress row per category with days or units and a
  "bring N" description, unboiled water, Open the stockpile, Cook, Objectives, Ledger. `/ob_home`
  opens it from anywhere for your home.
- **F1** grows a fifth **Home** column: same thin bars, same low/critical stripes and throb, morale,
  objectives with a status pip, last three ledger lines.
- **HUD strip**: one token, on the existing tick — `HOME FOOD` in rust when critical, `HOME LOW`
  quietly when low, `HOME STARVING`. Colour reinforces, the word carries (UI-SYSTEM.md).
- **Director menu → Story**: "World Director: run a pass now", "Settlement: residents / morale".

## Tuning knobs worth knowing

`SupplyCfg.TickMinutes`, `TargetResidents`, `TargetDays`, `Reserve`, `PerResidentPerDay`, every
threshold and chance under `Morale`; `DirectorCfg.EveryMinutes`, `Weights`, `Cooldowns`,
`ProbeSize`. For a test evening: `TickMinutes = 2`, `EveryMinutes = { 3, 5 }`, and the DM menu's
settlement tool to seed residents and drop morale.

## What is unverified until it runs

- ox_lib context `progress` / `colorScheme` / `readOnly` / `disabled` option fields render as
  intended (descriptions carry the numbers regardless).
- `GetInventoryItems` on a registered-but-never-opened stash returns its items (outbreak_camps
  relies on the same behaviour).
- The four stranger models are the ones `outbreak_dm` / `outbreak_housing` already use — still run
  `/ob_models`.
- Rumour coordinates only choose the *nearest* label; the label is what the player hears.

## Test (SMOKE-SCRIPT §14)

S1 claim a house, Door → Settlement: seven bars, "Nobody yet" · S2 put 3 beans + 2 water + 1 plank in
storage, reopen: bars move · S3 Cook → Bean stew: plank and beans gone, 2 hot stew in storage, ledger
line · S4 DM → Settlement +2 residents; set `TickMinutes = 2` and watch a meal vanish; HOME LOW on
the strip when food drops · S5 DM morale −45, wait two ticks: a note appears at the door, resident
count drops · S6 DM → run a Director pass with food stocked: a stranger at the door, Take them in →
resident +1 · S7 empty the food, run a pass: a food rumour on channel 0 naming the nearest 24/7 ·
S8 F1: Home column matches the ledger.
