SkillCfg = {
  Skills = { 'mechanics', 'medicine', 'stealth', 'fitness', 'scavenging' },
  MaxLevel = 10,
  XPPerLevel = 100,     -- level = floor(sqrt(xp / 100))-ish; kept linear for readability
  XP = { repair = 25, battery = 15, hotwire = 12, bandage = 15, splint = 25, stabilize = 40,
         sneak_tick = 2, sprint_tick = 1, search = 6, cache = 30, quiet_kill = 10 },
  -- what levels buy you (read via exports by other resources)
  Effects = {
    mechanics  = function(l) return { repairTime = 1.0 - l * 0.06, partsSave = l * 0.04 } end,  -- 40% faster, 40% chance parts survive at 10
    medicine   = function(l) return { bandageTime = 1.0 - l * 0.05, stabilizeHealth = 20 + l * 3 } end,
    stealth    = function(l) return { noiseMult = 1.0 - l * 0.04, sightMult = 1.0 - l * 0.03 } end, -- 40% quieter, 30% harder to see at 10
    fitness    = function(l) return { staminaMult = 1.0 + l * 0.08 } end,
    scavenging = function(l) return { lootBonus = l * 0.03 } end,                                 -- +30% chance at 10
  },
  TraitStarts = { handy = { mechanics = 200 }, first_aider = { medicine = 200 } },
  TraitXPMult = { fast_learner = 1.25, slow_learner = 0.75 },
}
