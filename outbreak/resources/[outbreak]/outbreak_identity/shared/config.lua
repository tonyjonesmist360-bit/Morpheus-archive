IdentityCfg = {
  FormerLives = { 'Nurse', 'Mechanic', 'Line cook', 'Park ranger', 'Cop', 'Soldier', 'Carpenter', 'Burglar', 'Student', 'Trucker', 'Farmer', 'Bartender', 'Fisherman', 'Electrician', 'Nobody special' },
  -- Zomboid-style traits. Pick 2 positive and 1 negative. Effects are read by outbreak_skills.
  Traits = {
    positive = {
      { id = 'thick_skinned', label = 'Thick Skinned',  desc = 'Infection chance per hit -25%.' },
      { id = 'light_eater',   label = 'Light Eater',    desc = 'Hunger decays 30% slower.' },
      { id = 'camel',         label = 'Camel',          desc = 'Thirst decays 30% slower.' },
      { id = 'graceful',      label = 'Graceful',       desc = 'Footstep noise -30%.' },
      { id = 'keen_hearing',  label = 'Keen Hearing',   desc = 'Listen reveals more, farther.' },
      { id = 'handy',         label = 'Handy',          desc = 'Start Mechanics 2.' },
      { id = 'first_aider',   label = 'First Aider',    desc = 'Start Medicine 2.' },
      { id = 'cat_eyes',      label = 'Cat Eyes',       desc = 'Night is a little less black.' },
      { id = 'fast_learner',  label = 'Fast Learner',   desc = 'All skill XP +25%.' },
      { id = 'strong_back',   label = 'Strong Back',    desc = 'Carry 20% more.' },
    },
    negative = {
      { id = 'weak_stomach',  label = 'Weak Stomach',   desc = 'Bad food hits twice as hard.' },
      { id = 'heavy_sleeper', label = 'Restless',       desc = 'Fatigue decays 40% faster.' },
      { id = 'clumsy',        label = 'Clumsy',         desc = 'Footstep noise +30%.' },
      { id = 'smoker',        label = 'Smoker',         desc = 'Stamina drains faster. Cigarettes calm you.' },
      { id = 'hemophobic',    label = 'Hemophobic',     desc = 'Bandaging takes twice as long.' },
      { id = 'slow_learner',  label = 'Slow Learner',   desc = 'All skill XP -25%.' },
    },
  },
  LookRadius = 3.0,
}
