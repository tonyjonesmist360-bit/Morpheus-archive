OutbreakCfg = {
  -- GTA V ships ONE unambiguous zombie ped. Everything else here is a derelict human whose
  -- silhouette already reads wrong, and DamagePacks below is what actually sells "infected".
  -- Entries may be a plain string or { model = '...', weight = n }; weight defaults to 10.
  ZombieModels = {
    { model = 'u_m_y_zombie_01',  weight = 55 },  -- the only real zombie model in the base game
    { model = 'a_m_m_skidrow_01', weight = 12 },
    { model = 'a_m_o_tramp_01',   weight = 10 },
    { model = 'a_f_m_trampbeac_01', weight = 8 },
    { model = 'a_m_m_hillbilly_02', weight = 8 },
    { model = 's_m_y_autopsy_01', weight = 7 },   -- morgue attendant: reads as a corpse that got up
  },
  -- Blood and wounds applied to every zombie on spawn. A bad pack name is a silent no-op,
  -- never an error, so this list is safe to experiment with. Set to {} to disable.
  DamagePacks = { 'BigHitByVehicle', 'SCR_Dumpster', 'Explosion_Med', 'Skin_Melee_Cuts' },
  MaxPerPlayer = 12,            -- ambient zombies around each player
  SpawnRadius = { min = 45, max = 120 },
  DespawnRadius = 180.0,
  NightMultiplier = 1.6,        -- more zombies 22:00-05:00
  HeadshotOnly = false,         -- true = only headshots kill (TODO hook)
  InfectionChancePerHit = 0.15, -- Zomboid-style: every hit rolls
  AggroRadius = 30.0,           -- sight range
  HearGunshotRadius = 90.0,     -- gunfire pulls zombies
  WalkStyles = { 'move_m@injured' },  -- BISECT 2: verydrunk alone did NOT lurch, so it is the bad name
  Hordes = { enabled = true, minInterval = 20, maxInterval = 45, size = 25, announceOnRadio = true },
  -- MOB AREAS. Density multiplier and variant bias by place. radius in metres.
  -- Safehouses are deliberately placed outside these, so a base stays approachable.
  HotZones = {
    { id = 'downtown',    pos = vec3(  195.0, -890.0,  30.7), radius = 400.0, mult = 2.2, bias = 'shambler' },
    { id = 'vinewood',    pos = vec3(  290.0,  180.0, 104.0), radius = 300.0, mult = 1.8, bias = 'shambler' },
    { id = 'lsia',        pos = vec3(-1030.0,-2730.0,  13.8), radius = 350.0, mult = 1.9, bias = 'runner'   },
    { id = 'pillbox',     pos = vec3(  310.0, -560.0,  43.3), radius = 200.0, mult = 2.0, bias = 'shambler' },
    { id = 'sandy_town',  pos = vec3( 1960.0, 3740.0,  32.3), radius = 250.0, mult = 1.4, bias = 'shambler' },
    { id = 'paleto_town', pos = vec3(  -180.0,6350.0,  31.5), radius = 220.0, mult = 1.3, bias = 'shambler' },
    { id = 'prison',      pos = vec3( 1700.0, 2590.0,  45.6), radius = 260.0, mult = 2.4, bias = 'runner'   },
    { id = 'humane_labs', pos = vec3( 3620.0, 3740.0,  28.7), radius = 240.0, mult = 2.0, bias = 'bloater'  },
    -- Quiet by design: the outskirts, so there is somewhere to breathe.
    { id = 'grapeseed',   pos = vec3( 1700.0, 4780.0,  42.0), radius = 250.0, mult = 0.5 },
    { id = 'chiliad',     pos = vec3(  430.0, 5610.0, 766.0), radius = 400.0, mult = 0.3 },
  },
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
