CampCfg = {
  Camps = {
    { id = 'boneyard', pos = vec3(2395.9, 3111.2, 48.15), radius = 45.0, guards = 6, label = 'Boneyard Camp',   stash = 'camp_boneyard' },
    { id = 'quarry',   pos = vec3(2951.6, 2789.5, 41.0),  radius = 50.0, guards = 7, label = 'Quarry Camp',     stash = 'camp_quarry' },
    { id = 'pier',     pos = vec3(-1850.3, -1231.8, 8.6), radius = 40.0, guards = 5, label = 'Pier Camp',       stash = 'camp_pier' },
  },
  GuardModels = { 'g_m_y_lost_01', 'g_m_y_lost_03', 'g_m_m_armlieut_01', 'g_f_y_lost_01' },
  GuardWeapons = { `WEAPON_PUMPSHOTGUN`, `WEAPON_PISTOL`, `WEAPON_BAT`, `WEAPON_MACHETE` }, -- camps DO shoot. Chases don't.
  RespawnMinutes = 45,       -- camp regarrisons after being cleared
  Loot = { { 'mre', 4 }, { 'gas_can_small', 2 }, { 'car_battery', 1 }, { 'radio_battery', 4 }, { 'antibiotics', 2 }, { 'engine_parts', 1 }, { 'crowbar_tool', 1 }, { 'ammo-shotgun', 12 }, { 'ammo-9', 20 } },
  Convoy = {
    everyMinutes = { 30, 60 },
    from = { vec3(-1611.11, 2806.94, 17.05), vec3(1747.03, 3273.71, 41.13) }, -- Zancudo gate -> Sandy post and back
    vehicles = { 'barracks', 'crusader', 'insurgent2' },
    escorts = 2, cargoStash = 'convoy_cargo', cargoSlots = 12,
    cargo = { { 'mre', 8 }, { 'water_clean', 8 }, { 'bandage', 6 }, { 'antibiotics', 3 }, { 'radio_battery', 6 }, { 'ammo-rifle', 60 }, { 'weapon_kit', 1 } },
  },
}
