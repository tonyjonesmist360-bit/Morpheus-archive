-- outbreak_housing/server/housing.lua  (v2: keys as items, interiors, no money)
local QBCore = exports['qb-core']:GetCoreObject()
local houses = {}

local function cfg(id) for _, h in ipairs(HousingCfg.Houses) do if h.id == id then return h end end end

CreateThread(function()
  local rows = MySQL.query.await('SELECT * FROM outbreak_houses') or {}
  for _, r in ipairs(rows) do houses[r.house_id] = { owner = r.owner, barricade = r.barricade, visited = r.visited == 1 } end
  for _, h in ipairs(HousingCfg.Houses) do
    houses[h.id] = houses[h.id] or { owner = h.preOwned, barricade = 0, visited = h.preOwned ~= nil }
    exports.ox_inventory:RegisterStash('safehouse_' .. h.id, h.label .. ' Storage', HousingCfg.StashSlots, HousingCfg.StashWeight, nil)
  end
end)

local function save(id)
  local h = houses[id]
  MySQL.prepare([[INSERT INTO outbreak_houses (house_id, owner, barricade, visited) VALUES (?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE owner=VALUES(owner), barricade=VALUES(barricade), visited=VALUES(visited)]],
    { id, h.owner, h.barricade, h.visited and 1 or 0 })
end

local function hasKey(src, id)
  local slots = exports.ox_inventory:Search(src, 'slots', HousingCfg.KeyItem) or {}
  for _, s in ipairs(slots) do if s.metadata and s.metadata.house == id then return true end end
  return false
end

lib.callback.register('outbreak:houseInfo', function(src, id)
  local h = houses[id]; if not h then return nil end
  local roll, story = false, nil
  if not h.visited then
    h.visited = true; roll = math.random() < HousingCfg.OccupiedChance; save(id)
    if not roll then story = HousingCfg.Stories[math.random(#HousingCfg.Stories)] end
  end
  local p = QBCore.Functions.GetPlayer(src)
  return { owner = h.owner, barricade = h.barricade, occupiedRoll = roll, story = story,
           isMine = p and h.owner == p.PlayerData.citizenid, hasKey = hasKey(src, id) }
end)

RegisterNetEvent('outbreak:server:claimHouse', function(id)
  local src = source
  local h = houses[id]; if not h or h.owner then return end
  local p = QBCore.Functions.GetPlayer(src); if not p then return end
  h.owner = p.PlayerData.citizenid; save(id)
  local c = cfg(id)
  exports.ox_inventory:AddItem(src, HousingCfg.KeyItem, 1, { house = id, description = 'Key to ' .. c.label })
  TriggerClientEvent('ox_lib:notify', src, { title = 'Claimed. You pocket the key.', description = 'Hand copies to whoever you trust.', type = 'success' })
end)

-- Cut a spare key (owner only) — hand the item to a friend
RegisterNetEvent('outbreak:server:cutKey', function(id)
  local src = source
  local h = houses[id]; local p = QBCore.Functions.GetPlayer(src)
  if not h or not p or h.owner ~= p.PlayerData.citizenid then return end
  local c = cfg(id)
  exports.ox_inventory:AddItem(src, HousingCfg.KeyItem, 1, { house = id, description = 'Key to ' .. c.label })
end)

RegisterNetEvent('outbreak:server:openHouseStash', function(id)
  local src = source
  if not hasKey(src, id) then return end
  exports.ox_inventory:forceOpenInventory(src, 'stash', 'safehouse_' .. id)
end)

lib.callback.register('outbreak:houseEnter', function(src, id)
  return hasKey(src, id)
end)

RegisterNetEvent('outbreak:server:barricade', function(id)
  local src = source
  local h = houses[id]; if not h or h.barricade >= HousingCfg.MaxBarricadeLevel then return end
  if not hasKey(src, id) then return end
  if exports.ox_inventory:GetItemCount(src, 'hammer_tool') < 1 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'You need a hammer.', type = 'error' }); return end
  for item, n in pairs(HousingCfg.BarricadeCost) do
    if exports.ox_inventory:GetItemCount(src, item) < n then
      TriggerClientEvent('ox_lib:notify', src, { title = 'Missing materials.', type = 'error' }); return end
  end
  for item, n in pairs(HousingCfg.BarricadeCost) do exports.ox_inventory:RemoveItem(src, item, n) end
  h.barricade = h.barricade + 1; save(id)
  TriggerClientEvent('outbreak:client:barricadeLevel', -1, id, h.barricade)
  TriggerClientEvent('ox_lib:notify', src, { title = ('Barricade level %d.'):format(h.barricade), type = 'success' })
end)

-- Searching a house spot: routed through the loot service so cooldowns persist across restarts
RegisterNetEvent('outbreak:server:houseSearch', function(id, spotIdx)
  local src = source
  local h = houses[id]; local spot = HousingCfg.SearchSpots[spotIdx]; if not h or not spot then return end
  if h.owner and not hasKey(src, id) then return end  -- owned house: keyholders only (forced entry is the stash, not the drawers)
  exports.outbreak_items:search(src, ('house_%s_%d'):format(id, spotIdx), spot.table)
end)

-- Permadeath hook: a dead owner's house goes back on the market (their key rots with them)
AddEventHandler('outbreak:server:characterDied', function(citizenid)
  for id, h in pairs(houses) do
    if h.owner == citizenid then h.owner = nil; save(id) end
  end
end)

-- Forced entry: the minigame was won client-side; server grants a one-time stash open
RegisterNetEvent('outbreak:server:forcedEntry', function(id)
  local src = source
  if not houses[id] then return end
  exports.ox_inventory:forceOpenInventory(src, 'stash', 'safehouse_' .. id)
end)

exports('hasKey', hasKey)
-- Read model for outbreak_supply / outbreak_director: owner + barricade, never the table itself.
exports('getHouse', function(id) local h = houses[id]; return h and { owner = h.owner, barricade = h.barricade } or nil end)
exports('houses', function() local out = {}; for _, h in ipairs(HousingCfg.Houses) do out[#out + 1] = { id = h.id, label = h.label, door = h.door } end return out end)
exports('releaseHouse', function(id) local h = houses[id]; if h then h.owner = nil; save(id) end end)
exports('isNearClaimedHouse', function(pos, radius)
  for id, h in pairs(houses) do
    if h.owner then local c = cfg(id); if c and #(pos - c.door) <= (radius or 40.0) then return true, id end end
  end
  return false
end)
