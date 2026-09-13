-- CHAIN 5 — The light is still on. IMPLEMENTED (untested). The island is Cayo Perico, loaded natively by clients near it.
-- Intel: island_maritime (rumor on ch 16 via the Chiliad relay) -> island_charts (document at the marina; arrival at Chumash marina confirms)
--        -> island_landing (discovery: set foot on the island)
-- Stages: 1 hear it -> 2 find the charts -> 3 a boat that runs (marine fuel ≥ 60%) -> 4 the crossing (calm weather only) -> 5 the landing: occupants with their own rules -> 6 the light: restore the island repeater
-- Solutions on landing: negotiate (gift meds: they let you claim the far dock) | force (fight the enclave; island hostile, rep loss) | quiet (sneak past; claim the dock, they find out eventually)
-- The island is not an ending: marine fuel is finite, storms cut the route, infected wash up at night, raiders learn the route.
local O = function() return exports.outbreak_opportunities end
local ID = 'island'
local Cfg = {
  marina = vec3(-3427.6, 967.3, 8.3), marinaRadius = 40.0, chartsSpot = vec3(-3430.5, 980.2, 8.6),
  island = { beach = vec3(4900.0, -5180.0, 2.5), dock = vec3(5000.0, -5750.0, 3.0), enclave = vec3(4990.0, -5220.0, 3.5), lighthouse = vec3(4530.0, -4880.0, 5.0) },
  departRadius = 120.0, fuelToDepart = 60, calm = { CLEAR = true, CLOUDS = true, CLEARING = true },
  negotiate = { give = { { 'antibiotics', 2 }, { 'bandage', 4 } }, rep = 10 }, force = { rep = -20 }, quiet = { discoverHours = 24 },
  raidersLearn = 0.10, washup = { size = 6 }, cooldownMinutes = 0, repeatable = false,
}
local function transmit(t, title, origin, range) pcall(function() exports.outbreak_radio:transmit(16, title or 'MARITIME', t, nil, origin, range or 12000.0) end) end

