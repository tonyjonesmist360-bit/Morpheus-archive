-- outbreak_raiders/client/raiders.lua
-- Raiders don't shoot. They PIT, box you in, drag you out, beat you down, rob you, leave.
local chase = nil  -- { vehicles = {}, peds = {}, startedAt, robbed }

local function cleanup(escaped)
  if not chase then return end
  for _, ped in ipairs(chase.peds) do
    if DoesEntityExist(ped) then
      local veh = GetVehiclePedIsIn(ped, true)
      if veh ~= 0 and DoesEntityExist(veh) then
        TaskVehicleDriveWander(ped, veh, 30.0, 786603) -- drive off into the wasteland
      end
      SetEntityAsNoLongerNeeded(ped)
    end
  end
  for _, veh in ipairs(chase.vehicles) do SetEntityAsNoLongerNeeded(veh) end
  chase = nil
  TriggerServerEvent('outbreak:server:chaseEnded')
  if escaped then lib.notify({ title = 'You lost them.', type = 'success' }) end
end

local function spawnCrew(behindPos, heading)
  local vmodel = joaat(RaiderCfg.Vehicles[math.random(#RaiderCfg.Vehicles)])
  RequestModel(vmodel); local t = GetGameTimer()
  while not HasModelLoaded(vmodel) and GetGameTimer() - t < 4000 do Wait(10) end
  if not HasModelLoaded(vmodel) then return end
  local veh = CreateVehicle(vmodel, behindPos.x, behindPos.y, behindPos.z, heading, false, true)
  SetVehicleEngineOn(veh, true, true, false)
  SetVehicleColours(veh, 0, 0)  -- primer black; war paint
  chase.vehicles[#chase.vehicles + 1] = veh
  local crew = math.random(RaiderCfg.CrewSize[1], RaiderCfg.CrewSize[2])
  for seat = -1, crew - 2 do
    local pmodel = joaat(RaiderCfg.Models[math.random(#RaiderCfg.Models)])
    RequestModel(pmodel); while not HasModelLoaded(pmodel) do Wait(10) end
    local ped = CreatePedInsideVehicle(veh, 4, pmodel, seat, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    RemoveAllPedWeapons(ped, true)
    GiveWeaponToPed(ped, RaiderCfg.MeleeWeapons[math.random(#RaiderCfg.MeleeWeapons)], 1, false, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedRelationshipGroupHash(ped, `OUTBREAK_MIL`) -- reuse: hated by zombies too
    if seat == -1 then
      SetDriverAbility(ped, 1.0)
      SetDriverAggressiveness(ped, 1.0)
      TaskVehicleChase(ped, PlayerPedId())
      SetTaskVehicleChaseIdealPursuitDistance(ped, 0.0)  -- ram range: PITs and boxes
    end
    chase.peds[#chase.peds + 1] = ped
  end
end

RegisterNetEvent('outbreak:client:raiderAmbush', function()
  if chase then return end
  local me = PlayerPedId()
  local veh = GetVehiclePedIsIn(me, false)
  if veh == 0 then return end
  chase = { vehicles = {}, peds = {}, startedAt = GetGameTimer(), robbed = false }
  local pos = GetEntityCoords(me)
  local heading = GetEntityHeading(veh)
  local rad = math.rad(heading)
  local behind = vector3(pos.x + math.sin(rad) * 70.0, pos.y - math.cos(rad) * 70.0, pos.z)
  local found, z = GetGroundZFor_3dCoord(behind.x, behind.y, behind.z + 40.0, false)
  if found then behind = vector3(behind.x, behind.y, z) end
  local n = math.random(RaiderCfg.VehicleCount[1], RaiderCfg.VehicleCount[2])
  for i = 1, n do spawnCrew(behind + vector3(i * 6.0, i * 4.0, 0), heading) end
  lib.notify({ title = 'Engines behind you.', description = 'They\'re not slowing down.', type = 'error' })
end)

-- Chase supervisor
CreateThread(function()
  while true do
    Wait(1000)
    if not chase then goto continue end
    local me = PlayerPedId()
    local mpos = GetEntityCoords(me)
    local elapsed = (GetGameTimer() - chase.startedAt) / 1000

    -- prune dead crew
    local alive = 0
    for _, ped in ipairs(chase.peds) do
      if DoesEntityExist(ped) and not IsEntityDead(ped) then alive = alive + 1 end
    end

    -- escape conditions
    local nearest = math.huge
    for _, veh in ipairs(chase.vehicles) do
      if DoesEntityExist(veh) then
        nearest = math.min(nearest, #(GetEntityCoords(veh) - mpos))
      end
    end
    if alive == 0 or nearest > RaiderCfg.GiveUpDistance or elapsed > RaiderCfg.GiveUpSeconds then
      cleanup(alive > 0)
      goto continue
    end

    -- dismount: your car is crawling or you're on foot -> they bail and swing
    local myVeh = GetVehiclePedIsIn(me, false)
    local slow = myVeh == 0 or (GetEntitySpeed(myVeh) * 3.6) < RaiderCfg.DismountSpeedKmh
    if slow and nearest < 25.0 then
      for _, ped in ipairs(chase.peds) do
        if DoesEntityExist(ped) and not IsEntityDead(ped) and IsPedInAnyVehicle(ped, false) then
          TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 256)
        elseif DoesEntityExist(ped) and not IsEntityDead(ped) then
          TaskCombatPed(ped, me, 0, 16)
        end
      end
    end

    -- knocked out -> rob once, then leave
    if not chase.robbed and LocalPlayer.state.downState then
      chase.robbed = true
      CreateThread(function()
        -- one raider crouches over you
        for _, ped in ipairs(chase.peds) do
          if DoesEntityExist(ped) and not IsEntityDead(ped) then
            ClearPedTasks(ped)
            TaskGoToEntity(ped, me, -1, 1.0, 2.0, 0, 0)
            break
          end
        end
        Wait(RaiderCfg.RobSeconds * 1000)
        TriggerServerEvent('outbreak:server:raiderRob')
        Wait(2000)
        cleanup(false)
        lib.notify({ title = 'Rough hands go through your pockets...', type = 'error' })
      end)
    end
    ::continue::
  end
end)

-- Bait events (numbers station / distress) spawn a crew on foot around you
RegisterNetEvent('outbreak:client:raiderAmbushOnFoot', function()
  if chase then return end
  local me = PlayerPedId()
  local pos = GetEntityCoords(me)
  chase = { vehicles = {}, peds = {}, startedAt = GetGameTimer(), robbed = false }
  for i = 1, 3 do
    local pmodel = joaat(RaiderCfg.Models[math.random(#RaiderCfg.Models)])
    RequestModel(pmodel); while not HasModelLoaded(pmodel) do Wait(10) end
    local a = math.random() * 6.283
    local ped = CreatePed(4, pmodel, pos.x + math.cos(a) * 12.0, pos.y + math.sin(a) * 12.0, pos.z, 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    GiveWeaponToPed(ped, RaiderCfg.MeleeWeapons[math.random(#RaiderCfg.MeleeWeapons)], 1, false, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedRelationshipGroupHash(ped, `OUTBREAK_MIL`)
    TaskCombatPed(ped, me, 0, 16)
    chase.peds[#chase.peds + 1] = ped
  end
end)
