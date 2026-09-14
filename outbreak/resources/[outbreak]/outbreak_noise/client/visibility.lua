-- outbreak_noise/client/visibility.lua
-- The second sense. One number, 0-100: how easy you are to SEE right now. 50 = standing,
-- walking, daylight. outbreak_core scales zombie sight range by it. Same shape as noise:
-- computed from the core tick, no loop of its own, exported, pushed to the HUD.
VisibilityCfg = {
  Base = 50,
  Posture  = { crouch = 0.5, still = 0.6, walk = 1.0, run = 1.3, sprint = 1.6, vehicle = 1.2 },
  Light    = { night = 0.5, blackoutNight = 0.85, flashlight = 2.0, headlights = 1.5 },
  Weather  = { FOGGY = 0.6, RAIN = 0.8, THUNDER = 0.85, SMOG = 0.85 },
  Interior = 0.7,
  NightHours = { from = 22, to = 5 },
}
local visibility = VisibilityCfg.Base

local function isNight() local h = GetClockHours(); return h >= VisibilityCfg.NightHours.from or h <= VisibilityCfg.NightHours.to end

AddEventHandler('outbreak:tick', function(t)
  local C = VisibilityCfg
  local v = C.Base
  local crouched = false
  pcall(function() local _, c = exports.outbreak_emotes:getWalkStyle(); crouched = c == true end)
  if t.veh ~= 0 then v = v * C.Posture.vehicle
  elseif t.sprinting then v = v * C.Posture.sprint
  elseif t.running then v = v * C.Posture.run
  elseif (t.stealth or crouched) and t.moving then v = v * C.Posture.crouch
  elseif (t.stealth or crouched) then v = v * C.Posture.crouch * C.Posture.still
  elseif t.walking then v = v * C.Posture.walk
  else v = v * C.Posture.still end
  local night = isNight()
  if night then
    v = v * C.Light.night
    if GlobalState.obBlackout then v = v * C.Light.blackoutNight end
    if t.veh ~= 0 then local _, low, high = GetVehicleLightsState(t.veh); if low or high then v = v * C.Light.headlights end end
    if t.veh == 0 and IsFlashLightOn(t.ped) then v = v * C.Light.flashlight end
  end
  local w = GlobalState.obWeather; if w and C.Weather[w] then v = v * C.Weather[w] end
  if GetInteriorFromEntity(t.ped) ~= 0 then v = v * C.Interior end
  pcall(function() local e = exports.outbreak_skills:effects('stealth'); if e and e.sightMult then v = v * e.sightMult end end)
  visibility = math.max(2, math.min(100, v))   -- the HUD eye reads this through outbreak_core's outbreak:hud:sight, which also carries suspicion
end)

exports('getVisibility', function() return visibility end)

-- DISTRACTION: a can thrown where you aim. Lands, makes noise there, and outbreak_core walks
-- every zombie in range to it. The server removed the item before this fires.
RegisterNetEvent('outbreak:client:throwDistraction', function(item)
  local ped = PlayerPedId()
  local cam = GetGameplayCamCoord(); local rot = GetGameplayCamRot(2)
  local dir = vector3(-math.sin(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.cos(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.sin(math.rad(rot.x)))
  local start = GetPedBoneCoords(ped, 57005, 0.0, 0.0, 0.0)
  local m = `prop_ld_can_01`
  RequestModel(m); local t0 = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t0 < 1500 do Wait(10) end
  pcall(function() exports.outbreak_emotes:action('whistle', 600, 'Throwing...') end)
  local obj = HasModelLoaded(m) and CreateObject(m, start.x, start.y, start.z, false, false, false) or 0
  if obj ~= 0 then
    SetEntityVelocity(obj, dir.x * 18.0, dir.y * 18.0, dir.z * 18.0 + 4.0)
    SetModelAsNoLongerNeeded(m)
  end
  SetTimeout(1600, function()
    local land = obj ~= 0 and DoesEntityExist(obj) and GetEntityCoords(obj) or (start + dir * 18.0)
    TriggerEvent('outbreak:noise:spikeAt', land, 55, 40.0)
    pcall(function() exports.outbreak_core:lureTo(land, 40.0) end)
    if obj ~= 0 and DoesEntityExist(obj) then SetTimeout(20000, function() if DoesEntityExist(obj) then DeleteEntity(obj) end end) end
  end)
  lib.notify({ title = 'You throw the can.', description = 'Clatter. Let them go look.', type = 'inform', duration = 3000 })
end)
-- a noise that happens somewhere else: only counts for YOUR noise if it is near you
AddEventHandler('outbreak:noise:spikeAt', function(pos, v, radius)
  if #(GetEntityCoords(PlayerPedId()) - pos) <= (radius or 30.0) * 0.5 then TriggerEvent('outbreak:noise:spike', v * 0.5) end
end)
