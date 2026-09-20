MechCfg = {
  Faction = 'mechanics', Channel = 9,
  -- THE YARD: Beeker's Garage, Harmony. Foreman is the target; two mechanics work the bay and shoot the dead.
  -- Coordinates and models from memory - UNVERIFIED (/coords on the real spot).
  Yard = { pos = vec3(1175.0, 2640.0, 37.8), radius = 18.0, foreman = vec4(1178.5, 2636.5, 37.8, 200.0), foremanModel = 's_m_y_xmech_02',
           hands = { { model = 's_m_m_autoshop_01', off = { -4.0, 2.0 } }, { model = 's_m_m_autoshop_02', off = { 3.0, 4.5 } } }, handWeapon = 'WEAPON_PISTOL',
           SpawnRadius = 160.0, DespawnRadius = 240.0 },
  -- DELIVERY JOBS: a car somewhere, bring it to the Yard. Server picks, spawns, judges.
  Pickups = {
    { id = 'airfield',  label = 'the Sandy airfield hangar',   pos = vec4(1731.5, 3291.2, 41.2, 195.0), model = 'sadler' },
    { id = 'grapeseed', label = 'the Grapeseed farm',         pos = vec4(2411.3, 4990.8, 46.2, 45.0),  model = 'rebel' },
    { id = 'paleto',    label = 'the Paleto gas station',      pos = vec4(155.8, 6618.4, 31.8, 225.0),  model = 'ingot' },
    { id = 'zancudo',   label = 'the road below Zancudo',      pos = vec4(-1552.0, 2735.6, 17.2, 300.0), model = 'surfer' },
    { id = 'chumash',   label = 'the Chumash strip',           pos = vec4(-3151.0, 1080.5, 20.7, 260.0), model = 'emperor' },
    { id = 'sandy_town',label = 'behind the Sandy motel',      pos = vec4(1948.5, 3722.0, 32.3, 120.0),  model = 'asea' },
  },
  Job = { minutes = 20, deliverRadius = 14.0, stopSpeed = 2.5,
          reward = { delivered = 15, intact = 5, failed = -5, abandoned = -3 }, intactEngine = 900.0,
          -- keys are handed to whoever takes the job; the car persists like any keyed car until delivered
          startState = { locked = false, battery = 'ok', fuel = 45, hotwired = true } },
  -- RAIDERS GIVE CHASE: once the car has moved this far from the pickup, the driver's client spawns the pursuit.
  Chase = { chance = 0.75, afterMetres = 350.0, behind = 140.0, cars = { 'rebel', 'bfinjection' }, riders = 2, model = 'g_m_y_lost_01', weapon = 'WEAPON_MICROSMG',
            breakOffMetres = 400.0, giveUpSeconds = 240 },
  -- STANDING -> what the Yard does for you, free. Bands use FactionCfg.Standing words.
  Unlocks = { repair = 'wary', respray = 'neutral', performance = 'trusted', armour = 'kin' },
  Mods = { engine = { idx = 11, max = 3 }, brakes = { idx = 12, max = 2 }, transmission = { idx = 13, max = 2 }, armour = { idx = 16, max = 4 }, turbo = { idx = 18 } },
  Colours = { { 'Matte black', 12, 12 }, { 'Worn white', 111, 111 }, { 'Faded red', 27, 27 }, { 'Olive drab', 53, 53 }, { 'Rust brown', 96, 96 }, { 'Steel grey', 4, 4 } },
  Lines = { hire = 'Car is at %s. Bring it here in one piece. Raiders watch the roads - do not stop.', delivered = 'That will do. The Yard remembers.', intact = 'Not a scratch. You drive like you mean it.',
            failed = 'Wrecked it. We will not forget that either.', busy = 'You already owe me a car.', noStanding = 'I do not know you. Bring me a car first.' },
}
