StationCfg = {
  -- State rolled deterministically per station from its id on server start (persisted in DB after Phase E)
  Weights = { dry = 0.55, trickle = 0.30, deadpump = 0.15 },
  TrickleYield = { 8, 22 },      -- percent per pull, then dry for TrickleRechargeHours
  TrickleRechargeHours = 6,
  DeadPumpItem = 'car_battery',  -- power the pump once -> becomes 'trickle'
  PumpSeconds = 10,
  Stations = {
    { id = 'ltd_grove',     pos = vec3(-47.0, -1757.5, 29.42),   label = 'LTD Grove St' },
    { id = 'ron_ocean',     pos = vec3(-2096.6, -320.0, 13.17),  label = 'RON Great Ocean Hwy' },
    { id = 'xero_lsia',     pos = vec3(-724.6, -935.3, 19.21),   label = 'Xero Little Seoul' },
    { id = 'ltd_mirror',    pos = vec3(1181.4, -330.9, 69.32),   label = 'LTD Mirror Park' },
    { id = 'ron_route68',   pos = vec3(1207.3, 2660.2, 37.90),   label = 'RON Route 68' },
    { id = 'ltd_sandy',     pos = vec3(1701.3, 6416.5, 32.76),   label = 'LTD Paleto Hwy' },
    { id = 'xero_sandy',    pos = vec3(1981.3, 3771.5, 32.18),   label = 'Xero Sandy Shores' },
    { id = 'globe_paleto',  pos = vec3(179.9, 6602.8, 31.87),    label = 'Globe Oil Paleto' },
    { id = 'ron_harmony',   pos = vec3(264.2, 2606.1, 44.98),    label = 'RON Harmony' },
    { id = 'ltd_davis',     pos = vec3(-64.3, -2000.9, 18.02),   label = 'LTD Davis Ave' },
  },
  -- Station shop-loot: search the register / back room
  Loot = { { 'water_clean', 1, 2, 0.40 }, { 'canned_beans', 1, 1, 0.25 }, { 'duct_tape', 1, 1, 0.15 }, { 'hose_kit', 1, 1, 0.10 }, { 'radio_battery', 1, 1, 0.12 }, { 'gas_can_small', 1, 1, 0.08 } },
}
