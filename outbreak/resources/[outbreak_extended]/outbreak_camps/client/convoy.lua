-- outbreak_camps/client/convoy.lua : a military convoy you can shadow, ambush, or get flattened by
local convoy = nil

local function cleanupConvoy()
  if not convoy then return end
  for _, e in ipairs(convoy.entities) do if DoesEntityExist(e) then SetEntityAsNoLongerNeeded(e) end end
  convoy = nil
end

RegisterNetEvent('outbreak:client:convoy', function(dir)
  if convoy then return end
  local C = CampCfg.Convoy
  local from, to = C.from[dir], C.from[dir == 1 and 2 or 1]
  convoy = { entities = {}, cargo = nil, startedAt = GetGameTimer() }
  lib.notify({ title = 'Engines. A lot of them. Military.', type = 'inform' })
  for i = 1, C.escorts + 1 do
    local vm = joaat(i == 1 and 'barracks' or C.vehicles[math.random(#C.vehicles)])
    RequestModel(vm); while not HasModelLoaded(vm) do Wait(10) end
    local veh = CreateVehicle(vm, from.x + (i * 8.0), from.y, from.z, 0.0, false, true)
    SetVehicleEngineOn(veh, true, true, false)
    local pm = joaat('s_m_y_marine_01'); RequestModel(pm); while not HasModelLoaded(pm) do Wait(10) end
    local driver = CreatePedInsideVehicle(veh, 4, pm, -1, false, true)
    SetPedRelationshipGroupHash(driver, `OUTBREAK_MIL`)
    GiveWeaponToPed(driver, `WEAPON_CARBINERIFLE`, 200, false, true)
    SetPedCombatAttributes(driver, 46, true)
    TaskVehicleDriveToCoordLongrange(driver, veh, to.x, to.y, to.z, 22.0, 786603, 10.0)
    convoy.entities[#convoy.entities + 1] = veh; convoy.entities[#convoy.entities + 1] = driver
    if i == 1 then convoy.cargo = veh end
  end
  -- cargo target: only when the truck is stopped and its driver is dead
  exports.ox_target:addLocalEntity(convoy.cargo, { {
    label = 'Break into the cargo',
    icon = 'fa-solid fa-truck',
    canInteract = function(e)
      local d = GetPedInVehicleSeat(e, -1)
      return (d == 0 or IsEntityDead(d)) and GetEntitySpeed(e) < 1.0
    end,
    onSelect = function()
      if exports.outbreak_minigames:play('pinsweep', { pins = 4, speed = 1.3 }) then
        TriggerServerEvent('outbreak:server:convoyLooted')
        TriggerEvent('outbreak:client:radioMsg', 7, 'MILITARY NET', 'Convoy hit! Convoy hit! Responding.')
      else TriggerEvent('outbreak:noise:spike', 80) end
    end } })
  -- expire after 12 minutes or when it reaches the far post
  CreateThread(function()
    while convoy do
      Wait(5000)
      local c = GetEntityCoords(convoy.cargo)
      if #(c - to) < 25.0 or GetGameTimer() - convoy.startedAt > 12 * 60000 then cleanupConvoy() end
    end
  end)
end)
