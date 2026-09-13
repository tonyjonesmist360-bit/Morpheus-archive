# illenium-appearance — apocalypse settings

Edit `illenium-appearance/config.lua` (recipe ships it). These are the lines to change:

- `Config.EnablePedsForShops = false`        -- no shopkeepers
- `Config.EnableJobOutfits = true`           -- military fatigues live here
- `Config.RCoreTattoosCompatibility = false`
- Shops/Barbers/Clothing rooms: set every `price` / `barberPrice` etc. to `0`.
  There is no money. Clothing changes happen at **safehouse wardrobes**
  (outbreak_identity adds a "Wardrobe" target inside every claimed house) and
  at the Zancudo armory (fatigues).
- `Config.Blacklist` — ban the clean-city look so every survivor reads as post-fall:
    * masks: none (masks are fine — bandanas, respirators)
    * torsos: formal jackets & tuxedos (male 33-35, female 25-27 as a starting list — verify in creator)
    * legs: suit trousers
  Verify IDs in-game once; drawable numbering shifts by DLC pack.
- **Clipping**: illenium's outfit slots use GTA's own component/prop matrix, so
  clipping is per-combo, not fixable in config. Two mitigations already wired:
    1. The **Survivor Presets** below are curated combos meant to be checked once
       in-game and then locked as `Config.DefaultOutfits` — anything that clips
       gets swapped before the crew ever sees it.
    2. `outbreak_identity` exposes `/outfitcheck` which cycles a player through
       torso/undershirt/legs combos slowly so you can eyeball clipping during the
       shakedown and blacklist the offenders.
