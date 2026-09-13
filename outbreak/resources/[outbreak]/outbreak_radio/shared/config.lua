RadioCfg = {
  -- Range model. Quality 0..1 between two radios on the same channel; below Floor you hear static, not words.
  Handheld = { range = 1500.0 },          -- metres
  Base     = { range = 6000.0, item = 'radio_base' },   -- placed in a claimed safehouse (radio room)
  Floor = 0.15,
  Weather = { RAIN = -0.15, THUNDER = -0.30, FOGGY = -0.05 },
  HeightBonusPer100m = 0.05,              -- the higher of the two radios lifts quality
  RecomputeSeconds = 5,
  -- Repeaters: coverage circles. 'active' persists (outbreak_repeaters). Both radios inside one active repeater = near-perfect.
  Repeaters = {
    chiliad = { label = 'Mount Chiliad repeater', pos = vec3(501.0, 5604.0, 797.9), radius = 9000.0, defaultActive = false, quality = 0.95 },
    zancudo = { label = 'Fort Zancudo mast',      pos = vec3(-2320.0, 3390.0, 32.0), radius = 2500.0, defaultActive = true,  quality = 0.85, military = true }, -- only for the military faction net
    cayo    = { label = 'The lighthouse (island)', pos = vec3(4530.0, -4880.0, 5.0),   radius = 14000.0, defaultActive = false, quality = 0.9 },  -- lit by chain 5: links the island to the mainland
  },
  Static = { sound = nil }, -- TODO audio; text garbling only for now
}
