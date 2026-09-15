VehCfg = {
  -- Deterministic first-seen roll (plate+model), server-side. These are the 'live' numbers;
  -- the active ERA below overrides them.
  LockedChance = 0.55, DeadBatteryChance = 0.40, FuelRange = { 2, 35 }, KeyInGloveboxChance = 0.15, MissingPartChance = 0.20,
  -- ERA: how the world's cars are found.
  --   early = the outbreak just happened. Most cars run, most have fuel, half still have the keys in them.
  --   live  = months in. Locked, dead, dry, stripped. The scavenging game.
  -- Boot default comes from `setr ob_veh_era early` in server.cfg (early if unset). Switch at runtime
  -- from the DM Vehicle kit or `ob_vehera live` in the txAdmin console. Only cars seen for the FIRST
  -- time after the switch roll the new era; a restart re-rolls every unclaimed car.
  Eras = {
    early = { LockedChance = 0.15, DeadBatteryChance = 0.10, MissingPartChance = 0.05, FuelRange = { 30, 80 }, KeyInGloveboxChance = 0.35, KeysInIgnitionChance = 0.60 },
    live  = { LockedChance = 0.55, DeadBatteryChance = 0.40, MissingPartChance = 0.20, FuelRange = { 2, 35 },  KeyInGloveboxChance = 0.15, KeysInIgnitionChance = 0.0 },
  },
  -- Items
  KeyItem = 'vehicle_key', LockpickItem = 'crowbar_tool', BatteryItem = 'car_battery', SiphonItem = 'hose_kit', RepairItem = 'engine_parts', CanItem = 'gas_can_small',
  -- Burn: percent of tank per real minute at 60 km/h, scaled by speed and class; idling burns 25%
  BurnPerMinute = 1.4, IdleFactor = 0.25,
  -- Class profiles: noise multiplier for outbreak_noise, burn multiplier, seats hint
  Classes = {
    [0] = { noise = 1.0, burn = 1.0 },  -- compacts
    [1] = { noise = 1.0, burn = 1.1 },  -- sedans
    [2] = { noise = 1.1, burn = 1.3 },  -- suvs
    [4] = { noise = 1.3, burn = 1.5 },  -- muscle
    [8] = { noise = 1.4, burn = 0.8 },  -- motorcycles
    [9] = { noise = 1.2, burn = 1.4 },  -- offroad
    [10] = { noise = 1.5, burn = 2.2 }, -- industrial
    [11] = { noise = 1.3, burn = 1.8 }, -- utility
    [12] = { noise = 1.3, burn = 1.6 }, -- vans
    [17] = { noise = 1.4, burn = 2.0 }, -- service (buses)
    [19] = { noise = 1.6, burn = 2.5 }, -- military
    [20] = { noise = 1.6, burn = 2.4 }, -- commercial
    [14] = { noise = 1.3, burn = 1.8, boat = true }, -- boats: marine fuel only
  },
  MarineCanItem = 'marine_fuel_can', MarinePartItem = 'engine_parts',
  -- Managed boats spawned at marinas on start (wrecks, unclaimed, deterministic state)
  Marinas = {
    { id = 'chumash', model = 'dinghy',   pos = vec3(-3427.6, 967.3, 8.3),  heading = 90.0,  plate = 'CHUMASH1' },
    { id = 'lsmarina', model = 'suntrap', pos = vec3(-786.0, -1340.0, 1.6), heading = 130.0, plate = 'LSMAR001' },
    { id = 'paleto',  model = 'dinghy',   pos = vec3(-1596.3, 5254.4, 2.1), heading = 20.0,  plate = 'PALETO01' },
  },
  Storm = { burnMult = 2.0, weathers = { THUNDER = true } },   -- boats in a storm drink fuel; the island chain refuses to depart
  SiphonYield = { 5, 20 }, PourMax = 100,
  Persistence = { claimedOnly = true, respawnOnStart = true }, -- claimed = a key exists for it
  DragOut = { enabled = true, idleSeconds = 6, dragChance = 0.5 },
}
