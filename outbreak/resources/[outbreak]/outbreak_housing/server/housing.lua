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
  pcall(function() exports.outbreak_log:log('house.claim', src, { house = id }) end)
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
  if exports.ox_inventory:GetItemCount(src, 'barricade_kit') >= 1 then   -- a bench-made kit is one level, ready to hang
    exports.ox_inventory:RemoveItem(src, 'barricade_kit', 1)
  else
    for item, n in pairs(HousingCfg.BarricadeCost) do
      if exports.ox_inventory:GetItemCount(src, item) < n then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Missing materials.', description = 'Two planks and nails, or a barricade kit from a workbench.', type = 'error' }); return end
    end
    for item, n in pairs(HousingCfg.BarricadeCost) do exports.ox_inventory:RemoveItem(src, item, n) end
  end
  h.barricade = h.barricade + 1; save(id)
  TriggerClientEvent('outbreak:client:barricadeLevel', -1, id, h.barricade)
  TriggerClientEvent('ox_lib:notify', src, { title = ('Barricade level %d.'):format(h.barricade), type = 'success' })
end)

-- Searching a house spot: routed through the loot service so cooldowns persist across restarts
RegisterNetEvent('outbreak:server:houseSearch', function(id, spotIdx)
  local src = source
  local h = houses[id]; local spot = HousingCfg.SearchSpots[spotIdx]; if not h or not spot then return end
  if h.owner and not hasKey(src, id) then return end  -- owned house: keyholders only (forced entry is the stash, not the drawers)
  local hc; for _, x in ipairs(HousingCfg.Houses) do if x.id == id then hc = x end end
  if hc and hc.interior then return end  -- interior houses are searched inside, at their spots
  exports.outbreak_items:search(src, ('house_%s_%d'):format(id, spotIdx), spot.table, spot.name)
end)

