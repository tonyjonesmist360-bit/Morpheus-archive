-- outbreak_worlditems/server/worlditems.lua — server creates every world object; clients only ask and target.
local QBCore = exports['qb-core']:GetCoreObject()
local Items = {}   -- id -> { item, count, metadata, model, pos, rot, by, at, house, storage, locked, entity, netId }
local Hidden = {}  -- id -> { model, pos, item, at }  (taken map props)
local nextId = 1
local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
local function near(src, pos, d) return #(GetEntityCoords(GetPlayerPed(src)) - pos) <= (d or 4.0) end

local function spawn(rec)
  local ent = CreateObjectNoOffset(rec.model, rec.pos.x, rec.pos.y, rec.pos.z, true, true, false)
  if not ent or ent == 0 then return false end
  SetEntityRotation(ent, rec.rot.x, rec.rot.y, rec.rot.z, 2, true)
  FreezeEntityPosition(ent, true)
  rec.entity, rec.netId = ent, NetworkGetNetworkIdFromEntity(ent)
  Entity(ent).state:set('worldItem', { id = rec.id, item = rec.item, count = rec.count, storage = rec.storage, locked = rec.locked, note = rec.metadata and rec.metadata.text, intel = rec.metadata and rec.metadata.intel, by = rec.byName }, true)
  return true
end
local function save(rec)
  MySQL.prepare([[INSERT INTO outbreak_world_items (id, item, count, metadata, model, x, y, z, rx, ry, rz, placed_by, placed_at, house_id, storage, locked)
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,FROM_UNIXTIME(?),?,?,?) ON DUPLICATE KEY UPDATE locked=VALUES(locked), count=VALUES(count), metadata=VALUES(metadata)]],
    { rec.id, rec.item, rec.count, json.encode(rec.metadata or {}), rec.model, rec.pos.x, rec.pos.y, rec.pos.z, rec.rot.x, rec.rot.y, rec.rot.z, rec.by, rec.at, rec.house, rec.storage and 1 or 0, rec.locked and 1 or 0 })
end
local function remove(id, keepStash)
  local rec = Items[id]; if not rec then return end
  if rec.entity and DoesEntityExist(rec.entity) then DeleteEntity(rec.entity) end
  if rec.storage and not keepStash then pcall(function() exports.ox_inventory:ClearInventory('wi_' .. id) end) end
  Items[id] = nil
  MySQL.update('DELETE FROM outbreak_world_items WHERE id = ?', { id })
end

CreateThread(function()
  for _, r in ipairs(MySQL.query.await('SELECT *, UNIX_TIMESTAMP(placed_at) AS at_u FROM outbreak_world_items') or {}) do
    local rec = { id = r.id, item = r.item, count = r.count, metadata = json.decode(r.metadata or '{}'), model = r.model, pos = vector3(r.x, r.y, r.z), rot = vector3(r.rx, r.ry, r.rz), by = r.placed_by, at = r.at_u, house = r.house_id, storage = r.storage == 1, locked = r.locked == 1 }
    Items[rec.id] = rec; nextId = math.max(nextId, rec.id + 1)
    if rec.storage then local S = WorldItemsCfg.Storage[rec.item]; exports.ox_inventory:RegisterStash('wi_' .. rec.id, rec.item:gsub('_', ' '), S.slots, S.weight, nil) end
    spawn(rec)
  end
  for _, r in ipairs(MySQL.query.await('SELECT *, UNIX_TIMESTAMP(taken_at) AS at_u FROM outbreak_hidden_props') or {}) do
    Hidden[r.id] = { model = r.model, pos = vector3(r.x, r.y, r.z), item = r.item, at = r.at_u, shelf = WorldItemsCfg.Shelves[r.model] ~= nil }
  end
  GlobalState.obHiddenProps = Hidden
end)

local function placedBy(c) local n = 0 for _, r in pairs(Items) do if r.by == c then n = n + 1 end end return n end

