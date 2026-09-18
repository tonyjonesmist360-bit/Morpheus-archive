-- outbreak_spawn/server/spawn.lua
local QBCore = exports['qb-core']:GetCoreObject()

local function scenario()
  local id = GetConvar('ob_scenario', SpawnCfg.Active)
  return SpawnCfg.Scenarios[id] or SpawnCfg.Scenarios[SpawnCfg.Active], id
end

-- DEAD MONEY: the framework's cash and bank are zeroed on EVERY load (old characters, admin gives, anything the
-- recipe pays out). The only money in the world is the old_cash item.
local function wipeMoney(src, player)
  for _, acct in ipairs({ 'cash', 'bank', 'crypto' }) do
    local ok = pcall(function() exports.qbx_core:SetMoney(src, acct, 0, 'outbreak-wipe') end)
    if not ok then pcall(function() player.Functions.SetMoney(acct, 0, 'outbreak-wipe') end) end
  end
end
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
  local cid = player.PlayerData.citizenid
  local src = player.PlayerData.source
  wipeMoney(src, player)
  local row = MySQL.single.await('SELECT citizenid FROM outbreak_players WHERE citizenid = ?', { cid })
  if row then return end
  MySQL.insert.await('INSERT INTO outbreak_players (citizenid) VALUES (?)', { cid })
  local sc, id = scenario()
  for _, kit in ipairs(sc.kit) do exports.ox_inventory:AddItem(src, kit[1], kit[2]) end
  if sc.needs then
    Wait(1500) -- let outbreak_needs load first
    exports.outbreak_needs:consume(src, { hunger = sc.needs.hunger - 100, thirst = sc.needs.thirst - 100, fatigue = sc.needs.fatigue - 100 })
  end
  if sc.hour then pcall(function() exports.outbreak_world:setTime(sc.hour) end) end
  if sc.weather then pcall(function() exports.outbreak_world:setWeather(sc.weather) end) end
  TriggerClientEvent('outbreak:client:freshSpawn', src, id)
  if sc.radio then
    SetTimeout(sc.radio.after * 1000, function() exports.outbreak_radio:transmit(sc.radio.channel, sc.radio.title, sc.radio.text, src) end)
  end
end)

exports('scenario', scenario)
