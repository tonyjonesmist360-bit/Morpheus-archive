# Commands — the complete list

Generated from the source on 2026-09-13 and checked against every registered command.
`SMOKE-SCRIPT.md` and `FIRST_BOOT_CHECKLIST.md` between them cite 31 commands; 11 more exist
and were documented nowhere, including `/ob_kit`, which is the one you want most often.

**Where to type these:** in game — chat (**T**) or the **F8** console. Not PowerShell, not the
txAdmin console. The exceptions are marked **console-safe** below: those are server commands and
can be typed into the txAdmin Live Console, which is how you get yourself out of trouble when
being downed has taken chat away from you.

## Gates

| Gate | Means |
|---|---|
| **debug** | needs `setr ob_debug 1` **and** ace `outbreak.debug`. Everything in `outbreak_debug`. |
| **admin** | ace `outbreak.admin`. Survives `ob_debug 0`, so it still works for the crew. |
| **dm** | ace `outbreak.dm`. |
| — | no gate, normal play. |

---

## Getting unstuck

| Command | Gate | Does |
|---|---|---|
| `ob_revive <id>` | admin | Pulls a player out of any downed/critical state. **Console-safe** — and from the console it skips the ace check entirely, so it works even if your principal is wrong. |
| `dm` | dm | Director menu. World → Ghost (invisible + invincible), Revive, Teleport, Bring. |

## Settlement & World Director (v0.16.0)

| Command | Gate | Does |
|---|---|---|
| `ob_home` | — | Opens your settlement ledger from anywhere (the same menu as Door → Settlement). |
| `ob_director` | debug | Forces one World Director pass now. **Console-safe.** Also: F10 → Story → "World Director: run a pass now". |
| F10 → Story → Settlement | dm | residents ± / morale ± on a house id. |

## Items and character state

| Command | Gate | Does |
|---|---|---|
| `ob_kit` | debug | **The whole slice kit at once**: beans, opener, clean + dirty water, purify tabs, 3 bandages, 2 ripped sheets, splint, antibiotics, radio, 2 batteries, 4 planks, nails, hammer. |
| `ob_give <item> <count>` | debug | One item. |
| `ob_key [house_id]` | debug | A safehouse key with metadata. Defaults to `sandy_bungalow`. |
| `ob_needs <hunger> <thirst> <fatigue>` | debug | Set the three bars directly. |
| `ob_reset` | debug | Wipe character state back to fresh. |
| `ob_state` | debug | Dump needs/wounds/infection **to the server console**. |
| `ob_persist` | debug | Snapshot of what should survive a restart. Run before, `ob_state` after. |
| `ob_wound <part> <kind>` | debug | Inflict a specific wound. |
| `ob_down` | debug | Go **unconscious** — note this is not the incapacitated state, so E self-splint will not apply. |

## World

| Command | Gate | Does |
|---|---|---|
| `ob_time <hour>` | debug | Set the clock. `22` for night. |
| `ob_weather <type>` | debug | e.g. `THUNDER`, `FOGGY`, `CLEAR`. |
| `ob_zombie <n>` | debug | Spawn n zombies next to you. |
| `ob_horde <size>` | debug | Fire a horde event at yourself. |
| `ob_radio <ch> <text>` | debug | Push a transmission. |
| `ob_rep <faction> <delta>` | debug | Move your reputation. |
| `ob_tp <name>` | debug | Teleport to a named spot, e.g. `sandy_bungalow`, `grove_house`. |

## Instrumentation — run these first, they retire whole bug classes

| Command | Gate | Does |
|---|---|---|
| `ob_animcheck` | debug | Loads every anim dictionary in `EmoteCfg.Actions`. Wants "0 missing". |
| `ob_models a,b,c` | debug | Validates prop models. **This is how you resolve any INVALID prop — test candidates, don't guess.** |
| `ob_anim <dict> <clip>` | debug | Play one animation to eyeball it. |
| `ob_walk` | debug | Toggle: prints the model name of whatever you aim at. Use it along 24/7 shelves. |
| `ob_scan <radius>` | debug | Lists nearby prop models. Use it inside a house for search spots. |
| `ob_look` | debug | Print what you are aiming at. |
| `ob_debugmenu` | debug | Context menu of the above. |

> Movement clipsets (`WalkStyles`) have **no** validity check — `SetPedMovementClipset` fails
> silently on a bad name. The only way to test one is to set it alone and watch whether zombies
> lurch. That is how `move_m@drunk@verydrunk` was identified as bad.

## Shakedown panel

| Command | Gate | Does |
|---|---|---|
| `shakedown` | debug | F9 panel. ▲▼ select, **P** pass, **F** fail, **N** note, **L** summary. |
| `pass <step>` / `fail <step> <note>` | debug | Mark a step from chat. |
| `shakedown_summary` | debug | Write the summary. |

Everything lands in `resources/[outbreak]/outbreak_debug/shakedown.log` — that is the shared record.

## Normal play (no gate)

`ob_wheel` (**G**) · `journal` (**J**) · `fallen` (**F5**) · `skills` · `look` · `me <text>` ·
`condition` · `craft` (**K**) · `wardrobe` · `semotes` · `stopemote` (**X**) · `writenote <text>` ·
`placeitem` · `scuff <note>` / `scufflist` · `setfaction <id> <job> <grade>` · `outfitcheck [component]`

## Internal / bound to keys

`e` (interact) · `ob_radioptt` (**N**, radio quick-open) · `cancelminigame` (minigame escape) ·
`ob_opp <op> <id>` (progression control — only useful once `[outbreak_progression]` is enabled)

---

## Known gap

`FIRST_BOOT_CHECKLIST.md` Z5 cites **`/listen`**, which is not registered. The wheel's
**Listen** action is the working path, and the checklist already says "(or wheel)". Use the wheel.
