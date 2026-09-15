MapKeyCfg = {
  -- Vanilla blip sprites that do not belong in the apocalypse. Removed every 10 s from the core
  -- tick (they respawn when the game streams a new area). Sprite ids from memory - UNVERIFIED;
  -- if a wanted blip vanishes or an unwanted one stays, this is the list to edit. Never put a
  -- sprite here that the Legend below uses.
  HideSprites = { 52, 71, 73, 75, 76, 77, 108, 110, 121, 205, 217, 500, 501, 502, 617, 619, 434, 279 },
  -- The legend. Order is the order shown. `res` = the resource that draws it (hidden from the
  -- key while that resource is not running, so the key never lists what is not on the map).
  Legend = {
    { icon = 'house',            colour = '#d8d2c0', label = 'Safehouse door',            what = 'A house you can claim. Grey.',                              res = 'outbreak_housing' },
    { icon = 'kit-medical',      colour = '#5e8a4c', label = 'Medical station',           what = 'Critical patients are treated here. Green cross.',           res = 'outbreak_down' },
    { icon = 'tower-broadcast',  colour = '#5e8a4c', label = 'Radio repeater',            what = 'Green = active, grey = dead. Extends radio range.',          res = 'outbreak_radio' },
    { icon = 'triangle-exclamation', colour = '#b4552d', label = 'Distress / DEFEND',     what = 'Red, flashing. Someone is down, or a settlement is under attack.', res = 'outbreak_down' },
    { icon = 'water',            colour = '#b4552d', label = 'The Tide',                  what = 'Red area. A roaming super-horde. Stay off those roads.',      res = 'outbreak_director' },
    { icon = 'location-dot',     colour = '#c98f3d', label = 'Crew pin',                  what = 'A marker your crew dropped. Only your crew sees it.',         res = 'outbreak_group' },
    { icon = 'user',             colour = '#5f8fa3', label = 'Crew member',               what = 'Blue. Where your people are.',                               res = 'outbreak_group' },
    { icon = 'circle-question',  colour = '#c98f3d', label = 'Rumour area',               what = 'Yellow area. Something is said to be in there. Go look.',     res = 'outbreak_intel' },
    { icon = 'map-pin',          colour = '#d8d2c0', label = 'Confirmed location',        what = 'A place the journal has confirmed. Yellow when active.',      res = 'outbreak_intel' },
    { icon = 'campground',       colour = '#b4552d', label = 'Camp',                      what = 'A survivor camp with a stockpile.',                          res = 'outbreak_camps' },
    { icon = 'shield-halved',    colour = '#7d8a5c', label = 'Military checkpoint',       what = 'Soldiers. Friendly if you are one of them.',                  res = 'outbreak_military' },
    { icon = 'gas-pump',         colour = '#c98f3d', label = 'Station',                   what = 'A fuel station with a shop to loot.',                         res = 'outbreak_stations' },
  },
}
