-- outbreak_down/server/down.lua
local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('outbreak:server:trySelfStabilize', function()
  local src = source
  local item = DownCfg.Incapacitated.selfStabilizeItem
  if exports.ox_inventory:GetItemCount(src, item) < 1 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'You need a ' .. item .. '.', type = 'error' })
    return
  end
  exports.ox_inventory:RemoveItem(src, item, 1)
  TriggerEvent('outbreak:server:grantXP', src, 'splint')
  TriggerClientEvent('outbreak:client:selfStabilizeOk', src)
end)

RegisterNetEvent('outbreak:server:helpPlayer', function(target, state)
  local src = source
  if state == 'incapacitated' then
    local item = DownCfg.Incapacitated.stabilizeItem
    if exports.ox_inventory:GetItemCount(src, item) < 1 then
      TriggerClientEvent('ox_lib:notify', src, { title = 'You need a ' .. item .. '.', type = 'error' })
      return
    end
    exports.ox_inventory:RemoveItem(src, item, 1)
    TriggerEvent('outbreak:server:grantXP', src, 'stabilize')
    TriggerClientEvent('outbreak:client:revived', target, 'stabilize')
  else
    TriggerClientEvent('outbreak:client:revived', target, 'shake')
  end
end)

local function daysSurvived(cid)
  local row = MySQL.single.await('SELECT TIMESTAMPDIFF(HOUR, first_spawn, NOW()) AS h FROM outbreak_players WHERE citizenid = ?', { cid })
  return row and math.floor((row.h or 0) / 24) or 0
end

-- Incapacitated timer ran out: permadeath mode -> CRITICAL, not death. Other modes -> old behaviour.
RegisterNetEvent('outbreak:server:incapExpired', function(cause)
  local src = source
  if Player(src).state.downState ~= 'incapacitated' then return end
  if DownCfg.DeathMode == 'permadeath' then
    TriggerClientEvent('outbreak:client:enterCritical', src)
    pcall(function() exports.outbreak_radio:transmit(0, 'STATIC', 'Someone\'s down bad out there. Get them to a medic.') end)
  else
    TriggerEvent('outbreak:server:bledOutInternal', src, cause)
  end
end)

-- Station treatment: server validates everything
RegisterNetEvent('outbreak:server:stationTreat', function(target, stationId)
  local src = source
  if Player(target).state.downState ~= 'critical' then return end
  local st
  for _, s in ipairs(DownCfg.Critical.Stations) do if s.id == stationId then st = s end end
  if not st then return end
  if #(GetEntityCoords(GetPlayerPed(target)) - st.pos) > st.radius + 2.0 then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - st.pos) > st.radius + 2.0 then return end
  for _, it in ipairs(DownCfg.Critical.treatItems) do
    if exports.ox_inventory:GetItemCount(src, it[1]) < it[2] then
      TriggerClientEvent('ox_lib:notify', src, { title = ('Need %dx %s'):format(it[2], it[1]:gsub('_', ' ')), type = 'error' }) return end
  end
  for _, it in ipairs(DownCfg.Critical.treatItems) do exports.ox_inventory:RemoveItem(src, it[1], it[2]) end
  local lvl = 0
  pcall(function() lvl = exports.outbreak_skills:getLevel(src, 'medicine') end)
  local ok = math.random() < DownCfg.Critical.baseChance + lvl * 0.03
  pcall(function() exports.outbreak_skills:grantXP(src, 'stabilize') end)
  TriggerClientEvent('outbreak:client:stationSaved', target, ok)
  TriggerClientEvent('ox_lib:notify', src, { title = ok and 'They\'re breathing steady.' or 'You lost them for a second. Try again — fast.', type = ok and 'success' or 'error' })
end)

-- Adrenaline: solo lifeline, only while incapacitated (registered here, not in items, because it needs the down statebag)
QBCore.Functions.CreateUseableItem(DownCfg.Adrenaline.item, function(src)
  if Player(src).state.downState ~= 'incapacitated' then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Not now. Save it for when you\'re going under.', type = 'inform' }) return end
  if exports.ox_inventory:RemoveItem(src, DownCfg.Adrenaline.item, 1) then
    TriggerClientEvent('outbreak:client:adrenaline', src)
    pcall(function() exports.outbreak_needs:consume(src, { fatigue = -DownCfg.Adrenaline.fatigueCost }) end)
  end
end)

-- Glitch insurance: admin revive (ace outbreak.admin; NOT debug-gated)
RegisterCommand('ob_revive', function(src, args)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.admin') then return end
  local t = tonumber(args[1]) or src
  TriggerClientEvent('outbreak:client:adminRevive', t)
  print(('^3[OB-ADMIN]^7 %s revived %s'):format(src == 0 and 'console' or GetPlayerName(src), t))
end, true)