-- PLACE: client validated the ghost, server validates the item + distance + limits, removes the item, creates the object
RegisterNetEvent('outbreak:wi:place', function(slot, pos, rot)
  local src = source; local c = cid(src); if not c then return end
  if type(pos) ~= 'vector3' or type(rot) ~= 'vector3' then return end
  if not near(src, pos, WorldItemsCfg.MaxDistance + 1.0) then return end
  if placedBy(c) >= WorldItemsCfg.MaxPlacedPerPlayer then TriggerClientEvent('ox_lib:notify', src, { title = 'You\'ve left enough of yourself around.', type = 'error' }) return end
  local it = exports.ox_inventory:GetSlot(src, slot); if not it or it.name:find('^WEAPON_') then return end
  local model = WorldItemsCfg.Models[it.name] or WorldItemsCfg.Fallback
  local count = WorldItemsCfg.Storage[it.name] and 1 or it.count
  if not exports.ox_inventory:RemoveItem(src, it.name, count, it.metadata, slot) then return end
  local house; pcall(function() local _, hid = exports.outbreak_housing:isNearClaimedHouse(pos, 25.0); house = hid end)
  local rec = { id = nextId, item = it.name, count = count, metadata = it.metadata or {}, model = joaat(model), pos = pos, rot = rot, by = c, byName = GetPlayerName(src), at = os.time(), house = house, storage = WorldItemsCfg.Storage[it.name] ~= nil, locked = false }
  nextId = nextId + 1
  if rec.storage then local S = WorldItemsCfg.Storage[it.name]; exports.ox_inventory:RegisterStash('wi_' .. rec.id, it.name:gsub('_', ' '), S.slots, S.weight, nil) end
  if spawn(rec) then Items[rec.id] = rec; save(rec) else exports.ox_inventory:AddItem(src, it.name, count, it.metadata) end
  if GlobalState.obDebug then print(('^5[OB-WI]^7 %s placed %s x%d @ %.1f,%.1f'):format(c, it.name, count, pos.x, pos.y)) end
end)

-- TAKE a placed item (anyone; inside a claimed house: keyholders only)
RegisterNetEvent('outbreak:wi:take', function(id)
  local src = source; local rec = Items[id]; if not rec or not near(src, rec.pos, 3.0) then return end
  if rec.house then
    local ok, allowed = pcall(function() return exports.outbreak_housing:hasKey(src, rec.house) end)
    if ok and not allowed and rec.by ~= cid(src) then TriggerClientEvent('ox_lib:notify', src, { title = 'Not yours to take. Not here.', type = 'error' }) return end
  end
  if rec.storage then
    if rec.locked then TriggerClientEvent('ox_lib:notify', src, { title = 'Padlocked.', type = 'error' }) return end
    if next(exports.ox_inventory:GetInventoryItems('wi_' .. id) or {}) ~= nil then TriggerClientEvent('ox_lib:notify', src, { title = 'Empty it first.', type = 'error' }) return end
  end
  if exports.ox_inventory:CanCarryItem(src, rec.item, rec.count) then
    exports.ox_inventory:AddItem(src, rec.item, rec.count, rec.metadata)
    remove(id)
  else TriggerClientEvent('ox_lib:notify', src, { title = 'Too heavy to carry right now.', type = 'error' }) end
end)

