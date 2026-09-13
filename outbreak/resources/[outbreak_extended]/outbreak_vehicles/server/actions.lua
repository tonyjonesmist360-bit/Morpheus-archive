-- outbreak_vehicles/server/actions.lua — every mutation is validated here. Clients only ask.
local QBCore = exports['qb-core']:GetCoreObject()
local S = function() return exports.outbreak_vehicles end
local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
local function notify(src, t, ty) TriggerClientEvent('ox_lib:notify', src, { title = t, type = ty or 'inform' }) end
local function near(src, netId, maxD)
  local ent = NetworkGetEntityFromNetworkId(netId); if not ent or ent == 0 or not DoesEntityExist(ent) then return nil end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(ent)) > (maxD or 6.0) then return nil end
  return ent
end
local function hasKey(src, plate)
  for _, s in ipairs(exports.ox_inventory:Search(src, 'slots', VehCfg.KeyItem) or {}) do if s.metadata and s.metadata.plate == plate then return true end end
  return false
end
local function has(src, item, n) return exports.ox_inventory:GetItemCount(src, item) >= (n or 1) end

-- lock / unlock with a key
RegisterNetEvent('outbreak:veh:toggleLock', function(netId)
  local src = source; local ent = near(src, netId); if not ent then return end
  local v, plate = S():byNet(netId); if not v then return end
  if not hasKey(src, plate) then notify(src, 'No key for this one.', 'error') return end
  S():set(plate, { locked = not v.locked }, 'key')
  notify(src, v.locked and 'Unlocked.' or 'Locked.')
end)

