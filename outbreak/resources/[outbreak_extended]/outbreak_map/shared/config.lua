MapCfg = {
  -- Ambient things that break the fiction
  KillTrains = true, KillPlanes = true, KillBoats = true, KillEmergencyVehicles = true,
  -- Static dressing: model, pos, heading. Placed once per client when within 300m.
  -- Checkpoints get sandbags + barriers; highways get wreck clusters. Add freely.
  Props = {
    -- Zancudo gate
    { 'prop_mil_barrier', vec3(-1608.5, 2809.9, 17.0), 34.0 }, { 'prop_mil_barrier', vec3(-1613.7, 2803.9, 17.0), 34.0 },
    { 'prop_sandbag_wall', vec3(-1605.9, 2812.3, 17.0), 124.0 }, { 'prop_sandbag_wall', vec3(-1616.3, 2801.5, 17.0), 124.0 },
    -- LSIA quarantine
    { 'prop_mil_barrier', vec3(-1040.0, -2748.0, 21.3), 240.0 }, { 'prop_sandbag_wall', vec3(-1045.5, -2743.0, 21.3), 330.0 },
    { 'prop_barrier_work05', vec3(-1036.0, -2741.0, 21.3), 240.0 },
    -- Sandy airfield post
    { 'prop_sandbag_wall', vec3(1744.5, 3276.0, 41.1), 195.0 }, { 'prop_mil_barrier', vec3(1750.0, 3271.0, 41.1), 195.0 },
    -- Wreck clusters on the highways out of the city
    { 'prop_rub_carwreck_2', vec3(1123.0, -1310.5, 34.5), 80.0 }, { 'prop_rub_carwreck_5', vec3(1130.0, -1302.0, 34.5), 200.0 },
    { 'prop_rub_carwreck_8', vec3(-1524.0, 2650.0, 47.0), 30.0 }, { 'prop_rub_carwreck_3', vec3(-1518.0, 2662.0, 47.0), 110.0 },
    { 'prop_rub_carwreck_12', vec3(2549.0, 2586.0, 37.9), 20.0 }, { 'prop_rub_carwreck_7', vec3(2560.0, 2598.0, 37.9), 300.0 },
    { 'prop_barrier_work05', vec3(1170.0, -1370.0, 34.5), 80.0 }, { 'prop_barrier_work05', vec3(1176.0, -1364.0, 34.5), 80.0 },
    -- Quarantine signage
    { 'prop_sign_road_restriction_01', vec3(-1600.0, 2820.0, 17.0), 34.0 },
  },
}
