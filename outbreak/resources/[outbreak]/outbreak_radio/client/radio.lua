-- outbreak_radio/client/radio.lua
local onChannel = 0
local function hasMMRadio() return GetResourceState('mm_radio') == 'started' end
local function hasRadio() local ok, n = pcall(function() return exports.ox_inventory:Search('count', 'radio_handheld') end) return ok and (n or 0) > 0 end

RegisterNetEvent('outbreak:client:openRadio', function()
  if not hasRadio() then lib.notify({ title = 'You don\'t have a radio.', type = 'error' }) return end
  if hasMMRadio() then
    local ok = pcall(function() exports['mm_radio']:openRadio() end); if ok then return end
    ok = pcall(function() TriggerEvent('mm_radio:client:use') end); if ok then return end
  end
  local input = lib.inputDialog('Handheld Radio', { { type = 'number', label = 'Channel (1-99, 0 = off)', default = onChannel, min = 0, max = 99 } })
  if not input then return end
  onChannel = math.floor(input[1] or 0)
  exports['pma-voice']:setRadioChannel(onChannel)
  exports.outbreak_emotes:loopAction('radio'); SetTimeout(1500, function() exports.outbreak_emotes:stopAction() end)
  lib.notify({ title = onChannel > 0 and ('Tuned to channel %d'):format(onChannel) or 'Radio off', description = onChannel > 0 and 'Hold CapsLock (RB) to transmit' or nil, type = onChannel > 0 and 'success' or 'inform' })
end)

RegisterNetEvent('outbreak:client:radioDead', function()
  onChannel = 0; exports['pma-voice']:setRadioChannel(0)
  lib.notify({ title = 'The radio dies. No batteries.', type = 'error' })
end)

-- incoming transmissions: channel 0 = any tuned radio; otherwise must match
RegisterNetEvent('outbreak:client:radioMsg', function(ch, title, text, q)
  local mine = onChannel
  pcall(function() mine = exports['pma-voice']:getRadioChannel() or onChannel end)
  if mine == 0 or not hasRadio() then return end
  if ch ~= 0 and mine ~= ch then return end
  lib.notify({ title = ('[CH %s] %s%s'):format(ch == 0 and '--' or ch, title, (q and q < 0.6) and ' (weak)' or ''), description = text, type = 'inform', duration = 12000, position = 'top' })
end)

CreateThread(function()
  while true do Wait(5 * 60000) TriggerServerEvent('outbreak:server:radioHeartbeat', onChannel > 0) end
end)
CreateThread(function()
  while true do Wait(4000) local ch = onChannel; pcall(function() ch = exports['pma-voice']:getRadioChannel() or onChannel end) TriggerServerEvent('outbreak:radio:channel', ch) end
end)

-- No phones in the apocalypse
CreateThread(function() while true do Wait(0) DisableControlAction(0, 27, true) end end)

exports('getChannel', function() return onChannel end)
