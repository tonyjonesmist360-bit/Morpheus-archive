# THE WORLD EDITOR — F10 → Editor

Needs the `outbreak.dm` ace. `/editor` toggles it too. While you are in it the server makes you not-there:
invisible, invulnerable, every faction ignores you, needs paused, noise zero, no infection rolls, no fall damage.
The world keeps running for everyone else. Esc puts you back on the ground where the cursor was.

## Moving
| | |
|---|---|
| WASD | fly (Shift fast, Ctrl slow) |
| Right-drag | look |
| Space / Q | up / down |
| Wheel | height · Ctrl+wheel rotates the heading |
| G | grid snap 0 → 0.25 → 0.5 → 1 → 2 m |
| R / Shift+R | heading ±15° |
| Z / Y | undo / redo |
| Del | delete the selection |
| Right-click | select what is under the cursor |

## Palette (left)
- **Place NPC** — model (type any ped model; the list is a start), *Preview* shows it translucent on the cursor. Name, look (what the target says), behaviour: stand (pose), wander (radius), guard (weapon; shoots the dead and returns), patrol (points in the record), sleep. Stance picks the relationship group: friendly, neutral, hostile, military, raider, yard.
- **Suppress map ped** — click an ambient ped. That model stops spawning within 30 m of the spot. Persistent. Listed under *Everything placed*.
- **Make interactable** — click a prop (sphere zone on it), a placed NPC (option on the NPC) or the ground (point, or a zone if you set a radius). Label, icon (Font Awesome class), hold ms, animation. **Conditions** gate it; **actions** run in order on the server.
- **Prop → container** — a stash on any prop (`stash` action with its own id).
- **Shelf → loot** — click shelves, pick the loot table; 30-minute cooldown per player by default.
- **Paint zone** — safe / infested / territory (faction) / loot (bias) / quarantine. Circles. The spawner multiplies by `safe 0 · infested 2.5 · quarantine 1.5`; loot multiplies by the bias.
- **Mission step here** — drops a `goto` step at the cursor into the mission being edited.

## Conditions
`item` (item, count) · `rep` (faction, min) · `time` (from, to hours) · `flag` (name, value) · `settlement` (holds any door key) · `once` (per character, persisted) · `cooldown` (seconds per character) · `chapter` (min; reads flag `chapter`) · `job` (job name).

## Actions
`give` / `take` (item, count) · `stash` (id, label, slots, weight) · `say` (title, text) · `notify` (title, text, type) · `mission` (op start|available|join, id) · `report` (mission, kind talk) · `flag` (name, value) · `scene` (a DM scene id) · `transmit` (ch, title, text) · `spawn` (kind horde|zombies, count) · `rep` (faction, delta, reason) · `teleport` (x, y, z) · `heal` · `learn_channel` (ch) · `noise` (v) · `loot` (table, label).

## Loot, items
*Loot tables* lists every pack table plus overrides. Edit rows (item, min, max, chance) and *Save override*: it applies to every search of that table immediately (shelves, containers, loot sites). *Reset to pack* removes the override.
*New item*: name, label, weight, description, PNG icon ≤ 64 KB. It is drafted into the managed `EDITOR ITEMS` section of `outbreak_items/data/ox_items_snippet.lua` and the icon into `ox_inventory/web/images/`. Then `setup/04-paste-ins.ps1 -Only items` and a restart. ox_inventory cannot hot-add items.

## Missions
Steps in order: `goto` (x y z radius) · `collect` (item count; checked every 2 s) · `deliver` (npc id, item, count; fired by a *talk* interaction on that NPC with action `report mission <id> kind talk`) · `talk` (npc id; same) · `kill` (count of zombies you kill) · `flag` (flag, value). Rewards: give / rep / flag / notify. Fail-after minutes, cooldown, repeatable. Each mission is a real opportunity (journal, persistence, state). ▶ in the list makes it available and starts it for you.

## Content packs
*Export* writes `outbreak_editor/packs/<name>.json` with every NPC, hidden ped, interaction, zone, kv (loot overrides, flags, item drafts) and mission. *Import* adds (never deletes). Console: `editor_export [name]`, `editor_import <name>`.

## Where it lives
Tables `outbreak_editor_npcs / hidden_peds / interactions / zones / kv / missions / once` (migration 010). Published as `GlobalState.obEditor` (rev bumps on every change; clients re-register targets within 2 s). Everything is logged as `editor.<verb>` and `editor.interact`.
