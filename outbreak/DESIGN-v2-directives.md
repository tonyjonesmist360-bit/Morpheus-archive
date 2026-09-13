# v2 directives — captured 2026-09-13, post-first-boot

Tony's direction after the server came up, recorded verbatim in substance so nothing is lost.
Status column is honest: **built**, **staged** (written, needs in-game verification), or **open**.

## The ask

> Refine what we have so we can play for a few hours and it feels ready.
> All spawning random NPCs have zombie skins. Raiders and other factions get other skins.
> Important NPCs get specific skins, even story-mode ones if needed.
> Define mob areas and safehouses. Prep shelf-item labelling for the next server start.
> **First priority after that: the best and cleanest UI ever — a single button that goes from
> roleplay to a status update on everything you need or have, quickly.**

## The hard constraint nobody can design around

**GTA V ships essentially one zombie ped: `u_m_y_zombie_01`.** There is no zombie roster. Any server
where "everything looks like a zombie" either streams custom ped assets, or fakes it. We fake it,
three ways at once:

1. **`u_m_y_zombie_01` carries the most weight** — it is the only unambiguous read.
2. **Everything else is a derelict human** (tramps, skid row, hillbillies, autopsy) so the silhouette
   is already wrong for a living citizen.
3. **`ApplyPedDamagePack` on spawn** puts blood and wounds on every one of them, which is what
   actually sells "infected" at 15 m. This is the part that was missing.

Plus the movement clipset (`move_m@injured`, confirmed working) doing the lurch.

Custom ped streams are the only way past this, and that is a content decision, not a code one.

## Decisions taken

| Area | Decision |
|---|---|
| Random NPCs | Ambient population is already zeroed by `outbreak_core`. Every ped the player sees in the open world is a spawned zombie. |
| Zombie look | Weighted toward `u_m_y_zombie_01`, all variants damage-packed on spawn. |
| Factions | Raiders `g_m_y_lost_*` / `salvagoon`; military `s_m_y_marine_*`. Already configured, kept. |
| Named NPCs | New roster using story-mode models (`ig_*`, `cs_*`) so recurring characters are recognisable. |
| Mob areas | New `HotZones` — named areas with a density multiplier and a variant bias. |
| Safehouses | The 8 in `HousingCfg.Houses` stand. Mob areas are placed to leave them approachable. |
| Shelf labelling | `/ob_walk` capture workflow + a file to paste results into. |
| Status UI | One key, full picture, built as its own resource so it cannot destabilise the HUD. |

## Verification rule — applies to everything below

**Every ped and prop model named here is unverified until `/ob_models` says otherwise.** Four of ten
props in the original pack were INVALID. Assume the same hit rate on peds. A single command to check
every new name ships alongside the change.
