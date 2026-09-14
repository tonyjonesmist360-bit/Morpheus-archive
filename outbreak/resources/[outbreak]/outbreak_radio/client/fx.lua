-- outbreak_radio/client/fx.lua — the walkie as an object: prop in hand, arm up, squelch, hiss,
-- distortion, dead zones, battery, and a mark over whoever is talking. Nothing here decides who
-- hears whom (server range model); this is what it looks and sounds like.
local C = RadioCfg
local prop, transmitting, submix = nil, false, nil
local talking = {}          -- sid -> quality, remote players currently keyed
local battery, spares, signal = 1.0, 0, 0.0

local function nui(t) SendNUIMessage(t) end
local function hasRadio() local ok, n = pcall(function() return exports.ox_inventory:Search('count', 'radio_handheld') end) return ok and (n or 0) > 0 end
local function sparesCount() local ok, n = pcall(function() return exports.ox_inventory:Search('count', 'radio_battery') end) return ok and (n or 0) or 0 end

-- ── dead zones: interiors and listed tunnels kill the signal both ways ──
local function inDeadZone()
  local ped = PlayerPedId()
  if GetInteriorFromEntity(ped) ~= 0 and C.IndoorsIsDead then return true, 'indoors' end
  local pos = GetEntityCoords(ped)
  for _, z in ipairs(C.DeadZones or {}) do if #(pos - z.pos) <= z.radius then return true, z.label end end
  return false
end
exports('inDeadZone', inDeadZone)

-- ── submix: the radio voice ──
local function radioSubmix()
  if submix or not C.Submix then return submix end
  submix = CreateAudioSubmix('OutbreakRadio')
  SetAudioSubmixEffectRadioFx(submix, 0)
  SetAudioSubmixEffectParamInt(submix, 0, `default`, 1)
  AddAudioSubmixOutput(submix, 0)
  return submix
end

-- ── prop + arm ──
local function raise()
  if prop then return end
  local m = `prop_cs_hand_radio`
  RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 1500 do Wait(10) end
  local ped = PlayerPedId()
  if HasModelLoaded(m) then
    local pos = GetEntityCoords(ped)
    prop = CreateObject(m, pos.x, pos.y, pos.z + 0.2, true, true, false)
    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 28422), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    SetModelAsNoLongerNeeded(m)
  end
  pcall(function() exports.outbreak_emotes:loopAction('radio') end)
end
local function lower()
  pcall(function() exports.outbreak_emotes:stopAction() end)
  if prop and DoesEntityExist(prop) then DetachEntity(prop, true, false); DeleteEntity(prop) end
  prop = nil
end

-- ── my key-up / release (pma-voice fires this on the local client) ──
AddEventHandler('pma-voice:radioActive', function(on)
  local ch = RadioGetChannel and RadioGetChannel() or 0
  if on then
    if ch <= 0 or not hasRadio() then return end
    local dead, why = inDeadZone()
    if dead then lib.notify({ title = 'No signal.', description = why == 'indoors' and 'Too deep. Get to a window or a door.' or ('Dead zone: ' .. tostring(why)), type = 'error', duration = 3000 }) end
    transmitting = true
    raise()
    nui({ action = 'sfx', name = 'on', volume = C.Sfx.click })
    nui({ action = 'show', data = { ch = ch, tx = true, battery = battery, signal = signal, spares = spares } })
  else
    if not transmitting then return end
    transmitting = false
    lower()
    nui({ action = 'sfx', name = 'off', volume = C.Sfx.click })
    nui({ action = 'state', data = { tx = false } })
    SetTimeout(1500, function() if not transmitting and not next(talking) then nui({ action = 'hide' }) end end)
  end
end)

-- ── someone else keys on my channel ──
local function refreshHiss()
  local best, who = 0.0, nil
  for sid, q in pairs(talking) do if q > best then best, who = q, sid end end
  if not who then
    nui({ action = 'loop', name = 'hiss', on = false }); nui({ action = 'loop', name = 'weak', on = false })
    nui({ action = 'state', data = { rx = false } })
    SetTimeout(1500, function() if not transmitting and not next(talking) then nui({ action = 'hide' }) end end)
    return
  end
  local name = GetPlayerName(GetPlayerFromServerId(who)) or ('#' .. who)
  if best < 0.6 then nui({ action = 'loop', name = 'weak', on = true, volume = C.Sfx.weak }); nui({ action = 'loop', name = 'hiss', on = false })
  else nui({ action = 'loop', name = 'hiss', on = true, volume = C.Sfx.hiss * (1.2 - best) }); nui({ action = 'loop', name = 'weak', on = false }) end
  nui({ action = 'show', data = { ch = RadioGetChannel and RadioGetChannel() or 0, rx = true, who = name, battery = battery, signal = signal, spares = spares } })
end
AddEventHandler('pma-voice:setTalkingOnRadio', function(sid, on)
  local row = LocalPlayer.state.radioReach
  local q = row and row[tostring(sid)] or nil
  if on then
    if q == nil then return end
    local dead = inDeadZone()
    if dead then q = q * C.IndoorFactor end
    talking[sid] = q
    if q >= C.Floor then
      local sm = radioSubmix(); if sm then MumbleSetSubmixForServerId(sid, sm) end
      nui({ action = 'sfx', name = 'on', volume = C.Sfx.click * 0.7 })
    end
    refreshHiss()
  elseif talking[sid] then
    talking[sid] = nil
    if C.Submix then MumbleSetSubmixForServerId(sid, -1) end
    nui({ action = 'sfx', name = 'off', volume = C.Sfx.click * 0.7 })
    refreshHiss()
  end
end)

-- ── mark over whoever is transmitting near me (drawn only while someone is) ──
local function drawTag(pos, text)
  SetDrawOrigin(pos.x, pos.y, pos.z + 1.05, 0)
  SetTextFont(4); SetTextScale(0.28, 0.28); SetTextColour(216, 210, 192, 210); SetTextCentre(true); SetTextOutline()
  BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayText(0.0, 0.0)
  ClearDrawOrigin()
end
CreateThread(function()
  while true do
    if next(talking) then
      Wait(0)
      local me = GetEntityCoords(PlayerPedId())
      for sid, q in pairs(talking) do
        local pid = GetPlayerFromServerId(sid)
        if pid ~= -1 then
          local ped = GetPlayerPed(pid)
          if ped ~= 0 and #(GetEntityCoords(ped) - me) < C.TagRange then drawTag(GetEntityCoords(ped), q < 0.6 and '((radio: weak))' or '((radio))') end
        end
      end
    else Wait(400) end
  end
end)

-- ── battery + signal for the screen ──
RegisterNetEvent('outbreak:client:radioBattery', function(pct) battery = math.max(0, math.min(1, (pct or 100) / 100)); spares = sparesCount(); nui({ action = 'state', data = { battery = battery, spares = spares } }) end)
AddEventHandler('outbreak:tick', function()
  local row = LocalPlayer.state.radioReach; local best = 0.0
  if row then for _, q in pairs(row) do if q > best then best = q end end end
  if inDeadZone() then best = best * C.IndoorFactor end
  if math.abs(best - signal) > 0.05 then signal = best; nui({ action = 'state', data = { signal = signal } }) end
end)

-- screen state is kept by radio.lua (channel) and here (battery/signal); expose for radio.lua's open
exports('screenState', function() return { battery = battery, signal = signal, spares = sparesCount() } end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then lower(); SetNuiFocus(false, false) end end)
