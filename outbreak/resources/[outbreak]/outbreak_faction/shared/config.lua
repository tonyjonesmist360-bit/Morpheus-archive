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
  -- POSTS (v0.25): where a faction physically is. A recruiter ped is the target (enlist / walk out / stash);
  -- guards stand around, shoot the dead, and ignore you unless you are the other side. Client-local peds,
  -- spawned inside SpawnRadius, removed beyond it. Models from memory - unverified.
  Posts = {
    military = { pos = vec4(-1611.1, 2806.9, 17.05, 0.0), recruiter = 's_m_y_marine_03', recruiterLabel = 'Sergeant',
                 guard = 's_m_y_marine_01', weapon = 'WEAPON_CARBINERIFLE', guards = { { 3.0, 2.0 }, { -3.5, 1.5 }, { 2.0, -4.0 }, { -2.5, -4.5 }, { 5.0, -1.0 } },
                 group = 'OUTBREAK_MIL' },
    raider   = { pos = vec4(1385.3, 3618.8, 34.98, 200.0), recruiter = 'g_m_y_lost_02', recruiterLabel = 'Warlord',
                 guard = 'g_m_y_lost_01', weapon = 'WEAPON_PUMPSHOTGUN', guards = { { 3.0, 2.0 }, { -3.0, 2.0 }, { 2.5, -3.5 }, { -3.0, -3.0 } },
                 group = 'OUTBREAK_RAIDERS' },
  },
  SpawnRadius = 180.0, DespawnRadius = 260.0, GuardSight = 70.0,
  -- Military-job players are allies of checkpoint soldiers; raider-job players are hostile to them.
  -- JOINING (v0.22): at the armory / the boneyard cache. Rep gates it; leaving costs rep with the ones you leave.
  Join = { minRep = -10, leaveRepCost = 25, cooldownMinutes = 30 },
  -- Standing words for the journal / F1. Bands on reputation -100..100.
  Standing = { { -40, 'hostile' }, { -1, 'wary' }, { 39, 'neutral' }, { 79, 'trusted' }, { 100, 'kin' } },
  Names = { military = 'Military Remnant', raider = 'Boneyard raiders', enclave = 'The Enclave', mechanics = 'The Yard (mechanics)' },
  Blurbs = {
    military = 'What is left of Zancudo. Channel 7. They hold the gate and the armory, and they remember who helped.',
    raider   = 'The Boneyard crew out of Sandy Shores. Channel 13. They take what they want and call it trade.',
    enclave  = 'The settlements that talk to each other on channel 4. Doors, stockpiles, people who remember your name.',
    mechanics = 'Beeker\'s Garage at Harmony, still turning wrenches. Channel 9. Bring them cars and they will keep yours running - for free, if they like you.',
  },
}
