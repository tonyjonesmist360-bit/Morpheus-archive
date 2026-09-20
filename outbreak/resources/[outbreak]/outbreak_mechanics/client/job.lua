-- outbreak_mechanics/client/job.lua — the delivery on your screen, and the raiders who want the car.
local job = nil
local blip, chase = nil, nil
exports('hasJob', function() return job ~= nil end)
local function clearBlip() if blip and DoesBlipExist(blip) then RemoveBlip(blip) end blip = nil end
RegisterNetEvent('outbreak:mech:job', function(j)
  job = j; clearBlip(); lib.hideTextUI()
  if not j then return end
  blip = AddBlipForCoord(j.pos.x, j.pos.y, j.pos.z); SetBlipSprite(blip, 1); SetBlipColour(blip, 5); SetBlipScale(blip, 0.9); SetBlipRoute(blip, true)
  BeginTextCommandSetBlipName('STRING'); AddTextComponentString('DELIVERY: ' .. j.label); EndTextCommandSetBlipName(blip)
  lib.notify({ title = 'Delivery', description = ('The car (plate %s) is at %s. %d minutes. Bring it back to the Yard and step out.'):format(j.plate, j.label, j.minutes), type = 'inform', duration = 10000 })
end)
-- once you are in the car, the route flips to the Yard; a thin line at the bottom keeps the plate and the clock
local lastUi, inCar = 0, false
AddEventHandler('outbreak:tick', function(t)
  if not job then return end
  if GetGameTimer() - lastUi < 2000 then return end
  lastUi = GetGameTimer()
  local veh = t.veh
  local mine = veh ~= 0 and (GetVehicleNumberPlateText(veh) or ''):gsub('%s+$', '') == job.plate
  if mine and not inCar then
    inCar = true
    if blip and DoesBlipExist(blip) then SetBlipCoords(blip, job.yard.x, job.yard.y, job.yard.z); BeginTextCommandSetBlipName('STRING'); AddTextComponentString('DELIVER TO: the Yard'); EndTextCommandSetBlipName(blip) end
    lib.showTextUI(('DELIVERY %s  ·  to the Yard  ·  do not stop for anyone'):format(job.plate), { position = 'bottom-center' })
  elseif not mine and inCar then inCar = false; lib.hideTextUI() end
end)
-- THE CHASE: two raider cars fall in behind you and try to put you in the ditch
local function loadModel(name) local m = joaat(name); RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 3000 do Wait(10) end return HasModelLoaded(m) and m or nil end
local function endChase()
  if not chase then return end
  for _, e in ipairs(chase.ents) do if DoesEntityExist(e) then DeleteEntity(e) end end
  chase = nil
end
RegisterNetEvent('outbreak:mech:chase', function(netId)
  if chase then return end
  local veh = NetworkGetEntityFromNetworkId(netId); if not veh or veh == 0 then return end
  local C = MechCfg.Chase
  local me = PlayerPedId()
  chase = { ents = {}, at = GetGameTimer(), veh = veh }
  local behind = GetOffsetFromEntityInWorldCoords(veh, 0.0, -C.behind, 0.0)
  local ok, node, heading = GetClosestVehicleNodeWithHeading(behind.x, behind.y, behind.z, 1, 3.0, 0)
  if not ok then node = behind; heading = GetEntityHeading(veh) end
  local pm = loadModel(C.model); if not pm then return end
  for i, carName in ipairs(C.cars) do
    local cm = loadModel(carName)
    if cm then
      local car = CreateVehicle(cm, node.x + (i - 1) * 4.0, node.y - (i - 1) * 4.0, node.z, heading, true, true)
      SetVehicleEngineOn(car, true, true, false); SetVehicleColours(car, 12, 12)
      chase.ents[#chase.ents + 1] = car
      for seat = -1, C.riders - 2 do
        local p = CreatePedInsideVehicle(car, 4, pm, seat, true, true)
        SetEntityAsMissionEntity(p, true, true); SetBlockingOfNonTemporaryEvents(p, true); SetPedRelationshipGroupHash(p, `OUTBREAK_RAIDERS`)
        GiveWeaponToPed(p, joaat(C.weapon), 300, false, true); SetPedInfiniteAmmo(p, true, joaat(C.weapon)); SetPedAccuracy(p, 25); SetPedCombatAttributes(p, 46, true); SetPedCombatAttributes(p, 3, true)
        if seat == -1 then TaskVehicleChase(p, me); SetDriverAbility(p, 1.0); SetDriverAggressiveness(p, 1.0) else TaskDriveBy(p, me, 0, 0.0, 0.0, 0.0, 60.0, 80, true, 1) end
        chase.ents[#chase.ents + 1] = p
      end
    end
  end
  lib.notify({ title = 'Headlights behind you.', description = 'Raiders. They want the car. Do not stop.', type = 'error', duration = 8000 })
  TriggerEvent('outbreak:noise:spike', 60)
end)
-- the chase ends when the car is delivered/lost, when they fall far behind, or when they give up
local lastChase = 0
AddEventHandler('outbreak:tick', function(t)
  if not chase or GetGameTimer() - lastChase < 3000 then return end
  lastChase = GetGameTimer()
  local C = MechCfg.Chase
  local alive, far = 0, true
  for _, e in ipairs(chase.ents) do
    if DoesEntityExist(e) and IsEntityAPed(e) and not IsEntityDead(e) then alive = alive + 1; if #(GetEntityCoords(e) - t.pos) < C.breakOffMetres then far = false end end
  end
  if not job or alive == 0 or far or GetGameTimer() - chase.at > C.giveUpSeconds * 1000 then
    if job and alive > 0 then lib.notify({ title = 'They break off.', type = 'inform' }) end
    endChase()
  end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then endChase(); clearBlip(); lib.hideTextUI() end end)
