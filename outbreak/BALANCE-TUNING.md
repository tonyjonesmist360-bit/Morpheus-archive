# BALANCE TUNING — which knob, which feeling (v0.23)

Everything below is `ob_tune set <key> <value>` in the console, live, no restart. `ob_tune` lists the current
values; `*` marks an override. `ob_tune reset` goes back to defaults. Test server vs friend server: keep two
`tuning.json` files and swap them (`ob_tune reload`).

| "The server feels…" | Turn | Direction | Notes |
|---|---|---|---|
| too hard, nothing to find | `loot.multiplier` | 1.0 → 1.5–2.0 | every chance in every table scales |
| too easy, pockets always full | `loot.multiplier` · `loot.respawnMinutes` | 0.5–0.7 · 30 → 90 | containers stay empty longer |
| quiet, nothing happens | `director.everyMin/Max` | 30/60 → 10/20 | passes happen sooner; weights decide what |
| too many strangers / rumours | `director.weight.stranger` etc. | lower the one that annoys | weights are relative |
| settlements never get hit | `director.weight.probe` | 25 → 60 | defense events |
| zombies are easy | `zombies.maxPerPlayer` · `zombies.mix.runner` · `zombies.mix.shambler` | 12 → 18 · 15 → 30 · 70 → 50 | more, and faster ones at night |
| zombies see you from space | `zombies.aggroRadius` | 30 → 22 | sight at visibility 50; sneak scales from it |
| nights are nothing special | `zombies.nightMultiplier` | 1.6 → 2.2 | |
| hordes too often / too rare | `horde.minInterval/maxInterval` · `horde.size` | | random horde events |
| the Tide never moves | `tide.everyMin/Max` | 20/40 → 10/20 | |
| infection is a death sentence | `infection.chancePerHit` · `infection.dirtyMinutes` · `infection.cureWithinHours` | 0.15 → 0.08 · 20 → 40 · 1 → 3 | |
| settlements starve too fast | `supply.foodPerResidentDay` / `waterPerResidentDay` | 2.0 → 1.2 | |
| residents leave too easily | `morale.leavingBelow` | 25 → 15 | |
| downed is over too quick | `down.bleedOutSeconds` · `down.criticalMinutes` | 300 → 600 · 30 → 60 | (read at the next down) |
| heists / minigames impossible | (Sheet #4) `minigames.*` | — | not a tuning key yet: `outbreak_minigames` config per game |

Rules of thumb: change one knob, play an hour, look at `logs kind:death` and `logs kind:director`, then decide.
Half-and-double is the right first step for a multiplier; ±25 % for a count.
