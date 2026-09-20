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

-- ── JOIN / LEAVE in the world (v0.22). The armory / cache target asks; rep decides. ──
local lastSwitch = {}
local function standingWord(v)
  for _, b in ipairs(FactionCfg.Standing) do if v <= b[1] then return b[2] end end
  return 'kin'
end
RegisterNetEvent('outbreak:server:joinFaction', function(which)
  local src = source
  local F = which == 'military' and FactionCfg.Military or which == 'raider' and FactionCfg.Raider or nil
  if not F then return end
  local p = QBCore.Functions.GetPlayer(src); if not p then return end
  local cur = jobOf(src)
  if cur == F.job then TriggerClientEvent('ox_lib:notify', src, { title = 'You already are.', type = 'inform' }) return end
  if lastSwitch[src] and os.time() - lastSwitch[src] < FactionCfg.Join.cooldownMinutes * 60 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Not so fast.', description = 'You just changed sides. Give it a while.', type = 'error' }) return
  end
  local r = exports.outbreak_faction:getRep(src, which)
  if r < FactionCfg.Join.minRep then TriggerClientEvent('ox_lib:notify', src, { title = 'They will not have you.', description = ('%s: %s.'):format(FactionCfg.Names[which], standingWord(r)), type = 'error' }) return end
  if cur == 'military' or cur == 'raider' then exports.outbreak_faction:addRep(src, cur, -FactionCfg.Join.leaveRepCost, 'walked out') end
  p.Functions.SetJob(F.job, 0)
  lastSwitch[src] = os.time()
  pcall(function() exports.outbreak_log:log('faction.join', src, { which = which, from = cur }) end)
  TriggerClientEvent('outbreak:radio:learn', src, F.radioChannel, FactionCfg.Names[which] .. ' net. Theirs, now yours.')
  TriggerClientEvent('ox_lib:notify', src, { title = 'You are with ' .. FactionCfg.Names[which] .. ' now.', description = 'Their channel is yours. So are their enemies.', type = 'success', duration = 8000 })
  print(('^5[OB-FACTION]^7 %s joined %s'):format(GetPlayerName(src), which))
end)
RegisterNetEvent('outbreak:server:leaveFaction', function()
  local src = source; local cur = jobOf(src)
  if cur ~= 'military' and cur ~= 'raider' then return end
  local p = QBCore.Functions.GetPlayer(src); if not p then return end
  exports.outbreak_faction:addRep(src, cur, -FactionCfg.Join.leaveRepCost, 'walked out')
  p.Functions.SetJob('unemployed', 0)
  lastSwitch[src] = os.time()
  pcall(function() exports.outbreak_log:log('faction.leave', src, { from = cur }) end)
  TriggerClientEvent('ox_lib:notify', src, { title = 'On your own again.', type = 'inform' })
end)
-- standings read-model for the journal and F1: every faction, number + word
lib.callback.register('outbreak:faction:standings', function(src)
  local out = {}
  for _, f in ipairs({ 'military', 'raider', 'enclave' }) do
    local v = exports.outbreak_faction:getRep(src, f)
    out[#out + 1] = { id = f, name = FactionCfg.Names[f], value = v, word = standingWord(v), blurb = FactionCfg.Blurbs[f], mine = jobOf(src) == f }
  end
  return out
end)
exports('standingWord', standingWord)

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
  pcall(function() exports.outbreak_log:log('faction.standing_change', src, { faction = f, delta = delta, value = rep[src][f], reason = reason }) end)
  TriggerClientEvent('outbreak:client:rep', src, f, rep[src][f], reason)
  return rep[src][f]
end)
