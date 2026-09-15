NeedsCfg = {
  TickSeconds = 15,
  Decay = { hunger = 0.35, thirst = 0.55, fatigue = 0.18 },
  SprintMultiplier = 2.0,
  StarveDamage = 2,
  Infection = {
    stages = { { after = 0, label = 'Anxious', fxDamage = 0 }, { after = 1, label = 'Queasy', fxDamage = 0 },
               { after = 3, label = 'Fever', fxDamage = 1 }, { after = 6, label = 'Critical', fxDamage = 3 } },
    fatal = true, antibioticsSlowHours = 4,
    dirtyMinutes = 20,        -- an untreated zombie wound (scratch/bite) this old infects you
    cureWithinHours = 1,      -- antibiotics inside this window CURE; after it they only slow the fever
  },
  -- Body-part wounds. A hit lands on a bone; we map it to a part.
  Parts = { 'head', 'torso', 'left_arm', 'right_arm', 'left_leg', 'right_leg' },
  BoneToPart = {
    [31086] = 'head', [39317] = 'head', [24818] = 'torso', [24816] = 'torso', [11816] = 'torso', [57597] = 'torso',
    [45509] = 'left_arm', [61163] = 'left_arm', [18905] = 'left_arm', [28252] = 'right_arm', [57005] = 'right_arm', [40269] = 'right_arm',
    [58271] = 'left_leg', [63931] = 'left_leg', [14201] = 'left_leg', [51826] = 'right_leg', [36864] = 'right_leg', [52301] = 'right_leg',
  },
  -- severity decides which wound wins a body part (a fracture replaces a bruise, never the reverse).
  -- dirty = can carry the infection if left untreated (see Infection.dirtyMinutes).
  -- Each item treats ONLY its type: bandage -> bleeds, splint -> breaks, painkillers -> bruises.
  WoundTypes = {
    bruise     = { bleed = 0, severity = 1, treat = { 'painkillers' },            label = 'Bruise',        state = 'bruised' },  -- fists, knocks
    scratch    = { bleed = 1, severity = 2, treat = { 'ripped_sheet', 'bandage' }, label = 'Scratch',       state = 'bleeding', dirty = true },
    bite       = { bleed = 2, severity = 3, treat = { 'bandage' },                 label = 'Bite',          state = 'bleeding', dirty = true },
    laceration = { bleed = 2, severity = 3, treat = { 'bandage' },                 label = 'Laceration',    state = 'bleeding' },   -- melee weapons
    gunshot    = { bleed = 3, severity = 5, treat = { 'bandage' },                 label = 'Gunshot wound', state = 'bleeding', slow = true },
    fracture   = { bleed = 0, severity = 4, treat = { 'splint' },                  label = 'Fracture',      state = 'broken',   slow = true, legOnly = true },
  },
  -- What an untreated wound does to the body (client effector, from the core tick):
  --   leg break  -> limp clipset until splinted (move_m@injured, the one the zombie bisect proved loads)
  --   arm wound  -> the sights will not hold still while aiming (gameplay cam hand shake)
  --   torso      -> a sprint you cannot hold: stamina cut after torsoSprintSeconds
  Effects = { limpClipset = 'move_m@injured', armSway = 0.45, torsoSprintSeconds = 3 },
  -- Plain-language body scan text. state -> what is wrong; item -> what fixes it.
  ScanText = {
    healthy = 'Fine.', bruised = 'Bruised. Aches when you move.', bleeding = 'Open and bleeding.', broken = 'Broken. Will not take weight.', treated = 'Dressed. Healing.',
    items = { bandage = 'bandage', ripped_sheet = 'ripped sheet', splint = 'splint', painkillers = 'painkillers' },
  },
  WoundRateLimitMs = 800,   -- server ignores wound reports faster than this
  Encumbrance = { slowAt = 0.8, crawlAt = 1.0 },
  -- SLEEP: in a bed you hold a key to. Resting outdoors (the emote) stays the slow, exposed option.
  Sleep = { seconds = 240, fatigueGain = 100, hungerCost = 8, thirstCost = 10, wakeOnZombies = true, wakeRadius = 60.0 },
}
