-- outbreak_worlditems/client/take.lua — curated map props can be taken; hidden ones stay hidden for everyone
local function applyHidden(h)
  -- CreateModelHide makes the map prop vanish in a radius for this client; every client applies the shared list
  for _, r in pairs(h or {}) do CreateModelHide(r.pos.x, r.pos.y, r.pos.z, 1.0, r.model, true) end
end
AddStateBagChangeHandler('obHiddenProps', 'global', function(_, _, value) Wait(0); applyHidden(value) end)
CreateThread(function() Wait(3000); applyHidden(GlobalState.obHiddenProps) end)

-- SHELVES: grab one item off the shelf
CreateThread(function()
  local models = {}
  for m in pairs(WorldItemsCfg.Shelves) do models[#models + 1] = m end
  exports.ox_target:addModel(models, { {
    label = 'Steal', icon = 'fa-solid fa-mask',
    canInteract = function(e) return Entity(e).state.worldItem == nil end,
    onSelect = function(d)
      local t = WorldItemsCfg.Shelves[GetEntityModel(d.entity)]; if not t then return end
      local pos = GetEntityCoords(d.entity)
      local S = WorldItemsCfg.Steal or {}
      TriggerEvent('outbreak:noise:spike', S.noise or 18)
      if math.random() < (S.dropChance or 0) then TriggerEvent('outbreak:noise:spike', S.dropNoise or 45); lib.notify({ title = 'A can hits the floor.', description = 'Loud.', type = 'error', duration = 2500 }) end
      if exports.outbreak_emotes:action('search', t.seconds * 1000, 'Stuffing it in your bag...') then
        TriggerServerEvent('outbreak:wi:takeProp', GetEntityModel(d.entity), vector3(pos.x, pos.y, pos.z))
        SetEntityAsMissionEntity(d.entity, true, true); DeleteObject(d.entity)
      end
    end } })
end)

-- THE STOCKER: when a shelf restocks while you're in the store, someone walks in and puts it back
RegisterNetEvent('outbreak:wi:restocked', function(pos, item)
  if #(GetEntityCoords(PlayerPedId()) - pos) > 40.0 then return end
  CreateThread(function()
    local m = joaat('a_m_m_farmer_01'); RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 2000 do Wait(10) end
    if not HasModelLoaded(m) then return end
    local ped = CreatePed(4, m, pos.x + 6.0, pos.y + 6.0, pos.z, 0.0, false, true)
    SetBlockingOfNonTemporaryEvents(ped, true); SetPedRelationshipGroupHash(ped, `OUTBREAK_MIL`)
    TaskGoToCoordAnyMeans(ped, pos.x, pos.y, pos.z, 1.2, 0, false, 786603, 0)
    Wait(7000)
    RequestAnimDict('amb@world_human_bum_bin@base'); Wait(300)
    TaskPlayAnim(ped, 'amb@world_human_bum_bin@base', 'base', 8.0, -8.0, 3000, 1, 0, false, false, false)
    Wait(3200)
    TaskWanderStandard(ped, 10.0, 10); SetEntityAsNoLongerNeeded(ped)
  end)
end)

CreateThread(function()
  local models = {}
  for m in pairs(WorldItemsCfg.Takeables) do models[#models + 1] = m end
  exports.ox_target:addModel(models, { {
    label = 'Take this', icon = 'fa-solid fa-hand-holding',
    canInteract = function(e) return Entity(e).state.worldItem == nil end,   -- placed objects have their own "Take"
    onSelect = function(d)
      local t = WorldItemsCfg.Takeables[GetEntityModel(d.entity)]; if not t then return end
      local pos = GetEntityCoords(d.entity)
      if exports.outbreak_emotes:action('search', t.seconds * 1000, 'Taking it...') then
        TriggerServerEvent('outbreak:wi:takeProp', GetEntityModel(d.entity), vector3(pos.x, pos.y, pos.z))
        SetEntityAsMissionEntity(d.entity, true, true); DeleteObject(d.entity)  -- immediate local feedback; the hide list makes it permanent
      end
    end } })
end)
