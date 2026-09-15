SpawnCfg = {
  -- Welcome card on every character load (not just the first spawn). Keep it to what a new
  -- player needs in the first minute; the rest is in the F1 panel.
  Motd = {
    title = 'DEAD STATE',
    lines = {
      'Channel 4 is main comms. N opens the radio, CapsLock talks. [ and ] step channels.',
      'G is the survival wheel. F1 is everything about you. TAB is your pockets.',
      'Quiet keeps you alive. Whistling, gunfire and chips do not.',
      'Downed? You can still talk, T for chat, F6 for a distress call. /ooc for out of character.',
    },
  },
  -- FIRST TEN MINUTES (v0.22). Runs once per character after the scenario spawn; /tutorial replays it.
  -- Each step: a line at the top of the screen, a check from the core tick, a sound when it lands.
  Guide = {
    enabled = true, stepSound = { 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET' }, doneSound = { 'MEDAL_UP', 'HUD_MINI_GAME_SOUNDSET' },
    Steps = {
      { id = 'move',   text = 'You are awake. WASD moves, Shift runs. Ctrl crouches - crouching is how you stay unseen.', check = 'moved', arg = 6.0, timeout = 0 },
      { id = 'pockets',text = 'TAB: your pockets. Beans, a knife, water, a ripped sheet, a map scrap.',                   check = 'wait',  arg = 10, timeout = 10 },
      { id = 'drink',  text = 'Drink. Drag the clean water to use it, or put it on the hotbar (1-5) and press the key.',   check = 'thirst', arg = 5, timeout = 60 },
      { id = 'wheel',  text = 'G: the survival wheel. Treat wounds, listen, throw a can, crouch, crew, map key.',          check = 'wait',  arg = 10, timeout = 10 },
      { id = 'status', text = 'F1: your body. Hover the silhouette to see what hurts and what fixes it.',                  check = 'wait',  arg = 10, timeout = 10 },
      { id = 'radio',  text = 'N: the radio. Channel 4 is where people talk. CapsLock to speak.',                          check = 'wait',  arg = 8,  timeout = 8 },
      { id = 'safety', text = 'Find walls. The nearest safehouse door is on your compass and marked on the map.',          check = 'house', arg = 25.0, timeout = 0 },
      { id = 'done',   text = 'You made it. E on the door claims it. Sleep in it. Keep it quiet out there.',               check = 'wait',  arg = 10, timeout = 10 },
    },
  },
  Active = 'motel',   -- which scenario fresh survivors get (set convar ob_scenario to override)
  Scenarios = {
    motel = {
      label = 'Day 3: Sandy Shores motel',
      pos = vec4(1961.24, 3742.4, 32.34, 300.0),
      story = 'You wake on a motel floor in Sandy Shores. The door is open. It has been three days.',
      kit = { { 'canned_beans', 1 }, { 'WEAPON_KNIFE', 1 }, { 'water_clean', 1 }, { 'ripped_sheet', 2 }, { 'water_dirty', 1 }, { 'map_scrap', 1 } },
      hour = 7, weather = 'OVERCAST',
      radio = { after = 20, channel = 0, title = 'STATIC', text = '...if anyone is receiving... the motel on the highway... we left the door open for you...' },
      needs = { hunger = 55, thirst = 40, fatigue = 70 },
    },
    airport = {
      label = 'Day 1: LSIA quarantine breach',
      pos = vec4(-1037.6, -2737.5, 20.17, 240.0),
      story = 'You wake under the airport overpass. Sirens, then nothing. Something was dragging you.',
      kit = { { 'canned_beans', 1 }, { 'WEAPON_KNIFE', 1 }, { 'water_clean', 1 }, { 'bandage', 1 } },
      hour = 22, weather = 'RAIN',
      radio = { after = 15, channel = 0, title = 'EMERGENCY BROADCAST', text = 'This is the Emergency Broadcast System. The LSIA perimeter has failed. Remain indoors.' },
      needs = { hunger = 80, thirst = 75, fatigue = 40 },
    },
    paleto = {
      label = 'Day 30: Paleto, alone',
      pos = vec4(-425.5, 6135.3, 31.48, 135.0),
      story = 'Behind a Paleto Bay diner. You have been alone a month. You stopped counting the nights.',
      kit = { { 'canned_beans', 1 }, { 'WEAPON_KNIFE', 1 }, { 'water_clean', 1 }, { 'can_opener', 1 }, { 'radio_handheld', 1 }, { 'radio_battery', 1 } },
      hour = 17, weather = 'FOGGY',
      radio = { after = 30, channel = 0, title = 'VOICE', text = '...Paleto... anyone in Paleto... we have a truck... answer on nine...' },
      needs = { hunger = 30, thirst = 30, fatigue = 50 },
    },
  },
}
