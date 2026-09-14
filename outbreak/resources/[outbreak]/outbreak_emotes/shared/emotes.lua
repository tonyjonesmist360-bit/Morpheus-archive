EmoteCfg = {
  -- scenario = looping ambient scenario; anim = { dict, clip, flag }
  -- effect = what it does to the world / your body while active
  Emotes = {
    rest     = { label = 'Rest',        scenario = 'WORLD_HUMAN_BUM_SLUMPED',     effect = 'rest',    desc = 'Sit against a wall. Fatigue recovers 3x. You are very killable.' },
    sit      = { label = 'Sit',         scenario = 'WORLD_HUMAN_SEAT_WALL',        desc = 'Sit on a ledge.' },
    lean     = { label = 'Lean',        scenario = 'WORLD_HUMAN_LEANING',          desc = 'Lean on something and look tired.' },
    guard    = { label = 'Stand guard', scenario = 'WORLD_HUMAN_GUARD_STAND',      desc = 'Rifle ready, eyes up.' },
    listen   = { label = 'Listen',      scenario = 'CODE_HUMAN_MEDIC_KNEEL',       effect = 'listen',  desc = 'Kneel and listen. After 4s you learn how many are near, and where.' },
    whistle  = { label = 'Whistle',     anim = { 'anim@mp_player_intcelebrationmale@salute', 'salute', 49 }, effect = 'whistle', once = 1500, desc = 'Loud. On purpose. Pull them off a friend, or toward one.' },
    mourn    = { label = 'Mourn',       scenario = 'CODE_HUMAN_MEDIC_TIME_OF_DEATH', desc = 'Kneel by the fallen.' },
    handsup  = { label = 'Hands up',    anim = { 'missminuteman_1ig_2', 'handsup_base', 49 }, desc = 'Don\'t shoot.' },
    kneel    = { label = 'Kneel',       anim = { 'random@arrests', 'kneeling_arrest_idle', 49 }, desc = 'On your knees, hands behind head.' },
    hammer   = { label = 'Work',        scenario = 'WORLD_HUMAN_HAMMERING',        desc = 'Fixing something. Or pretending.' },
    binocs   = { label = 'Scout',       scenario = 'WORLD_HUMAN_BINOCULARS',       desc = 'Glass the horizon.' },
    smoke    = { label = 'Smoke',       scenario = 'WORLD_HUMAN_SMOKING',          desc = 'Last pack in the county.' },
    weld     = { label = 'Weld',        scenario = 'WORLD_HUMAN_WELDING',          desc = 'Sparks. Also loud.' , effect = 'noisy' },
    stupor   = { label = 'Stupor',      scenario = 'WORLD_HUMAN_STUPOR',           desc = 'Sit on the ground, done with it all.' },
    wash     = { label = 'Wash',        scenario = 'WORLD_HUMAN_BUM_WASH',         desc = 'Scrub off the day.' },
    map      = { label = 'Check map',   scenario = 'WORLD_HUMAN_TOURIST_MAP',      desc = 'Paper map. Remember those?' },
  },
  -- WALK STYLES: /walkstyle <name> or the wheel. Clipset names from memory - UNVERIFIED; the
  -- picker requests each set with a timeout and says INVALID instead of silently doing nothing
  -- (the failure mode that hid the zombie lurch for a whole session). 'injured' is the one
  -- clipset in the pack already confirmed to load.
  WalkStyles = {
    normal = nil, injured = 'move_m@injured', tired = 'move_m@tired', hurry = 'move_m@hurry', brave = 'move_m@brave',
    casual = 'move_m@casual@a', sad = 'move_m@sad@a', hobo = 'move_m@hobo@a', tough = 'move_m@tough_guy@', drunk = 'move_m@drunk@slightlydrunk',
    shady = 'move_m@shadyped@a', quick = 'move_m@quick', femme = 'move_f@sexy@a', flee = 'move_m@fire',
  },
  CrouchClipset = 'move_ped_crouched',
  RestFatiguePerTick = 1.2,   -- every 5s while resting
  ListenRadius = 60.0,
}

-- ACTION ANIMS: every progress-bar action in the pack plays one of these via
-- the `action` export of outbreak_emotes (name, ms, label). TaskPlayAnim on a player ped
-- replicates to every client natively, so these are synchronized by construction.
EmoteCfg.Actions = {
  treat     = { dict = 'missheistdockssetup1ig_12@idle_a', clip = 'idle_a', flag = 1 },
  carry     = { dict = 'missfinale_c2mcs_1', clip = 'fin_c2_mcs_1_camman', flag = 49, loop = true },
  drag      = { dict = 'missfinale_c2mcs_1', clip = 'fin_c2_mcs_1_camman', flag = 49, loop = true },
  carried   = { dict = 'nm', clip = 'firemans_carry', flag = 33, loop = true },
  dragged   = { dict = 'combat@damage@writhe', clip = 'writhe_loop', flag = 1, loop = true },
  search    = { dict = 'amb@prop_human_bum_bin@base', clip = 'base', flag = 1 },
  barricade = { dict = 'amb@world_human_hammering@male@base', clip = 'base', flag = 1 },
  siphon    = { dict = 'timetable@gardener@filling_can', clip = 'gar_ig_5_filling_can', flag = 1 },
  repair    = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 1 },
  eat       = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 },
  drink     = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
  read      = { dict = 'missheistdockssetup1clipboard@base', clip = 'base', flag = 49 },
  surrender = { dict = 'missminuteman_1ig_2', clip = 'handsup_base', flag = 49, loop = true },
  pulse     = { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 1 },
  radio     = { dict = 'random@arrests', clip = 'generic_radio_chatter', flag = 49 },
  hotwire   = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer', flag = 1 },
  pry       = { dict = 'missexile3', clip = 'ex03_dingy_search_case_base_michael', flag = 1 },
}