-- ── INTERIOR SPOTS (v0.23): DB rows, seeded from config, published as a GlobalState read-model ──
local Spots = {}   -- id -> { id, house, name, tbl, pos }
local function publishSpots()
  local out = {}
  for id, s in pairs(Spots) do out[#out + 1] = { id = id, house = s.house, name = s.name, tbl = s.tbl, x = s.pos.x, y = s.pos.y, z = s.pos.z } end
  GlobalState.obHouseSpots = out
end
CreateThread(function()
  Wait(500)
  for _, r in ipairs(MySQL.query.await('SELECT * FROM outbreak_house_spots') or {}) do
    Spots[r.id] = { id = r.id, house = r.house_id, name = r.name, tbl = r.tbl, pos = vector3(r.x, r.y, r.z) }
  end
  -- seed: every interior house with no rows yet gets the default spread around its anchor
  for _, h in ipairs(HousingCfg.Houses) do
    if h.interior then
      local has = false; for _, s in pairs(Spots) do if s.house == h.id then has = true break end end
      if not has then
        for _, d in ipairs(HousingCfg.InteriorSpotDefaults or {}) do
          local pos = vector3(h.interior.x + d.dx, h.interior.y + d.dy, h.interior.z)
          local id = MySQL.insert.await('INSERT INTO outbreak_house_spots (house_id, name, tbl, x, y, z) VALUES (?, ?, ?, ?, ?, ?)', { h.id, d.name, d.table, pos.x, pos.y, pos.z })
          if id then Spots[id] = { id = id, house = h.id, name = d.name, tbl = d.table, pos = pos } end
        end
      end
    end
  end
  publishSpots()
end)
RegisterNetEvent('outbreak:server:spotSearch', function(spotId)
  local src = source; local s = Spots[spotId]; if not s then return end
  local h = houses[s.house]; if not h then return end
  if h.owner and not hasKey(src, s.house) then TriggerClientEvent('ox_lib:notify', src, { title = 'Not your house.', type = 'error' }) return end
  if #(GetEntityCoords(GetPlayerPed(src)) - s.pos) > (HousingCfg.SpotRadius or 1.6) + 2.5 then return end
  exports.outbreak_items:search(src, ('spot_%d'):format(spotId), s.tbl, s.name)
end)
-- /ob_spot <house_id> <table> <name...>  (debug ace): place or move a spot where you stand. /ob_spot_del <id>.
local function spotAllowed(src) return src == 0 or IsPlayerAceAllowed(src, 'outbreak.debug') or IsPlayerAceAllowed(src, 'outbreak.dm') end
RegisterCommand('ob_spot', function(src, a)
  if not spotAllowed(src) or src == 0 then return end
  local house, tbl = a[1], a[2]; local name = #a > 2 and table.concat(a, ' ', 3) or nil
  if not house or not tbl or not name or not houses[house] then TriggerClientEvent('ox_lib:notify', src, { title = 'Usage: /ob_spot <house_id> <house|medical|tools|trash> <name>', type = 'error' }) return end
  local pos = GetEntityCoords(GetPlayerPed(src))
  local existing; for id, s in pairs(Spots) do if s.house == house and s.name == name then existing = id end end
  if existing then
    MySQL.update('UPDATE outbreak_house_spots SET tbl = ?, x = ?, y = ?, z = ? WHERE id = ?', { tbl, pos.x, pos.y, pos.z, existing })
    Spots[existing].tbl = tbl; Spots[existing].pos = pos
  else
    local id = MySQL.insert.await('INSERT INTO outbreak_house_spots (house_id, name, tbl, x, y, z) VALUES (?, ?, ?, ?, ?, ?)', { house, name, tbl, pos.x, pos.y, pos.z })
    Spots[id] = { id = id, house = house, name = name, tbl = tbl, pos = pos }
  end
  publishSpots()
  TriggerClientEvent('ox_lib:notify', src, { title = (existing and 'Moved: ' or 'Placed: ') .. name, description = house .. ' · ' .. tbl, type = 'success' })
  pcall(function() exports.outbreak_log:log('house.spot', src, { house = house, name = name, tbl = tbl, x = pos.x, y = pos.y, z = pos.z }) end)
end, false)
RegisterCommand('ob_spot_del', function(src, a)
  if not spotAllowed(src) then return end
  local id = tonumber(a[1]); if not id or not Spots[id] then return end
  MySQL.update('DELETE FROM outbreak_house_spots WHERE id = ?', { id }); Spots[id] = nil; publishSpots()
  if src ~= 0 then TriggerClientEvent('ox_lib:notify', src, { title = 'Spot removed.', type = 'inform' }) end
end, false)
exports('spots', function() return Spots end)

-- The tap: a trickle of murky water for keyholders, rate-limited per house per hour.
local tap = {}   -- house_id -> { hour = floor(os.time()/3600), n = draws }
RegisterNetEvent('outbreak:server:tapWater', function(id)
  local src = source
  if not houses[id] or not hasKey(src, id) then return end
  local hour = math.floor(os.time() / 3600)
  local t = tap[id]; if not t or t.hour ~= hour then t = { hour = hour, n = 0 }; tap[id] = t end
  if t.n >= (HousingCfg.TapPerHour or 4) then TriggerClientEvent('ox_lib:notify', src, { title = 'Dry. It coughs air.', description = 'Give it an hour.', type = 'error' }) return end
  if exports.ox_inventory:AddItem(src, 'water_dirty', 1) then t.n = t.n + 1; TriggerClientEvent('ox_lib:notify', src, { title = 'Murky water.', description = 'Boil it before it counts.', type = 'inform' }) end
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
exports('damageBarricade', function(id, n)
  local h = houses[id]; if not h then return 0 end
  h.barricade = math.max(0, (h.barricade or 0) - (n or 1)); save(id)
  TriggerClientEvent('outbreak:client:barricadeLevel', -1, id, h.barricade)
  return h.barricade
end)
exports('houses', function() local out = {}; for _, h in ipairs(HousingCfg.Houses) do out[#out + 1] = { id = h.id, label = h.label, door = h.door } end return out end)
exports('releaseHouse', function(id) local h = houses[id]; if h then h.owner = nil; save(id) end end)
exports('isNearClaimedHouse', function(pos, radius)
  for id, h in pairs(houses) do
    if h.owner then local c = cfg(id); if c and #(pos - c.door) <= (radius or 40.0) then return true, id end end
  end
  return false
end)
