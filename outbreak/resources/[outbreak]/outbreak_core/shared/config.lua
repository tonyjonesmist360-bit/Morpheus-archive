OutbreakCfg = {
  ZombieModels = { 'u_m_y_zombie_01', 'a_m_m_hillbilly_02', 'a_m_m_skidrow_01', 'a_f_m_trampbeac_01', 'a_m_o_tramp_01' },
  MaxPerPlayer = 12,            -- ambient zombies around each player
  SpawnRadius = { min = 45, max = 120 },
  DespawnRadius = 180.0,
  NightMultiplier = 1.6,        -- more zombies 22:00-05:00
  HeadshotOnly = false,         -- true = only headshots kill (TODO hook)
  InfectionChancePerHit = 0.15, -- Zomboid-style: every hit rolls
  AggroRadius = 30.0,           -- sight range
  HearGunshotRadius = 90.0,     -- gunfire pulls zombies
  WalkStyles = { 'move_m@drunk@verydrunk', 'move_m@injured' },
  Hordes = { enabled = true, minInterval = 20, maxInterval = 45, size = 25, announceOnRadio = true },
  -- Variants: weight = spawn share. Runners only after dark.
  Variants = {
    shambler = { weight = 70, models = nil },   -- uses ZombieModels
    runner   = { weight = 15, models = { 'a_m_y_runner_01', 'a_f_y_runner_01' }, nightOnly = true, moveRate = 1.35, health = 140 },
    bloater  = { weight = 10, models = { 'a_m_m_genfat_01', 'a_m_m_genfat_02' }, moveRate = 0.8, health = 320, burst = true, burstInfect = 0.5 },
    screamer = { weight = 5,  models = { 'a_f_y_hippie_01', 'a_m_y_hippy_01' }, moveRate = 1.0, health = 100, callsHorde = 8 },
  },
  -- Weather with teeth (reads outbreak_world's GlobalState.obWeather)
  Weather = {
    RAIN     = { noiseMult = 0.6,  spawnMult = 1.0 },   -- rain masks you
    THUNDER  = { noiseMult = 0.5,  spawnMult = 1.2, frenzy = true }, -- but thunder agitates them
    FOGGY    = { noiseMult = 1.0,  spawnMult = 1.5 },   -- they come out of nowhere
    OVERCAST = { noiseMult = 1.0,  spawnMult = 1.1 },
  },
}
