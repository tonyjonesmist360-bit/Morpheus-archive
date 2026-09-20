LootCfg = {
  RespawnMinutes = 30, SearchSeconds = 6,
  -- Searchable prop models -> loot table {item, min, max, chance}
  Containers = {
    [`prop_dumpster_01a`] = 'trash', [`prop_dumpster_02a`] = 'trash', [`prop_dumpster_02b`] = 'trash',
    [`prop_bin_05a`] = 'trash',
    [`prop_postbox_01a`] = 'house',
    [`prop_vend_soda_01`] = 'vend', [`prop_vend_soda_02`] = 'vend', [`prop_vend_snak_01_tu`] = 'vend',
    [`prop_vend_snak_01`] = 'vend', [`prop_vend_water_01`] = 'vend', [`prop_vend_coffe_01`] = 'vend', [`prop_vend_fags_01`] = 'vend', [`prop_vend_condom_01`] = 'vend', [`prop_vend_ice_01`] = 'vend',
    [`prop_toolchest_01`] = 'tools', [`prop_toolchest_02`] = 'tools', [`prop_toolchest_03`] = 'tools',
    [`prop_medstation_01`] = 'medical',
    -- the till: forcing it is loud, and what is inside stopped meaning anything
    [`prop_till_01`] = 'register', [`prop_till_02`] = 'register', [`prop_till_03`] = 'register',
  },
  -- STORES ARE LOOTING. A search of one of these is theft: its own prompt, its own noise.
  Labels = { register = 'Force the register', vend = 'Break into the machine', gunstore = 'Take weapons off the rack', gunsafe = 'Force the ammo safe', vault = 'Crack the vault' },
  Noise  = { register = 45, vend = 35, gunsafe = 40, vault = 55 },
  -- NAMED LOOT SITES (v0.23). Gun stores and bank vaults are not shops; they are places you loot.
  -- A site is a sphere zone: label, table, position, radius, optional minigame before the roll.
  -- Coordinates are from memory - UNVERIFIED. Stand at the spot and use /ob_site_here to print a
  -- corrected line, or fix them here. Sites live in one place so `loot reset` and F9 can find them.
  Sites = {
    -- Ammunation counters / racks (ids from the store list; three per store: rack + counter + safe)
    { id = 'ammu_sandy_rack',    label = 'Sandy Shores Ammunation — rack',   table = 'gunstore', pos = vec3(1693.4, 3760.2, 34.7), radius = 2.5 },
    { id = 'ammu_sandy_safe',    label = 'Sandy Shores Ammunation — safe',   table = 'gunsafe',  pos = vec3(1698.0, 3757.6, 34.7), radius = 1.8, minigame = 'pinsweep', pins = 3 },
    { id = 'ammu_paleto_rack',   label = 'Paleto Ammunation — rack',         table = 'gunstore', pos = vec3(-330.2, 6083.9, 31.5), radius = 2.5 },
    { id = 'ammu_paleto_safe',   label = 'Paleto Ammunation — safe',         table = 'gunsafe',  pos = vec3(-324.4, 6079.5, 31.5), radius = 1.8, minigame = 'pinsweep', pins = 3 },
    { id = 'ammu_hawick_rack',   label = 'Hawick Ammunation — rack',         table = 'gunstore', pos = vec3(252.9, -50.0, 69.9),    radius = 2.5 },
    { id = 'ammu_hawick_safe',   label = 'Hawick Ammunation — safe',         table = 'gunsafe',  pos = vec3(258.3, -47.9, 69.9),    radius = 1.8, minigame = 'pinsweep', pins = 3 },
    { id = 'ammu_pillbox_rack',  label = 'Pillbox Hill Ammunation — rack',   table = 'gunstore', pos = vec3(22.0, -1107.3, 29.8),   radius = 2.5 },
    { id = 'ammu_pillbox_safe',  label = 'Pillbox Hill Ammunation — safe',   table = 'gunsafe',  pos = vec3(16.5, -1103.0, 29.8),   radius = 1.8, minigame = 'pinsweep', pins = 3 },
    { id = 'ammu_chumash_rack',  label = 'Chumash Ammunation — rack',        table = 'gunstore', pos = vec3(-3172.6, 1087.1, 20.8), radius = 2.5 },
    { id = 'ammu_tataviam_rack', label = 'Tataviam Ammunation — rack',       table = 'gunstore', pos = vec3(842.4, -1033.5, 28.2),  radius = 2.5 },
    { id = 'ammu_cypress_rack',  label = 'Cypress Flats Ammunation — rack',  table = 'gunstore', pos = vec3(810.2, -2157.4, 29.6),  radius = 2.5 },
    { id = 'ammu_lsh_rack',      label = 'Little Seoul Ammunation — rack',   table = 'gunstore', pos = vec3(-662.2, -935.3, 21.8),  radius = 2.5 },
    { id = 'ammu_vinewood_rack', label = 'Vinewood Ammunation — rack',       table = 'gunstore', pos = vec3(-1305.2, -393.5, 36.7), radius = 2.5 },
    { id = 'ammu_morningwood_rack', label = 'Morningwood Ammunation — rack', table = 'gunstore', pos = vec3(-1117.6, 2698.6, 18.6), radius = 2.5 },
    { id = 'ammu_rte68_rack',    label = 'Route 68 Ammunation — rack',       table = 'gunstore', pos = vec3(2568.3, 294.4, 108.7),  radius = 2.5 },
    -- Bank vaults. The Pacific Standard vault and the Fleeca branches' back rooms.
    { id = 'vault_pacific',      label = 'Pacific Standard — vault',         table = 'vault',    pos = vec3(263.6, 213.4, 101.7),   radius = 3.0, minigame = 'pinsweep', pins = 5 },
    { id = 'vault_fleeca_hawick',label = 'Fleeca Hawick — vault',            table = 'vault',    pos = vec3(311.8, -284.5, 54.2),   radius = 2.5, minigame = 'pinsweep', pins = 4 },
    { id = 'vault_fleeca_legion',label = 'Fleeca Legion Square — vault',     table = 'vault',    pos = vec3(147.0, -1046.1, 29.4),  radius = 2.5, minigame = 'pinsweep', pins = 4 },
    { id = 'vault_fleeca_rock',  label = 'Fleeca Rockford — vault',          table = 'vault',    pos = vec3(-1212.9, -336.5, 37.8), radius = 2.5, minigame = 'pinsweep', pins = 4 },
    { id = 'vault_fleeca_burton',label = 'Fleeca Burton — vault',            table = 'vault',    pos = vec3(-350.5, -53.2, 49.0),   radius = 2.5, minigame = 'pinsweep', pins = 4 },
    { id = 'vault_fleeca_gcp',   label = 'Fleeca Great Ocean Hwy — vault',   table = 'vault',    pos = vec3(-2962.6, 482.9, 15.7),  radius = 2.5, minigame = 'pinsweep', pins = 4 },
    { id = 'vault_blaine',       label = 'Blaine County Savings — vault',    table = 'vault',    pos = vec3(-109.4, 6470.3, 31.6),  radius = 2.5, minigame = 'pinsweep', pins = 4 },
    -- BOLINGBROKE (v0.25): opens when the pool is clear (requires = 'pool:prison'). Coordinates from memory - unverified.
    { id = 'prison_cafeteria',  label = 'Bolingbroke — cafeteria stores', table = 'prison_food', pos = vec3(1746.8, 2593.5, 45.6), radius = 3.0, requires = 'pool:prison' },
    { id = 'prison_infirmary',  label = 'Bolingbroke — infirmary',        table = 'medical',     pos = vec3(1770.2, 2571.4, 45.6), radius = 3.0, requires = 'pool:prison' },
    { id = 'prison_tower_ne',   label = 'Bolingbroke — NE tower',         table = 'gunsafe',     pos = vec3(1827.0, 2636.0, 60.0), radius = 3.0, requires = 'pool:prison', guard = { model = 's_m_m_prisguard_01', weapon = 'WEAPON_PUMPSHOTGUN' } },
    { id = 'prison_tower_sw',   label = 'Bolingbroke — SW tower',         table = 'gunsafe',     pos = vec3(1612.0, 2497.0, 60.0), radius = 3.0, requires = 'pool:prison', guard = { model = 's_m_m_prisguard_01', weapon = 'WEAPON_CARBINERIFLE' } },
    { id = 'vault_fleeca_sandy', label = 'Fleeca Route 68 — vault',          table = 'vault',    pos = vec3(1175.3, 2706.8, 38.1),  radius = 2.5, minigame = 'pinsweep', pins = 4 },
  },
  Tables = {
    trash   = { { 'rotten_meat', 1, 1, 0.35 }, { 'water_dirty', 1, 1, 0.30 }, { 'ripped_sheet', 1, 2, 0.25 }, { 'duct_tape', 1, 1, 0.10 }, { 'old_cash', 1, 3, 0.15 } },
    vend    = { { 'water_clean', 1, 2, 0.55 }, { 'canned_beans', 1, 1, 0.20 }, { 'old_cash', 1, 4, 0.30 } },
    -- DEAD MONEY: it exists, it is findable, it is worth nothing. See ECONOMY in START-HERE.
    register = { { 'old_cash', 5, 40, 0.90 }, { 'soda', 1, 1, 0.15 }, { 'chocolate_bar', 1, 2, 0.20 } },
    -- GUN STORES ARE CACHES (bugfix 1): free, no licence, no money. Racks: melee + a pistol now and then. Safes: ammo.
    gunstore = { { 'WEAPON_KNIFE', 1, 1, 0.35 }, { 'WEAPON_BAT', 1, 1, 0.30 }, { 'WEAPON_CROWBAR', 1, 1, 0.20 }, { 'WEAPON_PISTOL', 1, 1, 0.22 }, { 'WEAPON_PUMPSHOTGUN', 1, 1, 0.07 }, { 'ammo-9', 6, 18, 0.45 }, { 'gun_oil', 1, 1, 0.15 } },
    gunsafe  = { { 'ammo-9', 12, 40, 0.80 }, { 'ammo-shotgun', 4, 16, 0.45 }, { 'ammo-rifle', 10, 30, 0.20 }, { 'WEAPON_PISTOL', 1, 1, 0.30 }, { 'weapon_kit', 1, 1, 0.10 } },
    -- BANKS ARE RUINS (bugfix 2): the vault is full of paper nobody wants, and the odd thing someone hid there.
    vault    = { { 'old_cash', 40, 120, 0.95 }, { 'document', 1, 1, 0.25 }, { 'padlock', 1, 1, 0.20 }, { 'key_blank', 1, 1, 0.15 } },
    prison_food = { { 'canned_beans', 2, 6, 0.90 }, { 'mre', 1, 3, 0.60 }, { 'water_clean', 2, 5, 0.80 }, { 'noodle_bowl', 1, 4, 0.60 }, { 'can_opener', 1, 1, 0.30 } },
    clothing = { { 'ripped_sheet', 2, 5, 0.80 }, { 'duffel_bag', 1, 1, 0.20 }, { 'old_cash', 1, 5, 0.30 } },
    house   = { { 'old_cash', 1, 6, 0.25 }, { 'canned_beans', 1, 2, 0.35 }, { 'can_opener', 1, 1, 0.12 }, { 'bandage', 1, 1, 0.20 }, { 'map_scrap', 1, 1, 0.05 }, { 'radio_base', 1, 1, 0.02 }, { 'radio_battery', 1, 2, 0.10 }, { 'ammo-9', 4, 9, 0.08 }, { 'WEAPON_KNIFE', 1, 1, 0.04 }, { 'gun_oil', 1, 1, 0.03 }, { 'note', 1, 3, 0.20 }, { 'padlock', 1, 1, 0.05 }, { 'duffel_bag', 1, 1, 0.04 } },
    tools   = { { 'workbench', 1, 1, 0.04 }, { 'hammer_tool', 1, 1, 0.20 }, { 'nails', 1, 1, 0.35 }, { 'plank', 1, 2, 0.30 }, { 'gas_can_small', 1, 1, 0.10 }, { 'radio_battery', 1, 1, 0.12 }, { 'crowbar_tool', 1, 1, 0.15 }, { 'car_battery', 1, 1, 0.08 }, { 'hose_kit', 1, 1, 0.12 }, { 'engine_parts', 1, 1, 0.07 }, { 'key_blank', 1, 1, 0.06 }, { 'radio_coil', 1, 1, 0.03 }, { 'ammo-shotgun', 2, 6, 0.05 }, { 'WEAPON_HATCHET', 1, 1, 0.03 }, { 'crate', 1, 1, 0.05 }, { 'rain_catcher', 1, 1, 0.05 }, { 'padlock', 1, 1, 0.06 } },
    medical = { { 'bandage', 1, 2, 0.45 }, { 'antibiotics', 1, 1, 0.12 }, { 'painkillers', 1, 1, 0.30 }, { 'splint', 1, 1, 0.15 }, { 'adrenaline_shot', 1, 1, 0.04 } },
  },
}
