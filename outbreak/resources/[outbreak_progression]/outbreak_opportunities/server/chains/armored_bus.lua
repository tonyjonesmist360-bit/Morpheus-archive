-- CHAIN 2 — The Route 14 bus. IMPLEMENTED on outbreak_vehicles v2 (untested).
-- Intel: bus_photo (document, partial) -> bus_manifest (document: depot area; arrival confirms) -> bus spawned at the depot, managed by vehicles v2.
-- Stages: 1 find the depot -> 2 recover the alternator -> 3 battery + fuel + ignition -> 4 drive it to a claimed safehouse (or trade the lead)
-- Solutions: restore (solo-friendly, long) | trade (hand the lead to the raiders: rep + cache, bus goes to them)
local O = function() return exports.outbreak_opportunities end
local ID = 'armored_bus'
local Cfg = {
  depot = vec3(-1175.6, -1541.9, 4.4), depotHeading = 125.0, model = 'pbus', plate = 'ROUTE14',
  partItem = 'bus_alternator', partSources = { camp = 'quarry', barter = { give = { 'engine_parts', 3 }, get = { 'bus_alternator', 1 } } },
  homeRadius = 40.0, tradeRep = 12, restoreRep = 6, cooldownMinutes = 0, repeatable = false,
}
local function transmit(t, title) pcall(function() exports.outbreak_radio:transmit(0, title or 'STATIC', t) end) end

O():registerOpportunity({
  id = ID, title = 'The Route 14 bus', trigger = 'bus_manifest', intel = { 'bus_photo', 'bus_manifest' },
  summary = 'A city bus someone armored before the fall, rotting at a depot south of the airport. It wants a heavy alternator, a battery, fuel, and a driver with nerve.',
  stages = { { label = 'Find the depot' }, { label = 'Recover a heavy alternator' }, { label = 'Battery, fuel, splice the ignition' }, { label = 'Bring it home (park it at a claimed safehouse)' } },
  solutions = {
    { id = 'restore', label = 'Restore it', desc = 'Alternator from the Quarry raider cache — or trade 3 engine parts to the Quartermaster. Then battery, fuel, splice. Then drive it home.', solo = true },
    { id = 'trade',   label = 'Trade the lead to the raiders', desc = 'Tell the Boneyard where it is. They take the bus. You get their cache open and their goodwill.', solo = true },
  },
  cooldownMinutes = Cfg.cooldownMinutes, repeatable = Cfg.repeatable,

  onStart = function(r, src)
    r.data.spawned = false
    O():advance(ID, 2, src, {})
  end,
  onStage = function(r, stage)
    if stage == 2 and not r.data.spawned then
      -- the bus exists in the world now, managed by vehicles v2: locked, dead battery, no fuel, missing the alternator
      local ent, netId = exports.outbreak_vehicles:spawnManaged(Cfg.model, Cfg.depot, Cfg.depotHeading, Cfg.plate,
        { part = Cfg.partItem, battery = 'dead', fuel = 0, locked = true, noise = 1.6, burn = 2.4, data = { armored = true } })
      r.data.spawned = ent ~= nil; r.data.netId = netId
      O():setData(ID, 'spawned', r.data.spawned)
      TriggerClientEvent('outbreak:opp:bus:spawned', -1, netId)
    end
  end,
  onRestore = function(r)
    if r.data.spawned and not exports.outbreak_vehicles:get(Cfg.plate) then
      -- vehicles v2 respawns CLAIMED vehicles; an unclaimed bus must be respawned by the chain
      local ent, netId = exports.outbreak_vehicles:spawnManaged(Cfg.model, Cfg.depot, Cfg.depotHeading, Cfg.plate, { part = Cfg.partItem, battery = 'dead', fuel = 0, locked = true, noise = 1.6, burn = 2.4, data = { armored = true } })
      r.data.netId = netId
    end
  end,
  onChoose = function(r, src, sol)
    if sol == 'trade' then
      if r.stage >= 4 then return false end
      pcall(function() exports.outbreak_faction:addRep(src, 'raider', Cfg.tradeRep, 'sold the route 14 lead') end)
      pcall(function() exports.outbreak_faction:addRep(src, 'civilian', -4, 'armed the raiders') end)
      transmit('...Boneyard, Boneyard, we got a location on that bus. Roll heavy.', 'RAIDER NET')
      exports.outbreak_vehicles:set(Cfg.plate, { claimed = true, owner = 'raiders', locked = true, hotwired = true, battery = 'ok', part = false, fuel = 60 }, 'traded to raiders')
      exports.outbreak_intel:obsolete('bus_manifest', 'traded')
      pcall(function() exports.ox_inventory:forceOpenInventory(src, 'stash', 'camp_boneyard') end)
      O():resolve(ID, 'traded', { by = src })
    end
    return true
  end,
  -- progress is observed, not reported: the watcher reads vehicles v2 state
  onReport = function() end,
  onResolve = function(r, state, outcome)
    if outcome == 'restored' then transmit('...someone\'s got the Route 14 running. You can hear it from Vespucci. God help them.') end
  end,
  debug = { part = function(r, src) exports.outbreak_intel:giveDocument(src, 'bus_photo'); exports.outbreak_intel:giveDocument(src, 'bus_manifest'); exports.ox_inventory:AddItem(src, Cfg.partItem, 1) end },
})

-- watcher: stage advances follow the bus's actual state (server truth), home = parked inside a claimed safehouse radius
CreateThread(function()
  while true do
    Wait(10000)
    local r = O():get(ID)
    if r and r.state == 'active' then
      local v = exports.outbreak_vehicles:get(Cfg.plate)
      if v then
        if r.stage == 2 and v.part == false then O():advance(ID, 3, nil, {}) end
        if r.stage == 3 and v.battery == 'ok' and v.fuel > 0 and v.hotwired then O():advance(ID, 4, nil, {}) end
        if r.stage == 4 and v.claimed and v.netId then
          local ent = NetworkGetEntityFromNetworkId(v.netId)
          if ent and ent ~= 0 and DoesEntityExist(ent) then
            local pos = GetEntityCoords(ent)
            local home = false
            pcall(function() home = exports.outbreak_housing:isNearClaimedHouse(pos, Cfg.homeRadius) end)
            if home then
              for c in pairs(O():participants(ID)) do local s = GetSrcByCid(c); if s then pcall(function() exports.outbreak_faction:addRep(s, 'civilian', Cfg.restoreRep, 'restored the route 14') end) end end
              O():resolve(ID, 'restored', { plate = Cfg.plate })
            end
          end
        end
      end
    end
  end
end)

-- part sources: Quarry camp cache seeds an alternator when cleared (extended camps) — soft hook
AddEventHandler('outbreak:camps:cleared', function(campId, stash)
  if campId == Cfg.partSources.camp then pcall(function() exports.ox_inventory:AddItem(stash, Cfg.partItem, 1) end) end
end)
