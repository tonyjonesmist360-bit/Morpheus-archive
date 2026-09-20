HousingCfg = {
  OccupiedChance = 0.30,
  OccupantModels = { 'g_m_y_lost_01', 'a_m_m_hillbilly_01', 'g_m_y_salvagoon_01' },
  OccupantCount = { 1, 3 },
  BarricadeCost = { plank = 2, nails = 1 },
  MaxBarricadeLevel = 3,
  KeyItem = 'safehouse_key',       -- metadata.house = id; give the item = give access. No apps. No money.
  TapPerHour = 4,                  -- murky water from a claimed house's tap, per house, per real hour (the grid is down; so is the pressure)
  -- Every house has searchable spots (persistent cooldown via outbreak_items loot service) and,
  -- if the occupant roll misses, an environmental story shown on first entry.
  -- Exterior-only houses (no interior to enter) keep a door menu of these three.
  SearchSpots = { { name = 'Kitchen cupboards', table = 'house' }, { name = 'Bathroom cabinet', table = 'medical' }, { name = 'Bedroom drawers', table = 'house' } },
  -- INTERIOR SPOTS (v0.23 bugfix 3). Houses with an interior are searched INSIDE, at named spots that are
  -- ox_target zones ("Search kitchen counter"). Spots live in outbreak_house_spots; this seeds each interior
  -- on first boot with five spots spread around the entry anchor. Walk to the real counter / bed / cabinet and
  -- `/ob_spot <house_id> <table> <name>` to move one (same name = replace). Debug ace.
  InteriorSpotDefaults = {
    { name = 'Kitchen counter',     table = 'house',   dx =  3.0, dy =  2.0 },
    { name = 'Bedroom drawers',     table = 'house',   dx = -3.0, dy =  3.0 },
    { name = 'Bathroom cabinet',    table = 'medical', dx = -3.0, dy = -2.0 },
    { name = 'Living room shelves', table = 'house',   dx =  2.5, dy = -3.0 },
    { name = 'Office desk',         table = 'tools',   dx =  0.0, dy =  4.5 },
  },
  SpotRadius = 1.6,
  Stories = {
    'A calendar on the wall, every day crossed off until the 14th. Nothing after.',
    'Two plates on the table, one clean. A chair pushed back like someone left in a hurry.',
    'Kids\' drawings taped to the fridge. The newest one is just black crayon.',
    'A suitcase half-packed on the bed. They never got to finish.',
    'Dried blood on the door frame, at knee height. Then a trail. Then nothing.',
    'A note under a coffee mug: "Gone to Paleto. Don\'t wait. Love you." No name.',
    'The radio is on. Static. Someone was listening for something.',
  },
  StashSlots = 40, StashWeight = 100000,
  -- interior = nil -> exterior stash only. interior = vec4 -> teleport in/out (bob74_ipl enables these).
  Houses = {
    { id = 'paleto_shack',   door = vec3(-20.04, 6428.62, 31.44),   label = 'Paleto Shack' },
    { id = 'sandy_bungalow', door = vec3(1893.45, 3768.72, 32.94),  label = 'Sandy Shores Bungalow' },
    { id = 'grove_house',    door = vec3(-14.28, -1441.44, 31.10),  label = 'Grove St House',
      interior = vec4(-14.9, -1438.5, 31.1, 0.0) }, -- Franklin's Strawberry house (default IPL)
    { id = 'vinewood_flat',  door = vec3(324.72, 179.85, 103.59),   label = 'Vinewood Flat' },
    { id = 'trevor_trailer', door = vec3(1972.6, 3815.3, 33.43),    label = 'Sandy Trailer',
      interior = vec4(1975.0, 3820.4, 33.45, 180.0) }, -- Trevor's trailer
    { id = 'michael_house',  door = vec3(-815.8, 179.3, 72.16),     label = 'Rockford Hills Mansion',
      interior = vec4(-802.3, 175.0, 72.84, 110.0) },  -- Michael's house
    { id = 'lester_house',   door = vec3(1273.9, -1719.4, 54.77),   label = 'Murrieta Heights House',
      interior = vec4(1274.0, -1719.4, 54.77, 20.0) },  -- Lester's house
    { id = 'island_dock',    door = vec3(5000.0, -5750.0, 3.0),     label = 'The Far Dock (island)', preOwned = 'enclave' },
    { id = 'eclipse_apt',    door = vec3(-773.8, 312.9, 85.7),      label = 'Eclipse Towers Apt',
      interior = vec4(-773.0, 342.0, 196.7, 180.0) },   -- Eclipse Towers penthouse (default apartment IPL)
    -- v0.25: more doors to claim. Exterior-only (door menu + named spots). Coordinates from memory - unverified.
    { id = 'paleto_house',    door = vec3(-114.4, 6459.5, 31.5),   label = 'Paleto Bay House' },
    { id = 'grapeseed_farm',  door = vec3(2438.6, 4970.4, 46.8),   label = 'Grapeseed Farmhouse' },
    { id = 'harmony_house',   door = vec3(1099.9, 2723.6, 38.6),   label = 'Harmony Roadside House' },
    { id = 'sandy_trailer2',  door = vec3(1893.9, 3712.1, 32.8),   label = 'Sandy Trailer Park' },
    { id = 'vinewood_hills',  door = vec3(-1290.8, 454.6, 97.0),   label = 'Vinewood Hills House' },
    { id = 'mirror_park',     door = vec3(1256.3, -401.1, 69.0),   label = 'Mirror Park House' },
    { id = 'vespucci_flat',   door = vec3(-1150.9, -1521.1, 10.6), label = 'Vespucci Beach Flat' },
    { id = 'chumash_cabin',   door = vec3(-3033.4, 84.5, 11.6),    label = 'Chumash Cabin' },
    { id = 'prison_cells',    door = vec3(1697.0, 2565.0, 45.6),   label = 'Bolingbroke Cell Block', requires = 'pool:prison' },
  },
}
