FactionCfg = {
  Military = {
    job = 'military',
    radioChannel = 7,                          -- their private net
    Armory = { coords = vec3(-2359.5, 3248.9, 32.81), stash = 'mil_armory', slots = 60, weight = 250000 },
    Uniform = { -- illenium-appearance outfit name, applied via its export if present
      name = 'military_fatigues',
    },
    -- Gear the armory is seeded with on first boot (server clears nothing after)
    Seed = { { 'mre', 20 }, { 'water_clean', 20 }, { 'bandage', 15 }, { 'antibiotics', 4 }, { 'radio_handheld', 6 }, { 'radio_battery', 12 } },
  },
  Raider = {
    job = 'raider',
    radioChannel = 13,
    Camp = { coords = vec3(1385.3, 3618.8, 34.98), stash = 'raider_cache', slots = 40, weight = 150000 }, -- Sandy Shores boneyard
  },
  -- Military-job players are allies of checkpoint soldiers; raider-job players are hostile to them.
}
