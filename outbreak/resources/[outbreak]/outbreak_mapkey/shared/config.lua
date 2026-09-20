MapKeyCfg = {
  -- Vanilla blip sprites that do not belong in the apocalypse. Removed every 10 s from the core
  -- tick (they respawn when the game streams a new area). Sprite ids from memory - UNVERIFIED;
  -- if a wanted blip vanishes or an unwanted one stays, this is the list to edit. Never put a
  -- sprite here that the Legend below uses.
  -- PLACES (v0.25): the map shows what you can loot or use, named. Coordinates from memory - unverified;
  -- stand on the real spot and use /coords to correct. Sprite ids from memory too.
  Places = {
    store    = { sprite = 52,  colour = 0,  scale = 0.65, legend = '24/7 / LTD',        what = 'Shelves to steal from, a till to force.', list = {
      { 'Sandy Shores 24/7', vec3(1960.5, 3740.6, 32.3) }, { 'Grapeseed store', vec3(1698.4, 4924.4, 42.1) }, { 'Paleto 24/7', vec3(1729.2, 6414.9, 35.0) },
      { 'Route 68 LTD', vec3(1165.1, 2709.6, 38.2) }, { 'Strawberry 24/7', vec3(25.7, -1347.3, 29.5) }, { 'Innocence Blvd 24/7', vec3(373.9, 325.9, 103.6) },
      { 'Clinton Ave 24/7', vec3(2557.5, 382.3, 108.6) }, { 'Tataviam LTD', vec3(1135.8, -982.3, 46.4) }, { 'Mirror Park LTD', vec3(1163.4, -323.8, 69.2) },
      { 'Little Seoul 24/7', vec3(-707.5, -914.3, 19.2) }, { 'Morningwood 24/7', vec3(-1222.9, -906.9, 12.3) }, { 'Chumash 24/7', vec3(-3038.9, 585.9, 7.9) },
      { 'Banham Canyon 24/7', vec3(-3242.9, 1001.5, 12.8) }, { 'Harmony LTD', vec3(548.5, 2671.4, 42.2) }, { 'Ineseno LTD', vec3(-2967.9, 390.9, 15.0) }, { 'Vespucci LTD', vec3(-1487.5, -379.1, 40.2) } } },
    clothing = { sprite = 73,  colour = 0,  scale = 0.6,  legend = 'Clothing store',   what = 'Change clothes for free; racks to loot.', target = 'clothes', list = {
      { 'Binco Strawberry', vec3(75.3, -1392.9, 29.4) }, { 'Suburban Vinewood', vec3(613.1, 2761.7, 42.1) }, { 'Ponsonbys Rockford', vec3(-709.2, -152.9, 37.4) },
      { 'Binco Grove St', vec3(-167.9, -299.1, 39.7) }, { 'Discount Store Paleto', vec3(4.6, 6512.5, 31.9) }, { 'Suburban Sandy', vec3(1696.3, 4829.3, 42.1) },
      { 'Binco Vespucci', vec3(-1097.4, 2710.9, 19.1) }, { 'Discount Little Seoul', vec3(-822.3, -1073.4, 11.3) } } },
    barber   = { sprite = 71,  colour = 0,  scale = 0.6,  legend = 'Barber',           what = 'Still charges. Five Old Money, every time.', target = 'barber', list = {
      { 'Herr Kutz Vinewood', vec3(-814.3, -183.8, 37.6) }, { 'Bob Mulét Rockford', vec3(-32.9, -152.3, 57.1) }, { 'Beach Combover Vespucci', vec3(-1282.6, -1116.8, 7.0) },
      { 'Hair on Hawick', vec3(136.8, -1708.4, 29.3) }, { 'Herr Kutz Paleto', vec3(-278.1, 6228.5, 31.7) }, { 'O\'Sheas Sandy', vec3(1931.5, 3729.7, 32.8) } } },
    customs  = { sprite = 72,  colour = 0,  scale = 0.6,  legend = 'Mechanic / customs', what = 'Mods and repairs. No money changes hands (mechanics faction: next build).', list = {
      { 'LS Customs Burton', vec3(-337.4, -136.9, 39.0) }, { 'LS Customs airport', vec3(-1155.0, -2007.0, 13.2) }, { 'Beeker\'s Garage Paleto', vec3(110.0, 6626.0, 31.8) }, { 'Beeker\'s Garage Harmony', vec3(1175.0, 2640.0, 37.8) } } },
    prison   = { sprite = 188, colour = 1,  scale = 0.7,  legend = 'Bolingbroke',       what = 'Fifty of the dead, once. Clear it for the cafeteria, infirmary, towers and cells.', list = { { 'Bolingbroke Penitentiary', vec3(1700.0, 2590.0, 45.6) } } },
  },
  -- derived categories (from other resources' configs): gun stores + vaults (LootCfg.Sites), stations (DownCfg), benches (CraftCfg)
  Derived = { gunstore = { sprite = 110, colour = 0, scale = 0.6, legend = 'Gun store (loot)' }, vault = { sprite = 108, colour = 0, scale = 0.6, legend = 'Bank vault (loot)' },
              station = { sprite = 61, colour = 2, scale = 0.7, legend = 'Medical station' }, bench = { sprite = 402, colour = 0, scale = 0.55, legend = 'Workbench' } },
  Barber = { price = 5 },
  HideSprites = { 52, 71, 73, 75, 76, 77, 108, 110, 121, 205, 217, 500, 501, 502, 617, 619, 434, 279 },
  -- The legend. Order is the order shown. `res` = the resource that draws it (hidden from the
  -- key while that resource is not running, so the key never lists what is not on the map).
  Legend = {
    { icon = 'house',            colour = '#d8d2c0', label = 'Safehouse door',            what = 'A house you can claim. Grey.',                              res = 'outbreak_housing' },
    { icon = 'kit-medical',      colour = '#5e8a4c', label = 'Medical station',           what = 'Critical patients are treated here. Green cross.',           res = 'outbreak_down' },
    { icon = 'tower-broadcast',  colour = '#5e8a4c', label = 'Radio repeater',            what = 'Green = active, grey = dead. Extends radio range.',          res = 'outbreak_radio' },
    { icon = 'triangle-exclamation', colour = '#b4552d', label = 'Distress / DEFEND',     what = 'Red, flashing. Someone is down, or a settlement is under attack.', res = 'outbreak_down' },
    { icon = 'water',            colour = '#b4552d', label = 'The Tide',                  what = 'Red area. A roaming super-horde. Stay off those roads.',      res = 'outbreak_director' },
    { icon = 'location-dot',     colour = '#c98f3d', label = 'Crew pin',                  what = 'A marker your crew dropped. Only your crew sees it.',         res = 'outbreak_group' },
    { icon = 'user',             colour = '#5f8fa3', label = 'Crew member',               what = 'Blue. Where your people are.',                               res = 'outbreak_group' },
    { icon = 'circle-question',  colour = '#c98f3d', label = 'Rumour area',               what = 'Yellow area. Something is said to be in there. Go look.',     res = 'outbreak_intel' },
    { icon = 'map-pin',          colour = '#d8d2c0', label = 'Confirmed location',        what = 'A place the journal has confirmed. Yellow when active.',      res = 'outbreak_intel' },
    { icon = 'campground',       colour = '#b4552d', label = 'Camp',                      what = 'A survivor camp with a stockpile.',                          res = 'outbreak_camps' },
    { icon = 'shield-halved',    colour = '#7d8a5c', label = 'Military checkpoint',       what = 'Soldiers. Friendly if you are one of them.',                  res = 'outbreak_military' },
    { icon = 'gas-pump',         colour = '#c98f3d', label = 'Station',                   what = 'A fuel station with a shop to loot.',                         res = 'outbreak_stations' },
  },
}
