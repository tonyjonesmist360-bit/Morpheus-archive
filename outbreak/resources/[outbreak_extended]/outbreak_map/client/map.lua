-- outbreak_map/client/map.lua
local placed = {}

CreateThread(function()
  if MapCfg.KillTrains then SetRandomTrains(false); DeleteAllTrains() end
  if MapCfg.KillBoats then SetRandomBoats(false) end
  if MapCfg.KillPlanes then SetCreateRandomCops(false); SetCreateRandomCopsNotOnScenarios(false); SetCreateRandomCopsOnScenarios(false) end
  if MapCfg.KillEmergencyVehicles then SetGarbageTrucks(false) end
  while true do
    Wait(0)
    if MapCfg.KillPlanes then
      -- no ambient aircraft in a dead sky
      SetAmbientVehicleRangeMultiplierThisFrame(0.0)
    end
    Wait(500)
  end
end)

CreateThread(function()
  while true do
    Wait(4000)
    local ppos = GetEntityCoords(PlayerPedId())
    for i, p in ipairs(MapCfg.Props) do
      local d = #(ppos - p[2])
      if d < 300.0 and not placed[i] then
        local m = joaat(p[1])
        RequestModel(m); local t = GetGameTimer()
        while not HasModelLoaded(m) and GetGameTimer() - t < 2000 do Wait(10) end
        if HasModelLoaded(m) then
          local obj = CreateObject(m, p[2].x, p[2].y, p[2].z, false, false, false)
          SetEntityHeading(obj, p[3]); PlaceObjectOnGroundProperly(obj); FreezeEntityPosition(obj, true)
          placed[i] = obj
        else placed[i] = false end
      elseif d > 400.0 and placed[i] then
        DeleteEntity(placed[i]); placed[i] = nil
      end
    end
  end
end)

-- /scuff <note> : tag a map problem where you stand. Shows up in the server DB + console for the shakedown list.
RegisterCommand('scuff', function(_, args)
  local note = table.concat(args, ' ')
  if note == '' then lib.notify({ title = 'Usage: /scuff <what\'s wrong here>', type = 'inform' }) return end
  local c = GetEntityCoords(PlayerPedId())
  TriggerServerEvent('outbreak:server:scuff', { x = c.x, y = c.y, z = c.z, note = note })
  lib.notify({ title = 'Scuff logged.', description = note, type = 'success' })
end, false)
