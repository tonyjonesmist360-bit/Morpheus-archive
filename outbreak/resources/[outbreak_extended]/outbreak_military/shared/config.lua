MilCfg = {
  Models = { 's_m_y_marine_01', 's_m_y_marine_03', 's_m_m_marine_02' },
  Weapon = `WEAPON_CARBINERIFLE`,
  WarnRadius = 25.0,        -- verbal warning zone
  FireIfArmedRadius = 15.0, -- approach armed = hostile
  Checkpoints = {
    { id = 'zancudo_gate',  pos = vec4(-1611.11, 2806.94, 17.05, 34.0),  guards = 4, label = 'Fort Zancudo Gate' },
    { id = 'lsia_bridge',   pos = vec4(-1042.87, -2745.65, 21.36, 240.0),guards = 3, label = 'LSIA Quarantine' },
    { id = 'sandy_airfield',pos = vec4(1747.03, 3273.71, 41.13, 195.0),  guards = 3, label = 'Sandy Airfield Post' },
  },
  SpawnDistance = 150.0,
  -- The Quartermaster: barter-only trading at Sandy Airfield. give -> get.
  Trader = {
    checkpoint = 'sandy_airfield',
    ped = 's_m_m_marine_01',
    offset = vec4(1743.5, 3270.2, 41.13, 195.0),
    Trades = {
      { give = { 'canned_beans', 3 },  get = { 'antibiotics', 1 },   label = '3 canned goods -> antibiotics' },
      { give = { 'water_clean', 2 },   get = { 'mre', 1 },           label = '2 clean waters -> military ration' },
      { give = { 'gas_can_small', 1 }, get = { 'radio_battery', 2 }, label = 'fuel can -> 2 radio batteries' },
      { give = { 'engine_parts', 1 },  get = { 'bandage', 3 },       label = 'engine parts -> 3 bandages' },
      { give = { 'map_scrap', 1 },     get = { 'purify_tabs', 2 },   label = 'intel (map scrap) -> purification tabs' },
      { give = { 'engine_parts', 3 },  get = { 'bus_alternator', 1 }, label = '3 engine parts -> heavy alternator (bus-grade)' },
      { give = { 'radio_battery', 4 }, get = { 'radio_coil', 1 },     label = '4 radio batteries -> radio coil' },
    },
  },
}
