-- outbreak_camps/server/camps.lua
local cleared = {} -- camp id -> os.time()

CreateThread(function()
  for _, c in ipairs(CampCfg.Camps) do
    exports.ox_inventory:RegisterStash(c.stash, c.label .. ' Cache', 24, 120000, nil)
  end
  exports.ox_inventory:RegisterStash(CampCfg.Convoy.cargoStash, 'Convoy Cargo', CampCfg.Convoy.cargoSlots, 100000, nil)
end)

local function restock(stash, table_)
  for _, it in pairs(exports.ox_inventory:GetInventoryItems(stash) or {}) do
    if it and it.name then exports.ox_inventory:RemoveItem(stash, it.name, it.count, nil, it.slot) end
  end
  for _, l in ipairs(table_) do exports.ox_inventory:AddItem(stash, l[1], l[2]) end
end

RegisterNetEvent('outbreak:server:campCleared', function(id, token)
  do local ok = exports.outbreak_minigames:consume(source, token, 'camp:crack:' .. tostring(id)); if not ok then return end end  -- Q1
  local c
  for _, x in ipairs(CampCfg.Camps) do if x.id == id then c = x end end
  if not c then return end
  local last = cleared[id]
  if not last or os.time() - last > CampCfg.RespawnMinutes * 60 then
    cleared[id] = os.time()
    restock(c.stash, CampCfg.Loot)
  end
  TriggerEvent('outbreak:camps:cleared', id, c.stash)
  exports.ox_inventory:forceOpenInventory(source, 'stash', c.stash)
end)

lib.callback.register('outbreak:campState', function(src, id)
  local last = cleared[id]
  return { garrisoned = not last or os.time() - last > CampCfg.RespawnMinutes * 60 }
end)

-- Convoy scheduler: one client "owns" it (the nearest player to the start), server just seeds
CreateThread(function()
  while true do
    Wait(math.random(CampCfg.Convoy.everyMinutes[1], CampCfg.Convoy.everyMinutes[2]) * 60000)
    local players = GetPlayers()
    if #players > 0 then
      restock(CampCfg.Convoy.cargoStash, CampCfg.Convoy.cargo)
      local dir = math.random(2)
      TriggerClientEvent('outbreak:client:convoy', players[math.random(#players)], dir)
      TriggerClientEvent('outbreak:client:radioMsg', -1, 7, 'MILITARY NET', 'Convoy rolling. Route 68. All units, eyes open.')
    end
  end
end)

RegisterNetEvent('outbreak:server:convoyLooted', function(token)
  do local ok = exports.outbreak_minigames:consume(source, token, 'convoy:loot'); if not ok then return end end  -- Q1
  exports.ox_inventory:forceOpenInventory(source, 'stash', CampCfg.Convoy.cargoStash)
end)
