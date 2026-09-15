LootCfg = {
  RespawnMinutes = 30, SearchSeconds = 6,
  -- Searchable prop models -> loot table {item, min, max, chance}
  Containers = {
    [`prop_dumpster_01a`] = 'trash', [`prop_dumpster_02a`] = 'trash', [`prop_dumpster_02b`] = 'trash',
    [`prop_bin_05a`] = 'trash',
    [`prop_postbox_01a`] = 'house',
    [`prop_vend_soda_01`] = 'vend', [`prop_vend_soda_02`] = 'vend', [`prop_vend_snak_01_tu`] = 'vend',
    [`prop_toolchest_01`] = 'tools', [`prop_toolchest_02`] = 'tools', [`prop_toolchest_03`] = 'tools',
    [`prop_medstation_01`] = 'medical',
    -- the till: forcing it is loud, and what is inside stopped meaning anything
    [`prop_till_01`] = 'register', [`prop_till_02`] = 'register', [`prop_till_03`] = 'register',
  },
  -- STORES ARE LOOTING. A search of one of these is theft: its own prompt, its own noise.
  Labels = { register = 'Force the register', vend = 'Break into the machine' },
  Noise  = { register = 45, vend = 35 },
  Tables = {
    trash   = { { 'rotten_meat', 1, 1, 0.35 }, { 'water_dirty', 1, 1, 0.30 }, { 'ripped_sheet', 1, 2, 0.25 }, { 'duct_tape', 1, 1, 0.10 }, { 'old_cash', 1, 3, 0.15 } },
    vend    = { { 'water_clean', 1, 2, 0.55 }, { 'canned_beans', 1, 1, 0.20 }, { 'old_cash', 1, 4, 0.30 } },
    -- DEAD MONEY: it exists, it is findable, it is worth nothing. See ECONOMY in START-HERE.
    register = { { 'old_cash', 5, 40, 0.90 }, { 'soda', 1, 1, 0.15 }, { 'chocolate_bar', 1, 2, 0.20 } },
    house   = { { 'old_cash', 1, 6, 0.25 }, { 'canned_beans', 1, 2, 0.35 }, { 'can_opener', 1, 1, 0.12 }, { 'bandage', 1, 1, 0.20 }, { 'map_scrap', 1, 1, 0.05 }, { 'radio_base', 1, 1, 0.02 }, { 'radio_battery', 1, 2, 0.10 }, { 'ammo-9', 4, 9, 0.08 }, { 'WEAPON_KNIFE', 1, 1, 0.04 }, { 'gun_oil', 1, 1, 0.03 }, { 'note', 1, 3, 0.20 }, { 'padlock', 1, 1, 0.05 }, { 'duffel_bag', 1, 1, 0.04 } },
    tools   = { { 'hammer_tool', 1, 1, 0.20 }, { 'nails', 1, 1, 0.35 }, { 'plank', 1, 2, 0.30 }, { 'gas_can_small', 1, 1, 0.10 }, { 'radio_battery', 1, 1, 0.12 }, { 'crowbar_tool', 1, 1, 0.15 }, { 'car_battery', 1, 1, 0.08 }, { 'hose_kit', 1, 1, 0.12 }, { 'engine_parts', 1, 1, 0.07 }, { 'key_blank', 1, 1, 0.06 }, { 'radio_coil', 1, 1, 0.03 }, { 'ammo-shotgun', 2, 6, 0.05 }, { 'WEAPON_HATCHET', 1, 1, 0.03 }, { 'crate', 1, 1, 0.05 }, { 'rain_catcher', 1, 1, 0.05 }, { 'padlock', 1, 1, 0.06 } },
    medical = { { 'bandage', 1, 2, 0.45 }, { 'antibiotics', 1, 1, 0.12 }, { 'painkillers', 1, 1, 0.30 }, { 'splint', 1, 1, 0.15 }, { 'adrenaline_shot', 1, 1, 0.04 } },
  },
}
