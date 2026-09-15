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
  -- Admin spawn list: { model, label }. Base-game models only (no DLC) so every one exists on a stock
  -- server; add DLC models freely. "Spawn by model name" takes anything. Model names from memory - unverified.
  Vehicles = {
    -- pickups / offroad
    { 'rebel', 'Rebel (rusty pickup)' }, { 'rebel2', 'Rebel (clean)' }, { 'bodhi2', 'Bodhi (open pickup)' }, { 'sadler', 'Sadler (work pickup)' }, { 'bison', 'Bison' }, { 'bobcatxl', 'Bobcat XL' },
    { 'rancherxl', 'Rancher XL' }, { 'sandking', 'Sandking (lifted)' }, { 'sandking2', 'Sandking XL' }, { 'mesa', 'Mesa' }, { 'mesa3', 'Mesa (off-road)' }, { 'dloader', 'Duneloader (dune buggy)' }, { 'bfinjection', 'BF Injection' },
    { 'dubsta3', 'Dubsta 6x6' }, { 'guardian', 'Guardian (heavy pickup)' }, { 'kalahari', 'Kalahari (jeep)' },
    -- suvs / cars
    { 'seminole', 'Seminole (SUV)' }, { 'baller', 'Baller' }, { 'cavalcade', 'Cavalcade' }, { 'granger', 'Granger' }, { 'patriot', 'Patriot' }, { 'dubsta', 'Dubsta' }, { 'landstalker', 'Landstalker' }, { 'gresley', 'Gresley' }, { 'habanero', 'Habanero' },
    { 'asea', 'Asea (sedan)' }, { 'premier', 'Premier' }, { 'emperor', 'Emperor' }, { 'emperor2', 'Emperor (rusty)' }, { 'washington', 'Washington' }, { 'stanier', 'Stanier' }, { 'ingot', 'Ingot (wagon)' }, { 'regina', 'Regina (wagon)' }, { 'blista', 'Blista (hatch)' }, { 'issi2', 'Issi' }, { 'dilettante', 'Dilettante' },
    { 'surfer', 'Surfer (VW bus)' }, { 'surfer2', 'Surfer (rusty)' }, { 'journey', 'Journey (RV)' }, { 'camper', 'Camper (RV)' }, { 'taco', 'Taco van' },
    -- vans / trucks
    { 'youga', 'Youga (van)' }, { 'burrito3', 'Burrito (van)' }, { 'rumpo', 'Rumpo (van)' }, { 'speedo', 'Speedo (van)' }, { 'pony', 'Pony (van)' }, { 'boxville', 'Boxville (box truck)' }, { 'mule', 'Mule (box truck)' }, { 'benson', 'Benson (box truck)' },
    { 'pounder', 'Pounder' }, { 'phantom', 'Phantom (semi)' }, { 'hauler', 'Hauler (semi)' }, { 'packer', 'Packer (semi)' }, { 'tanker', 'Tanker trailer' }, { 'trailers', 'Box trailer' },
    { 'towtruck', 'Tow truck' }, { 'towtruck2', 'Tow truck (small)' }, { 'flatbed', 'Flatbed' }, { 'scrap', 'Scrap truck' }, { 'utillitruck', 'Utility truck' }, { 'utillitruck3', 'Utility truck (small)' }, { 'tiptruck', 'Tipper' }, { 'mixer', 'Cement mixer' }, { 'rubble', 'Rubble' }, { 'tractor2', 'Tractor' }, { 'trash', 'Garbage truck' },
    -- service / emergency
    { 'ambulance', 'Ambulance' }, { 'firetruk', 'Fire truck' }, { 'police', 'Police cruiser' }, { 'police2', 'Police (Buffalo)' }, { 'police3', 'Police (Interceptor)' }, { 'sheriff', 'Sheriff cruiser' }, { 'sheriff2', 'Sheriff SUV' }, { 'policet', 'Police transporter' }, { 'riot', 'Riot van' },
    { 'pbus', 'Prison bus' }, { 'bus', 'City bus' }, { 'coach', 'Coach' }, { 'rentalbus', 'Rental bus' }, { 'tourbus', 'Tour bus' }, { 'airbus', 'Airport bus' },
    -- military
    { 'barracks', 'Barracks (troop truck)' }, { 'barracks2', 'Barracks (semi)' }, { 'barracks3', 'Barracks (short)' }, { 'crusader', 'Crusader (jeep)' }, { 'insurgent', 'Insurgent (turret)' }, { 'insurgent2', 'Insurgent (no turret)' }, { 'technical', 'Technical (gun truck)' }, { 'brickade', 'Brickade (armoured)' }, { 'stockade', 'Stockade (armoured van)' },
    -- bikes
    { 'sanchez', 'Sanchez (dirt bike)' }, { 'sanchez2', 'Sanchez (livery)' }, { 'enduro', 'Enduro' }, { 'bati', 'Bati 801' }, { 'hexer', 'Hexer (chopper)' }, { 'daemon', 'Daemon (chopper)' }, { 'blazer', 'Blazer (quad)' }, { 'bagger', 'Bagger' }, { 'faggio', 'Faggio (scooter)' },
    { 'bmx', 'BMX' }, { 'cruiser', 'Cruiser bicycle' }, { 'scorcher', 'Scorcher (mountain bike)' }, { 'fixter', 'Fixter (road bike)' },
    -- boats
    { 'dinghy', 'Dinghy' }, { 'dinghy2', 'Dinghy (2-seat)' }, { 'suntrap', 'Suntrap' }, { 'seashark', 'Seashark (jetski)' }, { 'speeder', 'Speeder' }, { 'jetmax', 'Jetmax' }, { 'squalo', 'Squalo' }, { 'tug', 'Tug' }, { 'marquis', 'Marquis (sailboat)' }, { 'predator', 'Police boat' },
  },
  -- Saved teleport locations for the admin menu. Add your own with /coords (copies a vec4 to the clipboard).
  Locations = {
    { label = 'Sandy Shores motel (spawn)', pos = vec4(1961.24, 3742.4, 32.34, 300.0) },
    { label = 'Sandy Medical',              pos = vec4(1839.6, 3672.93, 34.28, 210.0) },
    { label = 'Sandy bungalow (safehouse)', pos = vec4(1893.45, 3768.72, 32.94, 0.0) },
    { label = 'Grove St house',             pos = vec4(-14.28, -1441.44, 31.10, 0.0) },
    { label = 'Pillbox triage',             pos = vec4(298.83, -584.77, 43.26, 70.0) },
    { label = 'Paleto clinic',              pos = vec4(-247.76, 6331.23, 32.43, 305.0) },
    { label = 'Zancudo gate',               pos = vec4(-1611.11, 2806.94, 17.05, 0.0) },
    { label = 'LSIA overpass (spawn)',      pos = vec4(-1037.6, -2737.5, 20.17, 240.0) },
  },
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
