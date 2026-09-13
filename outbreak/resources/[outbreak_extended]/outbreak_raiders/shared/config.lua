RaiderCfg = {
  Models = { 'g_m_y_lost_01', 'g_m_y_lost_02', 'g_m_y_salvagoon_01', 'a_m_m_hillbilly_01' },
  Vehicles = { 'rebel', 'bodhi2', 'dloader', 'rancherxl' },
  MeleeWeapons = { `WEAPON_BAT`, `WEAPON_CROWBAR`, `WEAPON_KNUCKLE` },
  CrewSize = { 2, 3 },        -- per vehicle
  VehicleCount = { 1, 2 },
  -- Trigger: rolled server-side per driving player
  CheckMinutes = 6,           -- how often the director rolls
  ChanceWhileDriving = 0.25,  -- per roll
  MinSpeedKmh = 40,           -- only ambush moving targets
  CooldownMinutes = 15,       -- per player after a chase ends
  -- Chase behavior
  GiveUpDistance = 400.0,     -- you escaped
  GiveUpSeconds = 240,        -- they get bored
  DismountSpeedKmh = 15,      -- your car this slow = they bail out swinging
  -- Robbery
  RobSeconds = 8,             -- rummage time over your body
  MaxSlotsTaken = 4,
  Priority = { 'mre', 'canned_beans', 'water_clean', 'antibiotics', 'bandage', 'gas_can_small' },
  NeverTake = { 'radio_handheld', 'map_scrap' },  -- they leave you the radio. Sporting.
}
