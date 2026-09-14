-- outbreak_radio/client/radio.lua
local onChannel = 0
local screenOpen = false
local function hasMMRadio() return RadioCfg.PreferMMRadio and GetResourceState('mm_radio') == 'started' end
local function hasRadio() local ok, n = pcall(function() return exports.ox_inventory:Search('count', 'radio_handheld') end) return ok and (n or 0) > 0 end

-- shared with fx.lua (same resource, resource-global functions)
function RadioGetChannel() return onChannel end
function RadioSetChannel(ch, quiet)
  ch = math.max(0, math.min(99, math.floor(tonumber(ch) or 0)))
  if ch > 0 and not hasRadio() then lib.notify({ title = 'You don\'t have a radio.', type = 'error' }) return end
  onChannel = ch
  exports['pma-voice']:setRadioChannel(onChannel)
  TriggerServerEvent('outbreak:radio:channel', onChannel)
  if not quiet then
    exports.outbreak_emotes:loopAction('radio'); SetTimeout(1200, function() exports.outbreak_emotes:stopAction() end)
    SendNUIMessage({ action = 'sfx', name = 'on', volume = RadioCfg.Sfx.click })
  end
  SendNUIMessage({ action = 'state', data = { ch = onChannel } })
  lib.notify({ title = onChannel > 0 and ('Channel %d'):format(onChannel) or 'Radio off', description = onChannel > 0 and 'Hold CapsLock (RB) to transmit' or nil, type = onChannel > 0 and 'success' or 'inform', duration = 3000 })
end

local function closeScreen()
  if not screenOpen then return end
  screenOpen = false; SetNuiFocus(false, false); SendNUIMessage({ action = 'close' })
end
local function openScreen()
  screenOpen = true
  local st = {}; pcall(function() st = exports.outbreak_radio:screenState() or {} end)
  SendNUIMessage({ action = 'open', data = { ch = onChannel, battery = st.battery, signal = st.signal, spares = st.spares } })
  SetNuiFocus(true, true)
end
RegisterNUICallback('tune', function(d, cb) RadioSetChannel(d and d.ch or 0); cb('ok') end)
RegisterNUICallback('close', function(_, cb) closeScreen(); cb('ok') end)

RegisterNetEvent('outbreak:client:openRadio', function()
  if not hasRadio() then lib.notify({ title = 'You don\'t have a radio.', type = 'error' }) return end
  if screenOpen then closeScreen() return end
  if hasMMRadio() then
    local ok = pcall(function() exports['mm_radio']:openRadio() end); if ok then return end
    ok = pcall(function() TriggerEvent('mm_radio:client:use') end); if ok then return end
  end
  if RadioCfg.ScreenUI then openScreen() return end
  local input = lib.inputDialog('Handheld Radio', { { type = 'number', label = 'Channel (1-99, 0 = off)', default = onChannel, min = 0, max = 99 } })
  if not input then return end
  RadioSetChannel(input[1] or 0)
end)
-- quick switching without the screen ([ and ] by default)
RegisterCommand('ob_radioup', function() if onChannel > 0 then RadioSetChannel(onChannel + 1) end end, false)
RegisterCommand('ob_radiodown', function() if onChannel > 1 then RadioSetChannel(onChannel - 1) end end, false)
RegisterCommand('radio', function(_, a) if a[1] then RadioSetChannel(tonumber(a[1]) or 0) else TriggerEvent('outbreak:client:openRadio') end end, false)
CreateThread(function()
  while true do
    if screenOpen then Wait(0); if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 177) then closeScreen() end else Wait(300) end
  end
end)

RegisterNetEvent('outbreak:client:radioDead', function()
  onChannel = 0; exports['pma-voice']:setRadioChannel(0)
  SendNUIMessage({ action = 'sfx', name = 'off', volume = 1.0 }); SendNUIMessage({ action = 'state', data = { ch = 0, battery = 0 } })
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
  while true do
    Wait(4000)
    local ch = onChannel; pcall(function() ch = exports['pma-voice']:getRadioChannel() or onChannel end)
    local dead = false; pcall(function() dead = exports.outbreak_radio:inDeadZone() end)
    TriggerServerEvent('outbreak:radio:channel', ch, dead and true or false)
  end
end)

-- No phones in the apocalypse
CreateThread(function() while true do Wait(0) DisableControlAction(0, 27, true) end end)

exports('getChannel', function() return onChannel end)
