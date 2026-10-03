EditorCfg = {
  Ace = 'outbreak.dm',
  Grid = { default = 0.5, steps = { 0, 0.25, 0.5, 1.0, 2.0 } },
  Cam = { speed = 0.35, fast = 1.2, slow = 0.08, sens = 3.0 },
  -- NPC palette: a starting set; anything typed in the model box also works (unverified names = no spawn + a note)
  Models = { 'a_m_m_farmer_01', 'a_m_y_hipster_01', 'a_f_y_tourist_01', 'a_m_m_hillbilly_01', 's_m_y_marine_03', 'g_m_y_lost_01', 's_m_m_doctor_01', 's_f_y_scrubs_01', 's_m_y_xmech_02', 'ig_lestercrest', 'ig_priest', 'a_m_o_tramp_01', 's_m_m_scientist_01', 's_m_m_armoured_01', 'a_f_m_fatcult_01', 'u_m_y_zombie_01' },
  Behaviours = { 'stand', 'wander', 'guard', 'patrol', 'sleep' },
  Stances = { 'friendly', 'neutral', 'hostile', 'military', 'raider', 'yard' },
  Scenarios = { stand = 'WORLD_HUMAN_STAND_IMPATIENT', guard = 'WORLD_HUMAN_GUARD_STAND', sleep = 'WORLD_HUMAN_BUM_SLUMPED', smoke = 'WORLD_HUMAN_SMOKING', sit = 'WORLD_HUMAN_PICNIC', weld = 'WORLD_HUMAN_WELDING', clipboard = 'WORLD_HUMAN_CLIPBOARD' },
  ZoneKinds = { safe = { mult = 0.0, colour = 2 }, infested = { mult = 2.5, colour = 1 }, territory = { colour = 5 }, loot = { bias = 1.5, colour = 46 }, quarantine = { mult = 1.5, colour = 59 } },
  -- the interaction vocabulary. The NUI shows these; the server runner executes them.
  Actions = { 'give', 'take', 'stash', 'say', 'notify', 'mission', 'flag', 'scene', 'transmit', 'spawn', 'rep', 'teleport', 'heal', 'learn_channel', 'noise', 'report' },
  Conditions = { 'item', 'rep', 'time', 'flag', 'settlement', 'once', 'cooldown', 'chapter', 'job' },
  Anims = { 'search', 'treat', 'repair', 'read', 'eat', 'drink', 'pulse', 'radio', 'pry', 'siphon', 'barricade' },
  NpcSpawnRadius = 150.0, NpcDespawnRadius = 220.0, HiddenSweepRadius = 120.0,
}
