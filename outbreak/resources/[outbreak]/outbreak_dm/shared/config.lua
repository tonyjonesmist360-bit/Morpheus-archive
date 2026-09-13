DMCfg = {
  Ace = 'outbreak.dm',
  -- NAMED NPCs. Story-mode and unique models, so a recurring character is recognisable
  -- instead of being another random citizen. Spawn via Director -> Spawn -> Survivors.
  -- EVERY model here is unverified until /ob_models says otherwise - check before trusting.
  NamedNPCs = {
    { id = 'quartermaster', label = 'The Quartermaster',  model = 's_m_m_armoured_01', role = 'barter at Sandy airfield' },
    { id = 'doc',           label = 'The Doctor',         model = 's_m_m_doctor_01',   role = 'station treatment' },
    { id = 'mechanic',      label = 'The Mechanic',       model = 's_m_y_xmech_02',    role = 'vehicle repair' },
    { id = 'fixer',         label = 'The Fixer',          model = 'ig_lestercrest',    role = 'intel and leads' },
    { id = 'preacher',      label = 'The Preacher',       model = 'ig_priest',         role = 'camp morale' },
    { id = 'raider_boss',   label = 'Raider Warlord',     model = 'g_m_y_lost_01',     role = 'antagonist' },
    { id = 'colonel',       label = 'The Colonel',        model = 's_m_y_marine_03',   role = 'military remnant' },
    { id = 'scavenger',     label = 'Old Scavenger',      model = 'a_m_o_tramp_01',    role = 'rumours, trades scrap' },
    { id = 'nurse',         label = 'Field Nurse',        model = 's_f_y_scrubs_01',   role = 'camp medic' },
    { id = 'radio_op',      label = 'Radio Operator',     model = 's_m_m_scientist_01',role = 'repeater chain' },
  },
  Peds = { survivor = { 'a_m_y_hipster_01', 'a_f_y_tourist_01', 'a_m_m_farmer_01' }, raider = { 'g_m_y_lost_01', 'g_m_y_lost_02', 'g_m_y_salvagoon_01' }, military = { 's_m_y_marine_01', 's_m_y_marine_03' } },
  Vehicles = { 'rebel', 'bodhi2', 'barracks', 'crusader', 'ambulance', 'towtruck', 'pbus', 'dloader', 'sanchez', 'dinghy' },
  Weathers = { 'CLEAR', 'CLOUDS', 'OVERCAST', 'FOGGY', 'RAIN', 'THUNDER', 'CLEARING' },
  -- SCENE PRESETS: author these. Each step is a DM action run in order at (or relative to) the DM's position.
  -- actions: horde{size}, peds{kind,count,hostile,weapon}, vehicle{model,managed}, props{...}, cache{items}, radio{ch,title,text,range}, weather, time, item{name,count}, note{text}, wait{seconds}
  Scenes = {
    heli_crash = { label = 'Helicopter crash', steps = {
      { action = 'props', list = { { 'prop_rub_carwreck_2', 0, 0 }, { 'prop_barrier_work05', 4, 2 }, { 'prop_rub_flotsam_03', -3, 3 } } },
      { action = 'radio', ch = 0, title = 'MAYDAY', text = '...going down... going down... anyone... *static*', range = 4000.0 },
      { action = 'cache', items = { { 'mre', 4 }, { 'antibiotics', 2 }, { 'ammo-rifle', 40 }, { 'radio_battery', 3 } }, label = 'Wreckage' },
      { action = 'peds', kind = 'military', count = 2, hostile = false, weapon = 'WEAPON_CARBINERIFLE', dead = true },
      { action = 'wait', seconds = 45 },
      { action = 'horde', size = 18 },
    } },
    survivor_family = { label = 'Family needs medicine', steps = {
      { action = 'peds', kind = 'survivor', count = 3, hostile = false, line = 'Please — she\'s burning up. Antibiotics. Anything.' },
      { action = 'note', text = 'IF YOU FIND US: WE WENT NORTH. WATER TOWER. — R.' },
    } },
    raider_roadblock = { label = 'Raider roadblock', steps = {
      { action = 'props', list = { { 'prop_barrier_work05', 0, 0 }, { 'prop_barrier_work05', 3, 0 }, { 'prop_rub_carwreck_5', -4, 1 } } },
      { action = 'vehicle', model = 'rebel', offset = { 6, -3 } },
      { action = 'peds', kind = 'raider', count = 4, hostile = true, weapon = 'WEAPON_PUMPSHOTGUN' },
      { action = 'radio', ch = 13, title = 'RAIDER NET', text = 'Roadblock\'s up. Nobody passes without paying.', range = 3000.0 },
    } },
    supply_drop = { label = 'Military supply drop', steps = {
      { action = 'radio', ch = 7, title = 'MILITARY NET', text = 'Drop inbound. Coordinates follow. Secure it before the locals do.', range = 9000.0 },
      { action = 'cache', items = { { 'mre', 10 }, { 'water_clean', 10 }, { 'bandage', 8 }, { 'ammo-rifle', 90 }, { 'weapon_kit', 1 } }, label = 'Supply Drop', model = 'prop_box_wood04a' },
      { action = 'wait', seconds = 120 },
      { action = 'peds', kind = 'military', count = 3, hostile = false, weapon = 'WEAPON_CARBINERIFLE' },
    } },
    night_of_fire = { label = 'Night of fire (weather + horde surge)', steps = {
      { action = 'time', hour = 23 }, { action = 'weather', type = 'THUNDER' },
      { action = 'radio', ch = 0, title = 'EMERGENCY BROADCAST', text = 'Movement on every road. Get inside. Get inside now.', range = 0 },
      { action = 'horde', size = 30 },
    } },
  },
}
