-- outbreak_debug/client/hud.lua — /ob_hud: a debug overlay for admins. Coords, heading, street,
-- noise, zombies near, tick age, frame time, interior, radio channel. Reads the core tick; the
-- only per-frame work is drawing, and only while it is on.
local on = false
local last, lastAt = nil, 0
AddEventHandler('outbreak:tick', function(t) last = t; lastAt = GetGameTimer() end)

local function line(y, text)
  SetTextFont(4); SetTextScale(0.30, 0.30); SetTextColour(216, 210, 192, 220); SetTextOutline()
  BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName(text); EndTextCommandDisplayText(0.012, y)
end

RegisterCommand('ob_hud', function()
  if not (GlobalState.obDebug or LocalPlayer.state.isDM) then return end
  on = not on
  lib.notify({ title = on and 'Debug HUD on.' or 'Debug HUD off.', type = 'inform', duration = 1500 })
end, false)

CreateThread(function()
  local frames, fpsAt, fps = 0, GetGameTimer(), 0
  while true do
    if on then
      Wait(0)
      frames = frames + 1
      if GetGameTimer() - fpsAt >= 1000 then fps = frames; frames = 0; fpsAt = GetGameTimer() end
      local ped = PlayerPedId(); local p = GetEntityCoords(ped)
      local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(p.x, p.y, p.z))
      local noise = 0; pcall(function() noise = exports.outbreak_noise:getNoise() end)
      local ch = 0; pcall(function() ch = exports.outbreak_radio:getChannel() end)
      local zone = nil; pcall(function() local z = exports.outbreak_core:currentZone(); zone = z and z.id end)
      local t = last or {}
      local y = 0.30
      line(y, ('%.2f, %.2f, %.2f  h %.0f  %s'):format(p.x, p.y, p.z, GetEntityHeading(ped), street)); y = y + 0.022
      line(y, ('fps %d  tick age %dms  interior %d  zone %s'):format(fps, GetGameTimer() - lastAt, GetInteriorFromEntity(ped), tostring(zone or '-'))); y = y + 0.022
      line(y, ('noise %.0f  zombies near %d  nearest %.0fm  radio ch %d'):format(noise, t.zombiesNear or 0, t.nearestDist == math.huge and 0 or (t.nearestDist or 0), ch)); y = y + 0.022
      line(y, ('speed %.0f km/h  sprint %s  stealth %s  down %s  hp %d'):format(t.speedKmh or 0, tostring(t.sprinting), tostring(t.stealth), tostring(t.down), GetEntityHealth(ped) - 100)); y = y + 0.022
      line(y, ('time %s  weather %s  blackout %s'):format(tostring(GlobalState.obTime), tostring(GlobalState.obWeather), tostring(GlobalState.obBlackout)))
    else Wait(500) end
  end
end)

-- /bug <note>: position + timestamp + note, appended to outbreak_debug/bugs.log on the server.
RegisterCommand('bug', function(_, args)
  local note = table.concat(args, ' ')
  if note == '' then lib.notify({ title = 'Usage: /bug what went wrong', type = 'inform' }) return end
  local ped = PlayerPedId(); local p = GetEntityCoords(ped)
  TriggerServerEvent('outbreak:server:bug', { x = p.x, y = p.y, z = p.z, h = GetEntityHeading(ped), note = note:sub(1, 240),
    street = GetStreetNameFromHashKey(GetStreetNameAtCoord(p.x, p.y, p.z)), down = LocalPlayer.state.downState, hp = GetEntityHealth(ped) - 100 })
  lib.notify({ title = 'Bug logged.', description = 'Position, time and your note are in bugs.log.', type = 'success' })
end, false)
CreateThread(function() Wait(1500); TriggerEvent('chat:addSuggestion', '/bug', 'Log a bug with your position and a note (any player)', { { name = 'note', help = 'what happened' } }) end)
