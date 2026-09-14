-- outbreak_supply/shared/config.lua
-- A SETTLEMENT is a claimed safehouse. Its STOCKPILE is the house stash (safehouse_<id>) —
-- nothing new to store, nothing to convert; the levels below are a read-model over what is
-- physically in that stash. RESIDENTS are NPC survivors who live there and eat from it.
SupplyCfg = {
  TickMinutes = 10,            -- consumption / spoilage / morale tick (via outbreak_core's scheduler: only while someone is online)
  TargetResidents = 4,         -- "room for N more"; the Director sends strangers while there is food to spare
  TargetDays = 3,              -- a category is 'good' at this many days of supply
  DoorRange = 8.0,             -- how close to the door you must be to cook / manage
  Categories = { 'food', 'water', 'medicine', 'fuel', 'ammo', 'materials', 'comfort' },
  Labels = { food = 'Food', water = 'Water', medicine = 'Medicine', fuel = 'Fuel', ammo = 'Ammo', materials = 'Materials', comfort = 'Comfort' },
  Units  = { food = 'meals', water = 'litres', medicine = 'doses', fuel = 'burns', ammo = 'rounds', materials = 'parts', comfort = 'treats' },
  -- What each resident uses per day. Ammo and materials are spent by events, not by the clock.
  PerResidentPerDay = { food = 2.0, water = 2.0, medicine = 0.1, fuel = 0.5, comfort = 0.5 },
  -- Reserve targets while nobody lives there yet (scaled by keyholders online). Gives a crew objectives from day one.
  Reserve = { food = 6, water = 6, medicine = 4, fuel = 4, ammo = 20, materials = 6, comfort = 2 },
  -- item -> { category = units }. An item can count in two categories (a plank burns or builds).
  Value = {
    canned_beans = { food = 1 }, mre = { food = 1.5, water = 0.3 }, hot_stew = { food = 1.5 }, cooked_meat = { food = 0.75 }, hot_noodles = { food = 1 },
    noodle_bowl = { food = 0.75 }, bread = { food = 0.5 }, chips = { food = 0.25 }, chocolate_bar = { food = 0.25, comfort = 1 },
    water_clean = { water = 1 }, soda = { water = 0.4, comfort = 0.5 }, beer = { water = 0.2, comfort = 1 },
    bandage = { medicine = 1 }, ripped_sheet = { medicine = 0.25 }, antibiotics = { medicine = 2 }, painkillers = { medicine = 0.5 }, splint = { medicine = 1 }, adrenaline_shot = { medicine = 2 },
    gas_can_small = { fuel = 6 }, plank = { fuel = 1, materials = 1 },
    nails = { materials = 1 }, sandbag = { materials = 2 }, duct_tape = { materials = 0.5 }, chair = { materials = 1 }, crate = { materials = 3 },
    ['ammo-9'] = { ammo = 1 }, ['ammo-shotgun'] = { ammo = 1 }, ['ammo-rifle'] = { ammo = 1 },
  },
  Unboiled = { water_dirty = true },   -- counted separately: "3 unboiled" — boil them (recipe) before they count as water
  -- Hours until a stack in the stockpile spoils. Statistical per tick (expected loss = count * tick/hours), no per-item clocks.
  Spoil = { bread = 24, rotten_meat = 6, water_dirty = 12, hot_stew = 18, cooked_meat = 24, hot_noodles = 12 },
  -- Cooking happens AT the door (DoorRange), takes from the stockpile, puts back into it. fuel = how many FuelItems to burn.
  FuelItems = { 'plank', 'gas_can_small' },
  Recipes = {
    boil    = { label = 'Boil water',   out = { water_clean = 2 }, inp = { water_dirty = 2 },                 fuel = 1, seconds = 8,  morale = 0 },
    stew    = { label = 'Bean stew',    out = { hot_stew = 2 },    inp = { canned_beans = 1, water_clean = 1 }, fuel = 1, seconds = 12, morale = 5, hot = true },
    meat    = { label = 'Cook the meat',out = { cooked_meat = 1 }, inp = { rotten_meat = 1 },                 fuel = 1, seconds = 10, morale = 2, hot = true },
    noodles = { label = 'Hot noodles',  out = { hot_noodles = 2 }, inp = { noodle_bowl = 1, water_clean = 1 }, fuel = 1, seconds = 6,  morale = 3, hot = true },
  },
  RecipeOrder = { 'boil', 'stew', 'noodles', 'meat' },
  Morale = {
    start = 60, min = 0, max = 100,
    fedBonus = 0.5, lowPenalty = 1, criticalPenalty = 2, comfortBonus = 1, starvingPenalty = 5,   -- per tick
    hotMeal = 5, hotMealCooldownMinutes = 30, residentJoined = 3, residentLeft = 8, residentDied = 12, heldTheDoor = 4, turnedAway = -1,
    -- BEHAVIOUR. Rolled every tick while residents >= 1. Each is a thing you can see: a note, a log line, a hole in the stock.
    dispute  = { below = 45, chance = 0.15, morale = -2 },                 -- a fight; a materials unit becomes kindling
    drinking = { below = 35, chance = 0.20, morale = -1, takes = 3 },     -- the comfort stock goes overnight
    leaving  = { below = 25, chance = 0.25, othersMorale = -5 },          -- a resident leaves with food, water, a bandage — and a note at the door
    starvingTicksToDeath = 6,                                             -- an hour with no food and someone does not wake up
  },
  Names = { 'Rae', 'Milo', 'Dee', 'Tomas', 'Quinn', 'Ines', 'Bo', 'Lena', 'Hal', 'Priya', 'Sal', 'Nadia', 'Otto', 'June', 'Cal', 'Wren', 'Idris', 'Marta', 'Gus', 'Faye' },
  Notes = { leaving = { "Took what I was owed. Don't come looking. - %s", "There's nothing here worth starving for. - %s", "You said it would get better. - %s", "Gone north. Don't follow. - %s" } },
  LogMax = 30,
}
