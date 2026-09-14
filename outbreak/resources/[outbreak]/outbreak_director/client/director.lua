-- outbreak_director/client/director.lua : the one encounter that needs a body — a stranger at the door.
local active = {}   -- encounter id -> ped

local function spawnStranger(e)
  local models = DirectorCfg.StrangerModels
  local m = joaat(models[math.random(#models)])
  RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 3000 do Wait(10) end
  if not HasModelLoaded(m) then return nil end
  local d = e.door
  local a = math.random() * 6.283
  local x, y = d.x + math.cos(a) * 9.0, d.y + math.sin(a) * 9.0
  local found, z = GetGroundZFor_3dCoord(x, y, d.z + 5.0, false)
  local ped = CreatePed(4, m, x, y, found and z or d.z, 0.0, false, true)
  SetEntityAsMissionEntity(ped, true, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetPedRelationshipGroupHash(ped, `OUTBREAK_MIL`)   -- same group outbreak_dm gives friendly survivors
  SetModelAsNoLongerNeeded(m)
  TaskGoStraightToCoord(ped, d.x + 1.2, d.y + 1.2, d.z, 1.0, -1, 0.0, 0.5)
  return ped
end

RegisterNetEvent('outbreak:director:stranger', function(e)
  local ped = spawnStranger(e); if not ped then return end
  active[e.id] = ped
  lib.notify({ title = 'Someone at the door of ' .. e.label, description = 'Not one of the dead. Hands where you can see them.', type = 'inform', duration = 10000 })
  exports.ox_target:addLocalEntity(ped, {
    { label = 'Talk', icon = 'fa-solid fa-comment', onSelect = function() lib.notify({ title = 'Stranger', description = e.line, type = 'inform', duration = 9000 }) end },
    { label = 'Take them in', icon = 'fa-solid fa-house-user', onSelect = function() TriggerServerEvent('outbreak:director:takeIn', e.id) end },
    { label = 'Send them away', icon = 'fa-solid fa-person-walking-arrow-right', onSelect = function() TriggerServerEvent('outbreak:director:sendAway', e.id) end },
  })
  SetTimeout(DirectorCfg.StrangerExpireMinutes * 60000, function()
    local p = active[e.id]; if not p then return end
    active[e.id] = nil
    if DoesEntityExist(p) then TaskWanderStandard(p, 10.0, 10); SetTimeout(25000, function() if DoesEntityExist(p) then DeleteEntity(p) end end) end
  end)
end)

RegisterNetEvent('outbreak:director:strangerResolved', function(id, took)
  local p = active[id]; active[id] = nil
  if not p or not DoesEntityExist(p) then return end
  if took then
    -- walks in: one step to the door, then gone (the interior does not need a body)
    SetTimeout(3500, function() if DoesEntityExist(p) then DeleteEntity(p) end end)
  else
    TaskWanderStandard(p, 10.0, 10)
    SetTimeout(25000, function() if DoesEntityExist(p) then DeleteEntity(p) end end)
  end
end)

AddEventHandler('onResourceStop', function(r)
  if r ~= GetCurrentResourceName() then return end
  for _, p in pairs(active) do if DoesEntityExist(p) then DeleteEntity(p) end end
end)
