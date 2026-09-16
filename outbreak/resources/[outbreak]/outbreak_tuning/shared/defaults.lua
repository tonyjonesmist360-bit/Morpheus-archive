-- outbreak_tuning/shared/defaults.lua — THE tuning table. Keys are read live from GlobalState.obTune
-- by the resources named on the right, so a change lands on the next tick / next schedule.
-- Runtime: `ob_tune` lists, `ob_tune set <key> <value>`, `ob_tune reload` (re-reads tuning.json),
-- `ob_tune reset`. tuning.json in this resource overrides these defaults and is written by `set`.
-- BALANCE-TUNING.md explains what each knob does to the game.
TuneDefaults = {
  -- WORLD DIRECTOR (outbreak_director) — minutes between passes, and what a pass tends to do
  ['director.everyMin']         = { v = 30,   what = 'shortest gap between director passes (min)' },
  ['director.everyMax']         = { v = 60,   what = 'longest gap between director passes (min)' },
  ['director.weight.stranger']  = { v = 40,   what = 'chance weight: a stranger asks to join' },
  ['director.weight.rumor_food']= { v = 35,   what = 'chance weight: food rumour on the radio' },
  ['director.weight.rumor_medicine'] = { v = 30, what = 'chance weight: medicine rumour' },
  ['director.weight.probe']     = { v = 25,   what = 'chance weight: a defense event at a settlement' },
  ['director.weight.unrest']    = { v = 20,   what = 'chance weight: unrest message when morale < 30' },
  ['director.weight.trader']    = { v = 10,   what = 'chance weight: trader rumour' },
  ['director.weight.quiet']     = { v = 30,   what = 'chance weight: nothing happens (on purpose)' },
  ['tide.everyMin']             = { v = 20,   what = 'the Tide moves: shortest gap (min)' },
  ['tide.everyMax']             = { v = 40,   what = 'the Tide moves: longest gap (min)' },
  -- ZOMBIES (outbreak_core client)
  ['zombies.maxPerPlayer']      = { v = 12,   what = 'ambient zombies around each player' },
  ['zombies.nightMultiplier']   = { v = 1.6,  what = 'multiplier 22:00-05:00' },
  ['zombies.aggroRadius']       = { v = 30.0, what = 'sight range at visibility 50 (m)' },
  ['zombies.mix.shambler']      = { v = 70,   what = 'spawn share weight' },
  ['zombies.mix.runner']        = { v = 15,   what = 'spawn share weight (night only)' },
  ['zombies.mix.bloater']       = { v = 10,   what = 'spawn share weight' },
  ['zombies.mix.screamer']      = { v = 5,    what = 'spawn share weight' },
  ['horde.minInterval']         = { v = 20,   what = 'random horde: shortest gap (min)' },
  ['horde.maxInterval']         = { v = 45,   what = 'random horde: longest gap (min)' },
  ['horde.size']                = { v = 25,   what = 'random horde size' },
  -- INFECTION / WOUNDS (outbreak_needs, outbreak_core)
  ['infection.chancePerHit']    = { v = 0.15, what = 'chance a zombie hit infects you directly' },
  ['infection.dirtyMinutes']    = { v = 20,   what = 'untreated zombie wound turns after (min)' },
  ['infection.cureWithinHours'] = { v = 1,    what = 'antibiotics cure inside this window (h)' },
  ['infection.stageFeverHours'] = { v = 3,    what = 'hours until Fever (blur, shake, damage)' },
  ['infection.stageCriticalHours'] = { v = 6, what = 'hours until Critical (heavy damage)' },
  -- LOOT (outbreak_items)
  ['loot.multiplier']           = { v = 1.0,  what = 'every loot chance x this (0.5 harsh, 2 generous)' },
  ['loot.respawnMinutes']       = { v = 30,   what = 'a searched container is empty for (min)' },
  -- SETTLEMENTS (outbreak_supply)
  ['supply.foodPerResidentDay'] = { v = 2.0,  what = 'food units each resident eats per day' },
  ['supply.waterPerResidentDay']= { v = 2.0,  what = 'water units each resident drinks per day' },
  ['supply.tickMinutes']        = { v = 10,   what = 'settlement tick (min)' },
  ['morale.leavingBelow']       = { v = 25,   what = 'residents start leaving under this morale' },
  -- DOWNED (outbreak_down)
  ['down.bleedOutSeconds']      = { v = 300,  what = 'incapacitated -> critical (s)' },
  ['down.criticalMinutes']      = { v = 30,   what = 'critical -> the wall (min)' },
  -- OPS (outbreak_log)
  ['ops.restartHour']           = { v = 4,    what = 'daily restart hour (txAdmin does the restart; we warn at 60/15/5/1)' },
  ['ops.perfAlertMs']           = { v = 500,  what = 'print an alert when the server loop is this late (ms)' },
}
