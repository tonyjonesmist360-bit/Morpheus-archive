-- outbreak_identity/server/identity.lua
local QBCore = exports['qb-core']:GetCoreObject()

local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end

lib.callback.register('outbreak:identity:get', function(src, target)
  local id = cid(target or src); if not id then return nil end
  return MySQL.single.await('SELECT callsign, former, description, traits FROM outbreak_identity WHERE citizenid = ?', { id })
end)

RegisterNetEvent('outbreak:server:saveIdentity', function(data)
  local src = source
  local id = cid(src); if not id then return end
  MySQL.prepare([[INSERT INTO outbreak_identity (citizenid, callsign, former, description, traits) VALUES (?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE callsign=VALUES(callsign), former=VALUES(former), description=VALUES(description), traits=VALUES(traits)]],
    { id, data.callsign, data.former, data.description, json.encode(data.traits) })
  TriggerEvent('outbreak:server:traitsSet', src, data.traits)   -- outbreak_skills listens
end)

-- fresh spawn -> creator flow (fires after outbreak_spawn's story fade)
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
  local src = player.PlayerData.source
  local row = MySQL.single.await('SELECT 1 FROM outbreak_identity WHERE citizenid = ?', { player.PlayerData.citizenid })
  if not row then SetTimeout(12000, function() TriggerClientEvent('outbreak:client:createSurvivor', src) end) end
end)

RegisterNetEvent('outbreak:server:me', function(text)
  if type(text) ~= 'string' or #text > 140 then return end
  TriggerClientEvent('outbreak:client:me', -1, source, text)
end)
