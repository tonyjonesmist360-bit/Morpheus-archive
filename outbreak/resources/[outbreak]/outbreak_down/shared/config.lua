DownCfg = {
  -- UNCONSCIOUS: melee, fists, zombie swipes. You wake up.
  Unconscious = {
    seconds = 120,           -- wake naturally after this
    wakeHealthPct = 35,      -- wake with this much health
    shakeWakeSeconds = 8,    -- another player can shake you awake
  },
  -- INCAPACITATED: bullets, explosions, falls, vehicle impacts, critical infection.
  Incapacitated = {
    bleedOutSeconds = 300,   -- 5 min to bleed out (was 10; 2026-09-14 build sheet)
    stabilizeItem = 'bandage',
    selfStabilize = true,        -- solo-play lifeline
    selfStabilizeItem = 'splint',-- costs more when doing it yourself
    selfStabilizeSeconds = 20,
    stabilizeHealthPct = 20,
  },
  SecondDownWindow = 300,    -- unconscious twice within 5 min = incapacitated
  -- Death is a PIPELINE, not an event:
  --   unconscious -> incapacitated (bleed-out) -> CRITICAL (someone must get you to a medical station) -> permadeath
  -- A glitch or a fall drops you into the pipeline, never straight to the wall.
  Critical = {
    minutes = 30,                    -- the golden hour (real minutes) to reach a station
    treatItems = { { 'bandage', 2 }, { 'antibiotics', 1 } },   -- what the treating player spends
    baseChance = 0.70,               -- + medicine level * 0.03 of the treater
    failCutsTimerBy = 0.5,           -- a failed attempt halves the remaining time; it does not kill
    recoveringHours = 2,             -- after a station save: slowed, no sprint
    Stations = {
      { id = 'pillbox', label = 'Pillbox Triage',   pos = vec3(307.7, -595.2, 43.28), radius = 6.0 },
      { id = 'sandy',   label = 'Sandy Medical',    pos = vec3(1839.6, 3672.9, 34.28), radius = 6.0 },
      { id = 'paleto',  label = 'Paleto Clinic',    pos = vec3(-247.8, 6331.2, 32.43), radius = 6.0 },
    },
  },
  Adrenaline = { item = 'adrenaline_shot', healthPct = 10, fatigueCost = 40 }, -- solo lifeline, works ONLY while incapacitated
  -- 'permadeath' = the full pipeline above; new character at the end of it. Corpse stays lootable, name on the wall.
  -- 'losegear'   = same character, empty pockets.   'keep' = softcore.
  DeathMode = 'permadeath',
  PvP = true,                -- players can search/rob downed players
  CorpseProp = `prop_cs_body_bag`,   -- (used by the corpse marker; zombies eat the rest)
  CorpseHours = 24,
  Respawn = {
    loseInventory = false,   -- (only read in 'losegear' mode)
    points = {               -- "you were dragged somewhere..."
      vec4(298.83, -584.77, 43.26, 70.0),   -- Pillbox exterior triage
      vec4(1839.6, 3672.93, 34.28, 210.0),  -- Sandy medical
      vec4(-247.76, 6331.23, 32.43, 305.0), -- Paleto clinic
    },
  },
}
