BroadcastCfg = {
  Emergency = { channel = 1, everyMinutes = 12, lines = {
    'This is the Emergency Broadcast System. Remain indoors. Do not approach the infected.',
    '...quarantine perimeter at Fort Zancudo remains in effect. Civilians will be turned back...',
    '...if you are hearing this, you are not alone. Boil all water. Report to--',   -- cuts off
    'This is a recording. This is a recording. This is a rec--',
  }},
  Numbers = { channel = 9, everyMinutes = { 35, 70 }, baitChance = 0.3, lootSlots = 8,
    -- cache drop sites (a pilot, a smuggler, a fool)
    sites = {
      vec3(2495.1, 4110.6, 38.3), vec3(-1585.0, 5178.3, 4.1), vec3(1526.0, 3789.5, 34.5),
      vec3(-284.9, -2497.3, 6.0), vec3(3813.1, 4460.5, 4.5), vec3(-2181.6, 4257.5, 49.0),
    },
    loot = { { 'mre', 3 }, { 'antibiotics', 2 }, { 'bandage', 4 }, { 'radio_battery', 3 }, { 'engine_parts', 1 }, { 'car_battery', 1 }, { 'purify_tabs', 3 } },
  },
  Distress = { everyMinutes = { 25, 55 }, baitChance = 0.35, channels = { 3, 4, 5, 6, 8 },
    lines = { 'Anyone-- anyone on this channel? We\'re pinned at %s. They\'re at the door.',
              'Mayday, mayday, this is-- we have wounded, we\'re near %s, please--',
              '*static* ...%s... can\'t hold... *static*' },
    survivorModels = { 'a_m_y_hipster_01', 'a_f_y_tourist_01', 'a_m_m_farmer_01' },
    reward = { { 'map_scrap', 1 }, { 'canned_beans', 2 }, { 'water_clean', 2 } },
  },
}
