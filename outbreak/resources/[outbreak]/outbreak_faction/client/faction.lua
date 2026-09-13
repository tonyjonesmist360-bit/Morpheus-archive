-- outbreak_faction/client/faction.lua
local myJob = 'unemployed'

local function applyRelations()
  local me = PlayerPedId()
  if myJob == 'military' then
    SetRelationshipBetweenGroups(0, `OUTBREAK_MIL`, `PLAYER`) -- soldiers treat you as one of their own
    SetRelationshipBetweenGroups(0, `PLAYER`, `OUTBREAK_MIL`)
    exports['pma-voice']:setRadioChannel(FactionCfg.Military.radioChannel)
  elseif myJob == 'raider' then
    SetRelationshipBetweenGroups(5, `OUTBREAK_MIL`, `PLAYER`) -- shot on sight
    exports['pma-voice']:setRadioChannel(FactionCfg.Raider.radioChannel)
  else
    SetRelationshipBetweenGroups(3, `OUTBREAK_MIL`, `PLAYER`)
  end
end

local function refreshJob()
  myJob = lib.callback.await('outbreak:faction:job', false) or 'unemployed'
  applyRelations()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', refreshJob)
RegisterNetEvent('QBCore:Client:OnJobUpdate', refreshJob)

CreateThread(function()
  Wait(3000); refreshJob()
  local M, R = FactionCfg.Military, FactionCfg.Raider
  exports.ox_target:addSphereZone({ coords = M.Armory.coords, radius = 1.5, options = {
    { label = 'Armory', icon = 'fa-solid fa-box-open', onSelect = function() TriggerServerEvent('outbreak:server:openFactionStash', 'military') end },
    { label = 'Change into fatigues', icon = 'fa-solid fa-shirt', onSelect = function()
        local ok = pcall(function() exports['illenium-appearance']:setPlayerOutfit(M.Uniform.name) end)
        if not ok then lib.notify({ title = 'Outfit "' .. M.Uniform.name .. '" not saved yet — make it once in appearance.', type = 'inform' }) end
      end },
  }})
  exports.ox_target:addSphereZone({ coords = R.Camp.coords, radius = 1.5, options = {
    { label = 'Raider cache', icon = 'fa-solid fa-skull', onSelect = function() TriggerServerEvent('outbreak:server:openFactionStash', 'raider') end },
  }})
end)

exports('getJob', function() return myJob end)

RegisterNetEvent('outbreak:client:rep', function(faction, value, reason)
  lib.notify({ title = ('%s reputation: %d'):format(faction:gsub('^%l', string.upper), value), description = reason, type = value >= 0 and 'inform' or 'error', duration = 5000 })
end)
