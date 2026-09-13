-- outbreak_broadcast/client/broadcast.lua
local function myChannel()
  local ok, ch = pcall(function() return exports['pma-voice']:getRadioChannel() end)
  return ok and ch or 0
end

local function street(pos)
  local s1 = GetStreetNameAtCoord(pos.x, pos.y, pos.z)
  return GetStreetNameFromHashKey(s1)
end

RegisterNetEvent('outbreak:client:radioMsg', function(ch, title, text)
  if myChannel() ~= ch then return end
  if text:find('__STREET__') and pendingDistress then text = text:gsub('__STREET__', street(pendingDistress.pos)) end
  lib.notify({ title = ('[CH %d] %s'):format(ch, title), description = text, type = 'inform', duration = 12000, position = 'top' })
end)

-- Numbers cache: marker + open
local cache, cacheBlip = nil, nil
RegisterNetEvent('outbreak:client:cacheActive', function(c)
  if cacheBlip then RemoveBlip(cacheBlip); cacheBlip = nil end
  cache = c
end)
CreateThread(function()
  while true do
    Wait(1000)
    if cache then
      local d = #(GetEntityCoords(PlayerPedId()) - cache.pos)
      if d < 40.0 then
        if cache.bait and not cache.sprung then
          cache.sprung = true
          lib.notify({ title = 'Tire tracks. Fresh. Too fresh.', type = 'error' })
          TriggerEvent('outbreak:client:raiderAmbushOnFoot') -- outbreak_raiders listens
        elseif not cache.bait and not cache.zone then
          cache.zone = exports.ox_target:addSphereZone({ coords = cache.pos, radius = 2.0, options = { {
            label = 'Open the cache', icon = 'fa-solid fa-box', onSelect = function() TriggerServerEvent('outbreak:server:cacheOpened', cache.id) end } } })
        end
      end
    end
  end
end)

-- Distress: a survivor to reach (or a trap)
pendingDistress = nil
local dPeds = {}
RegisterNetEvent('outbreak:client:distressActive', function(d, ch)
  for _, p in ipairs(dPeds) do if DoesEntityExist(p) then DeleteEntity(p) end end
  dPeds = {}
  pendingDistress = d
end)
CreateThread(function()
  while true do
    Wait(1500)
    if pendingDistress and not pendingDistress.spawned then
      local d = #(GetEntityCoords(PlayerPedId()) - pendingDistress.pos)
      if d < 60.0 then
        pendingDistress.spawned = true
        local found, z = GetGroundZFor_3dCoord(pendingDistress.pos.x, pendingDistress.pos.y, pendingDistress.pos.z + 50.0, false)
        local pos = vector3(pendingDistress.pos.x, pendingDistress.pos.y, found and z or pendingDistress.pos.z)
        if pendingDistress.bait then
          TriggerEvent('outbreak:client:raiderAmbushOnFoot')
          lib.notify({ title = 'The "wounded" stand up. Armed.', type = 'error' })
        else
          local m = joaat(BroadcastCfg.Distress.survivorModels[math.random(#BroadcastCfg.Distress.survivorModels)])
          RequestModel(m); while not HasModelLoaded(m) do Wait(10) end
          local ped = CreatePed(4, m, pos.x, pos.y, pos.z, 0.0, false, true)
          SetBlockingOfNonTemporaryEvents(ped, true); TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_BUM_SLUMPED', 0, true)
          dPeds[#dPeds + 1] = ped
          TriggerEvent('outbreak:client:horde', 10) -- they really are pinned
          exports.ox_target:addLocalEntity(ped, { { label = 'Help the survivor', icon = 'fa-solid fa-hand-holding-heart', onSelect = function()
            if lib.progressCircle({ duration = 6000, label = 'Getting them up...', canCancel = true }) then
              TriggerServerEvent('outbreak:server:distressResolved', pendingDistress.id)
              TaskSmartFleePed(ped, PlayerPedId(), 200.0, -1, false, false)
            end end } })
        end
      end
    end
  end
end)
