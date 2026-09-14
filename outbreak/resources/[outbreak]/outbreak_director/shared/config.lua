-- outbreak_director/shared/config.lua
DirectorCfg = {
  EveryMinutes = { 30, 60 },     -- one evaluation pass, scheduled through outbreak_core (only while someone is online)
  Channel = 0,                   -- 0 = anyone with a powered radio on any channel hears it (outbreak_radio semantics)
  ProbeSize = 8, ProbeRange = 200.0, ProbeMorale = { held = 4, failed = -3 },
  StrangerExpireMinutes = 10,
  -- Every model here is unverified until /ob_models says otherwise. These four are already used by outbreak_dm / outbreak_housing.
  StrangerModels = { 'a_m_y_hipster_01', 'a_f_y_tourist_01', 'a_m_m_farmer_01', 'a_m_m_hillbilly_01' },
  -- Per settlement, per action. Minutes. 'quiet' and 'nothing' are the pass doing nothing, on purpose.
  Cooldowns = { stranger = 90, rumor_food = 60, rumor_medicine = 90, probe = 120, unrest = 45, trader = 180, safehouse = 90, quiet = 0, nothing = 0 },
  Weights   = { stranger = 40, rumor_food = 35, rumor_medicine = 30, probe = 25, unrest = 20, trader = 10, quiet = 30, nothing = 15 },
  -- Rumours point at real places. Coordinates are only used to pick the one nearest the settlement; the label is what the player hears.
  Rumors = {
    food = {
      { label = 'the 24/7 on Alhambra in Sandy Shores', pos = vec3(1960.5, 3740.6, 32.3) },
      { label = 'the store up in Grapeseed',            pos = vec3(1698.4, 4924.4, 42.1) },
      { label = 'the 24/7 in Paleto',                   pos = vec3(1729.2, 6414.9, 35.0) },
      { label = 'the LTD on Route 68',                  pos = vec3(1165.1, 2709.6, 38.2) },
      { label = 'the Strawberry 24/7',                  pos = vec3(25.7, -1347.3, 29.5) },
    },
    medicine = {
      { label = 'Sandy Medical',     pos = vec3(1839.6, 3672.9, 34.28) },
      { label = 'the Paleto clinic', pos = vec3(-247.8, 6331.2, 32.43) },
      { label = 'Pillbox',           pos = vec3(307.7, -595.2, 43.28) },
    },
  },
  Lines = {
    rumor_food     = { '...heard %s still has shelves. Nobody has been through it since the fires.', 'If you are hungry: %s. Go at first light. Go quiet.', '*static* ...%s... cans... a whole aisle... *static*' },
    rumor_medicine = { '...someone said %s was never looted. Locked, not empty.', '%s. There is a supply room behind triage. Bring a crowbar.' },
    probe          = { '*static* ...movement... near %s... a lot of it... *static*', 'Whoever is at %s: they are coming up the road. Get inside.' },
    trader         = { 'Word travels. Someone on channel 5 is asking about the place at %s. Might be trade. Might not.' },
    unrest         = { 'Your people at %s are talking. Bring them something. Anything.', 'It is quiet at %s. The bad kind of quiet.' },
    safehouse      = { '%s is empty. The door still holds. Someone should take it before someone else does.', 'If you need walls: %s. Nobody has claimed it.' },
  },
  StrangerLines = { 'I have been walking for three days. I can work. I can keep watch.', 'Saw your barricade from the road. Please. I will not be trouble.', 'My group is gone. I have hands. I have a knife. Let me in.' },
}
