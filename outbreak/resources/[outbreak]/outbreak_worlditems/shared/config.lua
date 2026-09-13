WorldItemsCfg = {
  -- Any inventory item can be placed. If it has no model here it uses Fallback (a small bundle) — you can still set beans on a table.
  Fallback = 'prop_paper_bag_small',
  Models = {
    canned_beans = 'prop_cs_beer_bot_40oz', water_clean = 'prop_ld_flow_bottle_01', water_dirty = 'prop_ld_flow_bottle_02', mre = 'prop_food_bs_bag_01',
    bandage = 'prop_ld_health_pack', antibiotics = 'prop_cs_pills', radio_handheld = 'prop_cs_hand_radio', radio_base = 'prop_radio_01',
    plank = 'prop_ld_planks01', nails = 'prop_tool_box_02', hammer_tool = 'prop_tool_hammer', crowbar_tool = 'prop_ld_crowbar', gas_can_small = 'prop_jerrycan_01a',
    car_battery = 'prop_car_battery_01', engine_parts = 'prop_car_engine_01', hose_kit = 'prop_hose_1', map_scrap = 'prop_cs_paper_01', document = 'prop_cs_documents_01',
    lantern = 'prop_gaslamp_01', sandbag = 'prop_sandbag_wall', crate = 'prop_box_wood02a', duffel_bag = 'prop_ld_bag_01', note = 'prop_cs_paper_02', chair = 'prop_chair_01a',
    padlock = 'prop_ld_padlock', dog_tags = 'prop_cs_dogtag',
  },
  -- Placeable STORAGE: becomes an ox stash bound to the placed object. Lockable with a padlock; forcing = pin sweep (pins).
  Storage = { crate = { slots = 20, weight = 60000, pins = 3 }, duffel_bag = { slots = 12, weight = 30000, pins = 2 } },
  -- Curated MAP props you can take. Removal is persisted with CreateModelHide for everyone. model -> { item, count, weight-ish delay }
  Takeables = {
    [`prop_chair_01a`] = { item = 'chair', count = 1, seconds = 3 },
    [`prop_ld_planks01`] = { item = 'plank', count = 2, seconds = 6 },
    [`prop_gaslamp_01`] = { item = 'lantern', count = 1, seconds = 3 },
    [`prop_sandbag_wall`] = { item = 'sandbag', count = 1, seconds = 8 },
    [`prop_jerrycan_01a`] = { item = 'gas_can_small', count = 1, seconds = 3 },
    [`prop_tool_box_02`] = { item = 'nails', count = 1, seconds = 3 },
    [`prop_car_battery_01`] = { item = 'car_battery', count = 1, seconds = 4 },
    [`prop_ld_health_pack`] = { item = 'bandage', count = 2, seconds = 2 },
  },
  -- SHELF STOCK: store shelf props are the store's inventory. Grab one, it's gone for everyone until restocked.
  -- Model names are GTA 24/7 / LTD interior props (v_ret_ml_* = "misc line"). VERIFY in-game with /outfitcheck-style prop cycling if any fail.
  Shelves = {
    [`v_ret_ml_sweet1`] = { item = 'chocolate_bar', count = 1, seconds = 2 }, [`v_ret_ml_sweet2`] = { item = 'chocolate_bar', count = 1, seconds = 2 }, [`v_ret_ml_sweet3`] = { item = 'chocolate_bar', count = 1, seconds = 2 },
    [`v_ret_ml_chips1`] = { item = 'chips', count = 1, seconds = 2 }, [`v_ret_ml_chips2`] = { item = 'chips', count = 1, seconds = 2 }, [`v_ret_ml_chips3`] = { item = 'chips', count = 1, seconds = 2 }, [`v_ret_ml_chips4`] = { item = 'chips', count = 1, seconds = 2 },
    [`v_ret_ml_bread01`] = { item = 'bread', count = 1, seconds = 2 }, [`v_ret_ml_bread02`] = { item = 'bread', count = 1, seconds = 2 },
    [`v_ret_ml_cereal`] = { item = 'noodle_bowl', count = 1, seconds = 2 }, [`v_ret_ml_beerbla`] = { item = 'beer', count = 1, seconds = 2 }, [`v_ret_ml_beeram`] = { item = 'beer', count = 1, seconds = 2 },
    [`prop_ecola_can`] = { item = 'soda', count = 1, seconds = 1 }, [`prop_ld_can_01`] = { item = 'soda', count = 1, seconds = 1 }, [`prop_ld_can_01b`] = { item = 'soda', count = 1, seconds = 1 },
    [`v_ret_247_redwine`] = { item = 'beer', count = 1, seconds = 2 }, [`prop_food_bs_chips`] = { item = 'chips', count = 1, seconds = 2 }, [`prop_cs_bottle_01`] = { item = 'water_clean', count = 1, seconds = 2 },
    [`v_ret_ml_water`] = { item = 'water_clean', count = 1, seconds = 2 }, [`prop_food_cb_noodles`] = { item = 'noodle_bowl', count = 1, seconds = 2 },
  },
  ShelfRestock = { hours = 36, nearCampHours = 8 },   -- "someone restocked" — faster when a camp with a trading habit is near
  MaxPlacedPerPlayer = 40, MaxDistance = 4.0, RotateStep = 10.0,
  NotePlaceableAsIntel = true,   -- a placed 'document' becomes environmental intel: reading it grants the intel without consuming it
  -- ENTROPY (server): the world pushes back
  Entropy = {
    tickMinutes = 10,
    camps = { tidyAfterHours = 2 },                    -- items placed inside a camp by non-residents get tidied into the camp's stash
    takeables = { restoreAfterHours = 48 },            -- "someone replaced it": taken map props come back
    raiders = { checkHours = 6, chance = 0.25, roadRadius = 60.0 }, -- unlocked storage outside a claimed house near a road: raiders break in
    perishables = { canned_beans = false, water_dirty = 12, mre = false, rotten_meat = 6, bread = 24, noodle_bowl = false, chocolate_bar = false }, -- hours until a placed food item spoils/vanishes
  },
}