-- pry (client won the pry minigame — trust gap #1; server still requires the crowbar and proximity)
RegisterNetEvent('outbreak:veh:pried', function(netId)
  local src = source; local ent = near(src, netId); if not ent then return end
  local v, plate = S():byNet(netId); if not v or not v.locked then return end
  if not has(src, VehCfg.LockpickItem) then return end
  S():set(plate, { locked = false }, 'pried')
  -- glovebox key?
  if v.keyInside then
    v.keyInside = false
    exports.ox_inventory:AddItem(src, VehCfg.KeyItem, 1, { plate = plate, description = 'Key · ' .. plate })
    notify(src, 'Keys in the glovebox. Lucky.', 'success')
  end
end)

-- hotwire (client won splice — trust gap; server requires unlocked + no key needed)
RegisterNetEvent('outbreak:veh:hotwired', function(netId)
  local src = source; local ent = near(src, netId); if not ent then return end
  local v, plate = S():byNet(netId); if not v or v.hotwired then return end
  if v.locked then return end
  S():set(plate, { hotwired = true }, 'hotwired')
  pcall(function() exports.outbreak_skills:grantXP(src, 'hotwire') end)
end)

-- battery
RegisterNetEvent('outbreak:veh:battery', function(netId)
  local src = source; local ent = near(src, netId); if not ent then return end
  local v, plate = S():byNet(netId); if not v or v.battery ~= 'dead' then return end
  if not exports.ox_inventory:RemoveItem(src, VehCfg.BatteryItem, 1) then notify(src, 'You need a battery.', 'error') return end
  S():set(plate, { battery = 'ok' }, 'battery'); notify(src, 'It cranks. It lives.', 'success')
  pcall(function() exports.outbreak_skills:grantXP(src, 'battery') end)
end)

-- part
RegisterNetEvent('outbreak:veh:part', function(netId)
  local src = source; local ent = near(src, netId); if not ent then return end
  local v, plate = S():byNet(netId); if not v or not v.part then return end
  if not exports.ox_inventory:RemoveItem(src, v.part, 1) then notify(src, 'Missing: ' .. v.part:gsub('_', ' '), 'error') return end
  local lvl = 0; pcall(function() lvl = exports.outbreak_skills:getLevel(src, 'mechanics') end)
  if math.random() < lvl * 0.04 then exports.ox_inventory:AddItem(src, v.part, 1); notify(src, 'You saved the old part. Handy.', 'success') end
  S():set(plate, { part = false }, 'part fitted'); notify(src, 'Fitted. Good enough to roll.', 'success')
  pcall(function() exports.outbreak_skills:grantXP(src, 'repair') end)
end)

-- siphon: vehicle -> can (metadata)
RegisterNetEvent('outbreak:veh:siphon', function(netId)
  local src = source; local ent = near(src, netId); if not ent then return end
  local v, plate = S():byNet(netId); if not v then return end
  if not has(src, VehCfg.SiphonItem) then notify(src, 'You need a hose.', 'error') return end
  local canName = v.boat and VehCfg.MarineCanItem or VehCfg.CanItem
  local slot = (exports.ox_inventory:Search(src, 'slots', canName) or {})[1]
  if not slot then notify(src, v.boat and 'You need a marine fuel can.' or 'Nothing to catch it in.', 'error') return end
  if v.fuel < 1 then notify(src, 'Tank\'s dry.', 'error') return end
  local have = slot.metadata and slot.metadata.fuel or 0
  local take = math.min(v.fuel, math.random(VehCfg.SiphonYield[1], VehCfg.SiphonYield[2]), VehCfg.PourMax - have)
  if take <= 0 then notify(src, 'The can is full.', 'error') return end
  S():set(plate, { fuel = v.fuel - take }, 'siphoned')
  exports.ox_inventory:SetMetadata(src, slot.slot, { fuel = have + take, description = ('Contains ~%d%% of a tank'):format(have + take) })
  notify(src, ('Siphoned ~%d%%.'):format(math.floor(take)), 'success')
end)

-- pour: can -> vehicle (useable item)
for _, canName in ipairs({ VehCfg.CanItem, VehCfg.MarineCanItem }) do
  QBCore.Functions.CreateUseableItem(canName, function(src, item)
    local pct = item and item.metadata and item.metadata.fuel or 0
    if pct < 1 then notify(src, 'The can is empty.', 'error') return end
    TriggerClientEvent('outbreak:veh:askPourTarget', src, item.slot, pct, canName)
  end)
end
RegisterNetEvent('outbreak:veh:pour', function(netId, slot, canName)
  local src = source; local ent = near(src, netId, 4.0); if not ent then return end
  local v, plate = S():byNet(netId); if not v then return end
  canName = canName == VehCfg.MarineCanItem and VehCfg.MarineCanItem or VehCfg.CanItem
  if (v.boat and canName ~= VehCfg.MarineCanItem) then notify(src, 'That\'s not marine fuel. It\'ll kill the outboard.', 'error') return end
  if (not v.boat and canName == VehCfg.MarineCanItem) then notify(src, 'Marine fuel in a car? No.', 'error') return end
  local s = (exports.ox_inventory:Search(src, 'slots', canName) or {})[1]
  if not s or s.slot ~= slot then return end
  local pct = s.metadata and s.metadata.fuel or 0; if pct < 1 then return end
  local room = 100 - v.fuel; local pour = math.min(pct, room)
  S():set(plate, { fuel = v.fuel + pour }, 'poured')
  exports.ox_inventory:SetMetadata(src, s.slot, { fuel = pct - pour, description = pct - pour > 0 and ('Contains ~%d%% of a tank'):format(pct - pour) or 'Empty' })
  notify(src, ('Fuel in the tank (+%d%%).'):format(math.floor(pour)), 'success')
end)

-- claim: a running, hotwired vehicle can be claimed with a key blank -> it persists across restarts
RegisterNetEvent('outbreak:veh:claim', function(netId)
  local src = source; local ent = near(src, netId); if not ent then return end
  local v, plate = S():byNet(netId); if not v or v.claimed then return end
  if not exports.ox_inventory:RemoveItem(src, 'key_blank', 1) then notify(src, 'You need a key blank to cut a key.', 'error') return end
  exports.ox_inventory:AddItem(src, VehCfg.KeyItem, 1, { plate = plate, description = 'Key · ' .. plate })
  S():set(plate, { claimed = true, owner = cid(src) }, 'claimed')
  notify(src, 'It\'s yours now. It\'ll be where you left it.', 'success')
end)

-- engine gate: the CLIENT asks whether the engine may run; the server answers from state (cheap, cached by statebag anyway)
lib.callback.register('outbreak:veh:mayRun', function(src, netId)
  local v = S():byNet(netId); if not v then return false, 'unknown' end
  if v.battery == 'dead' then return false, 'battery' end
  if v.part then return false, 'part' end
  if not v.hotwired and not hasKey(src, (select(2, S():byNet(netId)))) then return false, 'ignition' end
  if v.fuel <= 0 then return false, 'fuel' end
  return true
end)