-- STORAGE open / lock / force
RegisterNetEvent('outbreak:wi:open', function(id)
  local src = source; local rec = Items[id]; if not rec or not rec.storage or not near(src, rec.pos, 3.0) then return end
  if rec.locked and rec.by ~= cid(src) then TriggerClientEvent('ox_lib:notify', src, { title = 'Padlocked.', type = 'error' }) return end
  exports.ox_inventory:forceOpenInventory(src, 'stash', 'wi_' .. id)
end)
RegisterNetEvent('outbreak:wi:lock', function(id)
  local src = source; local rec = Items[id]; if not rec or not rec.storage or not near(src, rec.pos, 3.0) then return end
  if rec.locked then
    if rec.by ~= cid(src) then return end
    rec.locked = false; exports.ox_inventory:AddItem(src, 'padlock', 1)
  else
    if not exports.ox_inventory:RemoveItem(src, 'padlock', 1) then TriggerClientEvent('ox_lib:notify', src, { title = 'You need a padlock.', type = 'error' }) return end
    rec.locked = true; rec.by = cid(src)
  end
  save(rec); Entity(rec.entity).state:set('worldItem', { id = rec.id, item = rec.item, count = rec.count, storage = true, locked = rec.locked, by = rec.byName }, true)
end)
RegisterNetEvent('outbreak:wi:forced', function(id)  -- pin sweep won client-side (trust gap #1)
  local src = source; local rec = Items[id]; if not rec or not rec.locked or not near(src, rec.pos, 3.0) then return end
  rec.locked = false; save(rec); Entity(rec.entity).state:set('worldItem', { id = rec.id, item = rec.item, count = rec.count, storage = true, locked = false, by = rec.byName }, true)
  exports.ox_inventory:forceOpenInventory(src, 'stash', 'wi_' .. id)
end)

-- NOTES: placing a 'note' with text; reading a placed document grants intel without consuming (environmental storytelling)
RegisterNetEvent('outbreak:wi:read', function(id)
  local src = source; local rec = Items[id]; if not rec or not near(src, rec.pos, 3.0) then return end
  if rec.item == 'document' and rec.metadata.intel and WorldItemsCfg.NotePlaceableAsIntel then
    pcall(function() exports.outbreak_intel:discover(src, rec.metadata.intel, nil, 'document') end)
  end
end)

-- TAKEABLE MAP PROPS: hide for everyone, persist, give the item
RegisterNetEvent('outbreak:wi:takeProp', function(model, pos)
  local src = source
  local t = WorldItemsCfg.Takeables[model] or WorldItemsCfg.Shelves[model]; if not t or type(pos) ~= 'vector3' or not near(src, pos, 4.0) then return end
  for _, h in pairs(Hidden) do if h.model == model and #(h.pos - pos) < 0.5 then return end end
  if not exports.ox_inventory:CanCarryItem(src, t.item, t.count) then TriggerClientEvent('ox_lib:notify', src, { title = 'Too heavy.', type = 'error' }) return end
  exports.ox_inventory:AddItem(src, t.item, t.count)
  local id = MySQL.insert.await('INSERT INTO outbreak_hidden_props (model, x, y, z, item, taken_at) VALUES (?, ?, ?, ?, ?, NOW())', { model, pos.x, pos.y, pos.z, t.item })
  Hidden[id] = { model = model, pos = pos, item = t.item, at = os.time(), shelf = WorldItemsCfg.Shelves[model] ~= nil }
  GlobalState.obHiddenProps = Hidden
end)

exports('list', function() return Items end)
exports('remove', remove)
exports('restoreProp', function(id)
  local h = Hidden[id]; Hidden[id] = nil
  MySQL.update('DELETE FROM outbreak_hidden_props WHERE id = ?', { id }); GlobalState.obHiddenProps = Hidden
  if h and h.shelf then TriggerClientEvent('outbreak:wi:restocked', -1, h.pos, h.item) end  -- the stocker walks in
end)
exports('hidden', function() return Hidden end)
exports('placeSystem', function(item, count, metadata, pos, rot, byName) -- chains/NPCs place things too (no owner)
  local model = (metadata and metadata.model) or WorldItemsCfg.Models[item] or WorldItemsCfg.Fallback
  local rec = { id = nextId, item = item, count = count or 1, metadata = metadata or {}, model = joaat(model), pos = pos, rot = rot or vector3(0, 0, 0), by = 'world', byName = byName or 'someone', at = os.time(), storage = WorldItemsCfg.Storage[item] ~= nil, locked = false }
  nextId = nextId + 1
  if rec.storage then local S = WorldItemsCfg.Storage[item]; exports.ox_inventory:RegisterStash('wi_' .. rec.id, item, S.slots, S.weight, nil) end
  if spawn(rec) then Items[rec.id] = rec; save(rec); return rec.id end
end)

RegisterNetEvent('outbreak:wi:writeNote', function(text)
  local src = source
  if type(text) ~= 'string' or #text > 220 then return end
  if exports.ox_inventory:GetItemCount(src, 'note') < 1 then TriggerClientEvent('ox_lib:notify', src, { title = 'You need a blank note.', type = 'error' }) return end
  local slot = (exports.ox_inventory:Search(src, 'slots', 'note') or {})[1]
  exports.ox_inventory:SetMetadata(src, slot.slot, { text = text, description = '"' .. text:sub(1, 40) .. (#text > 40 and '..."' or '"') })
  TriggerClientEvent('ox_lib:notify', src, { title = 'Written. Set it down somewhere it\'ll be found.', type = 'success' })
end)
