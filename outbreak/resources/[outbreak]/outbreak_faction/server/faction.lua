-- outbreak_faction/server/faction.lua
local QBCore = exports['qb-core']:GetCoreObject()

local function jobOf(src)
  local p = QBCore.Functions.GetPlayer(src)
  return p and p.PlayerData.job and p.PlayerData.job.name or 'unemployed'
end

local function cid(src)
  local p = QBCore.Functions.GetPlayer(src)
  return p and p.PlayerData.citizenid
end

CreateThread(function()
  local M, R = FactionCfg.Military, FactionCfg.Raider
  exports.ox_inventory:RegisterStash(M.Armory.stash, 'Zancudo Armory', M.Armory.slots, M.Armory.weight, nil)
  exports.ox_inventory:RegisterStash(R.Camp.stash, 'Raider Cache', R.Camp.slots, R.Camp.weight, nil)
  -- seed armory once
  Wait(2000)
  local items = exports.ox_inventory:GetInventoryItems(M.Armory.stash) or {}
  if next(items) == nil then
    for _, s in ipairs(M.Seed) do exports.ox_inventory:AddItem(M.Armory.stash, s[1], s[2]) end
  end
end)

lib.callback.register('outbreak:faction:job', function(src) return jobOf(src) end)

RegisterNetEvent('outbreak:server:openFactionStash', function(which)
  local src = source
  local job = jobOf(src)
  local F = which == 'military' and FactionCfg.Military or FactionCfg.Raider
  if job ~= F.job then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Not your people.', type = 'error' })
    return
  end
  local stash = which == 'military' and F.Armory.stash or F.Camp.stash
  exports.ox_inventory:forceOpenInventory(src, 'stash', stash)
end)

-- Admin helpers (txAdmin console or /setfaction from an admin)
RegisterCommand('setfaction', function(src, args)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'command') then return end
  local target, job, grade = tonumber(args[1]), args[2], tonumber(args[3]) or 0
  local p = target and QBCore.Functions.GetPlayer(target)
  if not p or (job ~= 'military' and job ~= 'raider' and job ~= 'unemployed') then return end
  p.Functions.SetJob(job, grade)
  TriggerClientEvent('ox_lib:notify', target, { title = 'You are now: ' .. job, type = 'inform' })
end, true)

-- ── REPUTATION SERVICE ──
-- exports.outbreak_faction:getRep(src, 'military'|'raider'|'enclave')   -> number
-- exports.outbreak_faction:addRep(src, faction, delta, reason)           -> new value (server only)
local rep = {}
local function repLoad(src)
  local id = cid(src); if not id then return end
  rep[src] = {}
  for _, r in ipairs(MySQL.query.await('SELECT faction, value FROM outbreak_reputation WHERE citizenid = ?', { id }) or {}) do rep[src][r.faction] = r.value end
end
AddEventHandler('QBCore:Server:PlayerLoaded', function(player) repLoad(player.PlayerData.source) end)
AddEventHandler('playerDropped', function() rep[source] = nil end)
exports('getRep', function(src, f) return rep[src] and rep[src][f] or 0 end)
exports('addRep', function(src, f, delta, reason)
  local id = cid(src); if not id then return 0 end
  rep[src] = rep[src] or {}
  rep[src][f] = math.max(-100, math.min(100, (rep[src][f] or 0) + delta))
  MySQL.prepare('INSERT INTO outbreak_reputation (citizenid, faction, value) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE value = VALUES(value)', { id, f, rep[src][f] })
  if GlobalState.obDebug then print(('^5[OB-REP]^7 %s %s %+d (%s) -> %d'):format(id, f, delta, reason or '-', rep[src][f])) end
  TriggerClientEvent('outbreak:client:rep', src, f, rep[src][f], reason)
  return rep[src][f]
end)
