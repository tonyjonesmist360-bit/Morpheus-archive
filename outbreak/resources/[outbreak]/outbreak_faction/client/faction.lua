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
    { label = 'Enlist with the Remnant', icon = 'fa-solid fa-flag', canInteract = function() return myJob ~= 'military' end,
      onSelect = function() if lib.alertDialog({ header = 'Enlist', content = FactionCfg.Blurbs.military .. '\n\nJoin them? Leaving later costs standing.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:joinFaction', 'military') end end },
    { label = 'Walk out on the Remnant', icon = 'fa-solid fa-person-walking-arrow-right', canInteract = function() return myJob == 'military' end,
      onSelect = function() if lib.alertDialog({ header = 'Leave', content = 'Hand back the fatigues. Standing drops.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:leaveFaction') end end },
    { label = 'Change into fatigues', icon = 'fa-solid fa-shirt', onSelect = function()
        local ok = pcall(function() exports['illenium-appearance']:setPlayerOutfit(M.Uniform.name) end)
        if not ok then lib.notify({ title = 'Outfit "' .. M.Uniform.name .. '" not saved yet — make it once in appearance.', type = 'inform' }) end
      end },
  }})
  exports.ox_target:addSphereZone({ coords = R.Camp.coords, radius = 1.5, options = {
    { label = 'Raider cache', icon = 'fa-solid fa-skull', onSelect = function() TriggerServerEvent('outbreak:server:openFactionStash', 'raider') end },
    { label = 'Join the Boneyard', icon = 'fa-solid fa-skull-crossbones', canInteract = function() return myJob ~= 'raider' end,
      onSelect = function() if lib.alertDialog({ header = 'Join the Boneyard', content = FactionCfg.Blurbs.raider .. '\n\nThe soldiers will shoot you on sight. Join?', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:joinFaction', 'raider') end end },
    { label = 'Leave the Boneyard', icon = 'fa-solid fa-person-walking-arrow-right', canInteract = function() return myJob == 'raider' end,
      onSelect = function() if lib.alertDialog({ header = 'Leave', content = 'They do not forget. Standing drops.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:leaveFaction') end end },
  }})
end)

exports('getJob', function() return myJob end)
exports('getStandings', function() return lib.callback.await('outbreak:faction:standings', false) or {} end)

RegisterNetEvent('outbreak:client:rep', function(faction, value, reason)
  lib.notify({ title = ('%s reputation: %d'):format(faction:gsub('^%l', string.upper), value), description = reason, type = value >= 0 and 'inform' or 'error', duration = 5000 })
end)