-- Load/unload a carried critical/incapacitated player into a vehicle
RegisterNetEvent('outbreak:server:loadPatient', function(netId)
  local src = source
  local t = Player(src).state.carrying; if not t then return end
  Player(src).state:set('carrying', nil, true); Player(t).state:set('carriedBy', nil, true)
  TriggerClientEvent('outbreak:client:loadIntoVehicle', t, netId)
end)
RegisterNetEvent('outbreak:server:unloadPatient', function(target)
  local src = source
  if not Player(target).state.downState then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 6.0 then return end
  TriggerClientEvent('outbreak:client:unloadFromVehicle', target)
end)

RegisterNetEvent('outbreak:server:bledOut', function(cause) TriggerEvent('outbreak:server:bledOutInternal', source, cause) end)
AddEventHandler('outbreak:server:bledOutInternal', function(src, cause)
  local p = QBCore.Functions.GetPlayer(src); if not p then return end
  local cid = p.PlayerData.citizenid
  local name = (p.PlayerData.charinfo.firstname or '?') .. ' ' .. (p.PlayerData.charinfo.lastname or '')
  local mode = DownCfg.DeathMode

  if mode == 'keep' then TriggerClientEvent('outbreak:client:respawn', src) return end

  -- Corpse: everything they carried goes into a stash where they fell
  local ped = GetPlayerPed(src)
  local pos = GetEntityCoords(ped)
  local corpseId = ('corpse_%s_%d'):format(cid, os.time())
  exports.ox_inventory:RegisterStash(corpseId, 'Remains of ' .. name, 30, 100000, nil)
  for _, it in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
    if it and it.name then exports.ox_inventory:AddItem(corpseId, it.name, it.count, it.metadata) end
  end
  exports.ox_inventory:ClearInventory(src)
  MySQL.insert('INSERT INTO outbreak_corpses (stash_id, citizenid, name, x, y, z, died_at) VALUES (?, ?, ?, ?, ?, ?, NOW())',
    { corpseId, cid, name, pos.x, pos.y, pos.z })
  TriggerClientEvent('outbreak:client:corpseSpawned', -1, corpseId, name, pos)

  if mode == 'losegear' then TriggerClientEvent('outbreak:client:respawn', src) return end

  -- Permadeath: memorial, release holdings, retire the character
  local days = daysSurvived(cid)
  MySQL.insert('INSERT INTO outbreak_memorial (citizenid, name, days_survived, cause, died_at) VALUES (?, ?, ?, ?, NOW())',
    { cid, name, days, cause or 'unknown' })
  MySQL.update('UPDATE outbreak_players SET dead = 1 WHERE citizenid = ?', { cid })
  TriggerEvent('outbreak:server:characterDied', cid)
  TriggerClientEvent('ox_lib:notify', -1, { title = 'RADIO: ' .. name .. ' is gone.', description = ('Survived %d days.'):format(days), type = 'error', duration = 10000 })
  TriggerClientEvent('outbreak:client:thisIsHowYouDied', src, days)
  SetTimeout(9000, function()
    -- qbx_core: back to character select; the dead character is flagged and cannot be reloaded
    local ok = pcall(function() exports.qbx_core:Logout(src) end)
    if not ok then pcall(function() p.Functions.Logout() end) end
  end)
end)

-- Refuse to load a dead character (belt and suspenders for permadeath)
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
  local row = MySQL.single.await('SELECT dead FROM outbreak_players WHERE citizenid = ?', { player.PlayerData.citizenid })
  if row and row.dead == 1 then
    TriggerClientEvent('ox_lib:notify', player.PlayerData.source, { title = 'That survivor is dead.', description = 'Make a new one.', type = 'error', duration = 8000 })
    SetTimeout(4000, function() pcall(function() exports.qbx_core:Logout(player.PlayerData.source) end) end)
  end
end)

-- PvP: search a downed player's pockets
RegisterNetEvent('outbreak:server:searchDowned', function(target)
  local src = source
  if not DownCfg.PvP then return end
  if Player(target).state.downState == nil then return end
  exports.ox_inventory:forceOpenInventory(src, 'player', target)
end)

-- Memorial wall lookup
lib.callback.register('outbreak:memorial', function(src)
  return MySQL.query.await('SELECT name, days_survived, cause, died_at FROM outbreak_memorial ORDER BY died_at DESC LIMIT 25') or {}
end)

lib.callback.register('outbreak:corpses', function(src)
  return MySQL.query.await('SELECT stash_id, name, x, y, z FROM outbreak_corpses WHERE died_at > NOW() - INTERVAL ? HOUR', { DownCfg.CorpseHours }) or {}
end)

-- Carry / drag: server sets the statebags; both clients act on them
RegisterNetEvent('outbreak:server:carry', function(target, mode)
  local src = source
  if mode == 'stop' then
    local t = Player(src).state.carrying
    Player(src).state:set('carrying', nil, true)
    if t then Player(t).state:set('carriedBy', nil, true) end
    return
  end
  if not target or Player(target).state.downState == nil then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > 3.0 then return end
  Player(src).state:set('carrying', target, true)
  Player(target).state:set('carriedBy', { by = src, mode = mode }, true)
end)
