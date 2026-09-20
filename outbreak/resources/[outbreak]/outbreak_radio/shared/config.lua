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
  -- v2 (2026-09-14): the walkie as an object. All client-side presentation; the range model above stays the authority.
  ScreenUI = true,              -- our own radio screen (NUI) instead of mm_radio / an input dialog
  PreferMMRadio = false,        -- true = hand off to mm_radio when it is running
  Submix = true,                -- push remote radio voices through GTA's radio-FX submix (the distortion)
  IndoorsIsDead = true,         -- inside an interior = no signal (GetInteriorFromEntity ~= 0)
  IndoorFactor = 0.3,           -- quality multiplier when either side is indoors / in a dead zone
  DeadZones = {                 -- tunnels and holes. Coordinates from memory: verify by walking them with the screen open.
    { label = 'the LS freeway tunnel', pos = vec3(-1145.0, -1020.0, 0.0), radius = 120.0 },
    { label = 'the Braddock tunnel',   pos = vec3(-2270.0, 2540.0, 5.0),  radius = 200.0 },
  },
  Sfx = { click = 0.7, hiss = 0.45, weak = 0.55 },
  -- CHANNELS (v0.25). A radio powers up on the EMERGENCY channel. Other channels must be found: a scan
  -- (S on the screen) picks one that is live (someone on it, a faction net, main comms), a faction hands
  -- you its net when you join, a repeater you light gives you its channel. Up/down step known channels only.
  Channels = { emergency = 1, main = 4, KnownAtStart = { 1 }, Scan = { seconds = 4, chance = 0.85, always = { 4 } } },
  TagRange = 25.0,              -- metres: draw "((radio))" over a transmitting player this close
  BatteryHeartbeats = 9,        -- heartbeats (5 min each) per battery = 45 min
}