O():registerOpportunity({
  id = ID, title = 'The light is still on', trigger = 'island_charts', intel = { 'island_maritime', 'island_charts', 'island_landing' },
  summary = 'A lighthouse still burning somewhere past the horizon. Charts at Chumash marina. A boat that runs on fuel you don\'t have. A crossing the weather has to allow. And people already there who did not invite you.',
  stages = { { label = 'Hear the broadcast' }, { label = 'Find the marina charts' }, { label = 'Get a boat running with 60% marine fuel' }, { label = 'The crossing (calm weather)' }, { label = 'The landing: the enclave' }, { label = 'Light the lighthouse (island repeater)' } },
  solutions = {
    { id = 'negotiate', label = 'Negotiate', desc = 'Bring 2 antibiotics and 4 bandages. They give you the far dock and a rule: nobody you bring gets to bring anyone.', solo = true },
    { id = 'force',     label = 'Take the island', desc = 'They are six. You are armed. The island will remember.', solo = false },
    { id = 'quiet',     label = 'Go around them', desc = 'Land at the far dock, claim it, keep quiet. They find out within a day.', solo = true },
  },
  cooldownMinutes = Cfg.cooldownMinutes, repeatable = Cfg.repeatable,
  onIntel = function(r, src, intelId)
    if intelId == 'island_charts' then exports.ox_inventory:AddItem(src, 'marine_chart', 1) end
  end,
  onStart = function(r, src) r.data.landed = {}; O():advance(ID, 2, src, {}); O():advance(ID, 3, src, {}) end,  -- broadcast heard + charts found = start
  onStage = function(r, stage)
    if stage == 4 then transmit('...vessel on the bearing... we see you... the channel is on your left... slow down...', 'THE LIGHT', Cfg.island.lighthouse) end
    if stage == 6 then TriggerClientEvent('outbreak:opp:island:lighthouse', -1, Cfg.island.lighthouse) end
  end,
  onRestore = function(r) TriggerClientEvent('outbreak:opp:island:state', -1, r.data) end,
  onReport = function(r, src, kind, p)
    if kind == 'depart' and r.stage == 3 then
      if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.marina) > Cfg.departRadius then return end
      if not Cfg.calm[GlobalState.obWeather or 'CLEAR'] then TriggerClientEvent('ox_lib:notify', src, { title = 'Not in this weather. The charts say wait.', type = 'error' }) return end
      if exports.ox_inventory:GetItemCount(src, 'marine_chart') < 1 then TriggerClientEvent('ox_lib:notify', src, { title = 'You need the charts.', type = 'error' }) return end
      local ped = GetPlayerPed(src); local veh = GetVehiclePedIsIn(ped, false); if veh == 0 then return end
      local ok, v = pcall(function() return exports.outbreak_vehicles:byNet(NetworkGetNetworkIdFromEntity(veh)) end)
      if not ok or not v or not v.boat then TriggerClientEvent('ox_lib:notify', src, { title = 'That is not a boat.', type = 'error' }) return end
      if v.fuel < Cfg.fuelToDepart then TriggerClientEvent('ox_lib:notify', src, { title = ('Not enough fuel. You need %d%%.'):format(Cfg.fuelToDepart), type = 'error' }) return end
      O():advance(ID, 4, src, { by = src })
      TriggerClientEvent('outbreak:opp:island:enable', -1)
    elseif kind == 'landed' and r.stage == 4 then
      if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.island.beach) > 150.0 and #(GetEntityCoords(GetPlayerPed(src)) - Cfg.island.dock) > 150.0 then return end
      exports.outbreak_intel:discover(src, 'island_landing', 'confirmed', 'arrival')
      O():advance(ID, 5, src, {})
      transmit('...they made it. Somebody made it. Get the elders.', 'THE LIGHT', Cfg.island.lighthouse, 3000.0)
      if math.random() < Cfg.raidersLearn then r.data.raidersKnow = true; O():setData(ID, 'raidersKnow', true); pcall(function() exports.outbreak_radio:transmit(13, 'RAIDER NET', '...boat left Chumash on a bearing. Somebody\'s found something out there.') end) end
    elseif kind == 'lighthouse' and r.stage == 6 then
      if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.island.lighthouse) > 15.0 then return end
      if exports.ox_inventory:GetItemCount(src, 'radio_coil') < 1 or exports.ox_inventory:GetItemCount(src, 'car_battery') < 1 then TriggerClientEvent('ox_lib:notify', src, { title = 'A coil and a battery. Same as Chiliad.', type = 'error' }) return end
      exports.ox_inventory:RemoveItem(src, 'radio_coil', 1); exports.ox_inventory:RemoveItem(src, 'car_battery', 1)
      pcall(function() exports.outbreak_radio:setRepeater('cayo', true, 'lighthouse lit') end)
      O():resolve(ID, r.data.solution or 'quiet', { by = src })
    end
  end,
  onChoose = function(r, src, sol)
    if r.stage ~= 5 then return false end
    if sol == 'negotiate' then
      for _, g in ipairs(Cfg.negotiate.give) do if exports.ox_inventory:GetItemCount(src, g[1]) < g[2] then TriggerClientEvent('ox_lib:notify', src, { title = ('They want %dx %s.'):format(g[2], g[1]:gsub('_', ' ')), type = 'error' }) return false end end
      for _, g in ipairs(Cfg.negotiate.give) do exports.ox_inventory:RemoveItem(src, g[1], g[2]) end
      pcall(function() exports.outbreak_faction:addRep(src, 'enclave', Cfg.negotiate.rep, 'medicine for the island') end)
      r.data.enclave = 'allied'
    elseif sol == 'force' then
      pcall(function() exports.outbreak_faction:addRep(src, 'enclave', Cfg.force.rep, 'took the island') end); pcall(function() exports.outbreak_faction:addRep(src, 'civilian', -8, 'word travels') end)
      r.data.enclave = 'hostile'; TriggerClientEvent('outbreak:opp:island:hostile', -1, Cfg.island.enclave)
    elseif sol == 'quiet' then
      r.data.enclave = 'unaware'; r.data.discoverAt = os.time() + Cfg.quiet.discoverHours * 3600
    end
    pcall(function() exports.outbreak_housing:releaseHouse('island_dock') end)  -- the dock becomes claimable
    O():setData(ID, 'enclave', r.data.enclave)
    O():advance(ID, 6, src, {})
    return true
  end,
  onResolve = function(r, state, outcome)
    transmit('...this is the island. The light is on. The channel is open. Bring what you can carry and nobody you can\'t trust.', 'THE LIGHT', Cfg.island.lighthouse)
    for c in pairs(O():participants(ID)) do local s = GetSrcByCid(c); if s then pcall(function() exports.outbreak_faction:addRep(s, 'civilian', 6, 'reached the island') end) end end
  end,
  debug = { kit = function(r, src) exports.ox_inventory:AddItem(src, 'marine_chart', 1); exports.ox_inventory:AddItem(src, 'marine_fuel_can', 1, { fuel = 100 }); exports.ox_inventory:AddItem(src, 'car_battery', 2); exports.ox_inventory:AddItem(src, 'engine_parts', 1); exports.ox_inventory:AddItem(src, 'radio_coil', 1); exports.outbreak_intel:discover(src, 'island_maritime', 'rumor', 'radio') end },
})

-- the island pushes back: washed-up infected at night, the quiet route gets discovered, storms handled by vehicles v2
CreateThread(function()
  while true do
    Wait(600000)
    local r = O():get(ID); if not r or (r.state ~= 'active' and r.state ~= 'resolved') then goto continue end
    local t = GlobalState.obTime or 420; local h = math.floor(t / 60)
    if (h >= 22 or h <= 5) then TriggerClientEvent('outbreak:opp:island:washup', -1, Cfg.island.beach, Cfg.washup.size) end
    if r.data.enclave == 'unaware' and r.data.discoverAt and os.time() > r.data.discoverAt then
      r.data.enclave = 'wary'; O():setData(ID, 'enclave', 'wary')
      transmit('...someone\'s been using the far dock. We see the boat. We see you. Come talk, or don\'t come back.', 'THE LIGHT', Cfg.island.lighthouse, 4000.0)
    end
    ::continue::
  end
end)

-- marina charts: a searchable spot that yields the charts document once per character (arrival confirms the intel too)
CreateThread(function()
  exports.ox_inventory:RegisterStash('marina_office', 'Harbourmaster\'s desk', 6, 20000, nil)
end)
RegisterNetEvent('outbreak:opp:island:charts', function()
  local src = source
  if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.chartsSpot) > 4.0 then return end
  if exports.outbreak_intel:hasIntel(src, 'island_charts', 'partial') then TriggerClientEvent('ox_lib:notify', src, { title = 'Nothing else here. You have what you came for.', type = 'inform' }) return end
  exports.outbreak_intel:giveDocument(src, 'island_charts')
end)
