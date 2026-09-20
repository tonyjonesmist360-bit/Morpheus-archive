-- outbreak_radio/client/radio.lua
local onChannel = 0
local screenOpen = false
local function hasMMRadio() return RadioCfg.PreferMMRadio and GetResourceState('mm_radio') == 'started' end
local function hasRadio() local ok, n = pcall(function() return exports.ox_inventory:Search('count', 'radio_handheld') end) return ok and (n or 0) > 0 end

-- ── KNOWN CHANNELS (v0.25): what this character has found. Persisted per character (KVP). ──
local known = {}
local function cid() local ok, c = pcall(function() return exports['qb-core']:GetCoreObject().Functions.GetPlayerData().citizenid end); return ok and c or 'x' end
local function loadKnown()
  known = {}
  for _, c in ipairs((RadioCfg.Channels or {}).KnownAtStart or { 1 }) do known[c] = true end
  local raw = GetResourceKvpString('ob_radio_known_' .. cid())
  local ok, t = pcall(json.decode, raw or '')
  if ok and type(t) == 'table' then for _, c in ipairs(t) do known[tonumber(c)] = true end end
end
local function saveKnown() local t = {}; for c in pairs(known) do t[#t + 1] = c end; table.sort(t); SetResourceKvp('ob_radio_known_' .. cid(), json.encode(t)) end
local function knownList() local t = {}; for c in pairs(known) do t[#t + 1] = c end; table.sort(t); return t end
local function learn(ch, why)
  ch = math.floor(tonumber(ch) or 0); if ch <= 0 then return false end
  if known[ch] then return false end
  known[ch] = true; saveKnown()
  lib.notify({ title = ('New channel: %d'):format(ch), description = why or 'It is on your radio now.', type = 'success', duration = 7000 })
  SendNUIMessage({ action = 'sfx', name = 'on', volume = 0.6 })
  return true
end
exports('learnChannel', learn)
exports('knownChannels', knownList)
RegisterNetEvent('outbreak:radio:learn', function(ch, why) learn(ch, why) end)
AddEventHandler('QBCore:Client:OnPlayerLoaded', function() Wait(1000); loadKnown() end)
CreateThread(function() Wait(2000); loadKnown() end)

-- shared with fx.lua (same resource, resource-global functions)
function RadioGetChannel() return onChannel end
function RadioSetChannel(ch, quiet, force)
  ch = math.max(0, math.min(99, math.floor(tonumber(ch) or 0)))
  if ch > 0 and not hasRadio() then lib.notify({ title = 'You don\'t have a radio.', type = 'error' }) return end
  if ch > 0 and not known[ch] and not force then
    SendNUIMessage({ action = 'sfx', name = 'static_weak', volume = 0.6 })
    lib.notify({ title = ('Nothing on %d.'):format(ch), description = 'Scan for it (S on the screen), or find who uses it.', type = 'error' })
    SendNUIMessage({ action = 'state', data = { ch = onChannel } })
    return
  end
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
  -- power-up: a radio switched on lands on the emergency channel
  if onChannel == 0 then
    local em = (RadioCfg.Channels or {}).emergency or 1
    known[em] = true
    RadioSetChannel(em, false, true)
    lib.notify({ title = ('Channel %d: emergency.'):format(em), description = 'Everyone with a radio starts here. Scan (S) to find the others.', type = 'inform', duration = 7000 })
  end
  SendNUIMessage({ action = 'open', data = { ch = onChannel, battery = st.battery, signal = st.signal, spares = st.spares, known = knownList() } })
  SetNuiFocus(true, true)
end
local scanning = false
local function scan()
  if scanning then return end
  if not hasRadio() then lib.notify({ title = 'You don\'t have a radio.', type = 'error' }) return end
  scanning = true
  local S = (RadioCfg.Channels or {}).Scan or {}
  SendNUIMessage({ action = 'loop', name = 'hiss', on = true, volume = 0.6 })
  SendNUIMessage({ action = 'state', data = { scanning = true } })
  pcall(function() exports.outbreak_emotes:loopAction('radio') end)
  Wait((S.seconds or 4) * 1000)
  pcall(function() exports.outbreak_emotes:stopAction() end)
  SendNUIMessage({ action = 'loop', name = 'hiss', on = false })
  SendNUIMessage({ action = 'state', data = { scanning = false } })
  scanning = false
  local found = lib.callback.await('outbreak:radio:scan', false, knownList())
  if found and math.random() < (S.chance or 0.85) then
    learn(found, 'Voices in the static. Locked in.')
    RadioSetChannel(found, false, true)
  else
    lib.notify({ title = 'Static.', description = 'Nothing new this time. Try again, or move higher.', type = 'inform' })
  end
end
RegisterNUICallback('scan', function(_, cb) cb('ok'); CreateThread(scan) end)
-- up/down step through KNOWN channels only
local function stepKnown(dir)
  local list = knownList(); if #list == 0 then return end
  local idx = 0
  for i, c in ipairs(list) do if c == onChannel then idx = i end end
  local nxt = list[((idx - 1 + dir) % #list) + 1]
  RadioSetChannel(nxt)
end
RegisterNUICallback('tune', function(d, cb) RadioSetChannel(d and d.ch or 0); cb('ok') end)
RegisterNUICallback('step', function(d, cb) cb('ok'); stepKnown((d and d.dir) == 'down' and -1 or 1) end)
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
RegisterCommand('ob_radioup', function() if onChannel > 0 then stepKnown(1) end end, false)
RegisterCommand('ob_radiodown', function() if onChannel > 0 then stepKnown(-1) end end, false)
RegisterCommand('radioscan', function() CreateThread(scan) end, false)
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

-- No phones in the apocalypse. This used to be a per-frame DisableControlAction(0, 27) loop;
-- control 27 is also D-pad UP, which outbreak_binds maps to the inventory, so the loop ate the
-- pad's inventory button every frame. The phone resources are disabled in the recipe instead
-- (see server.cfg.additions header) - no input hook is needed here. CORE-MECHANICS.md #R1-1.

exports('getChannel', function() return onChannel end)
