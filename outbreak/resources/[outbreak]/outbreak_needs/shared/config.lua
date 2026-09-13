NeedsCfg = {
  TickSeconds = 15,
  Decay = { hunger = 0.35, thirst = 0.55, fatigue = 0.18 },
  SprintMultiplier = 2.0,
  StarveDamage = 2,
  Infection = {
    stages = { { after = 0, label = 'Anxious', fxDamage = 0 }, { after = 1, label = 'Queasy', fxDamage = 0 },
               { after = 3, label = 'Fever', fxDamage = 1 }, { after = 6, label = 'Critical', fxDamage = 3 } },
    fatal = true, antibioticsSlowHours = 4,
  },
  -- Body-part wounds. A hit lands on a bone; we map it to a part.
  Parts = { 'head', 'torso', 'left_arm', 'right_arm', 'left_leg', 'right_leg' },
  BoneToPart = {
    [31086] = 'head', [39317] = 'head', [24818] = 'torso', [24816] = 'torso', [11816] = 'torso', [57597] = 'torso',
    [45509] = 'left_arm', [61163] = 'left_arm', [18905] = 'left_arm', [28252] = 'right_arm', [57005] = 'right_arm', [40269] = 'right_arm',
    [58271] = 'left_leg', [63931] = 'left_leg', [14201] = 'left_leg', [51826] = 'right_leg', [36864] = 'right_leg', [52301] = 'right_leg',
  },
  WoundTypes = {
    -- from zombies: scratch (bleeds a little) or bite (bleeds, infection roll handled by core)
    scratch    = { bleed = 1, treat = { 'ripped_sheet', 'bandage' }, label = 'Scratch' },
    bite       = { bleed = 2, treat = { 'bandage' },                  label = 'Bite' },
    laceration = { bleed = 2, treat = { 'bandage' },                  label = 'Laceration' },   -- melee weapons
    gunshot    = { bleed = 3, treat = { 'bandage' },                  label = 'Gunshot wound', slow = true },
    fracture   = { bleed = 0, treat = { 'splint' },                   label = 'Fracture', slow = true, legOnly = true },
  },
  WoundRateLimitMs = 800,   -- server ignores wound reports faster than this
  Encumbrance = { slowAt = 0.8, crawlAt = 1.0 },
}
