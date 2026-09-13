-- outbreak_housing/client/housing.lua (v2)
local barricadeProps = {}
local inside = nil  -- house id while inside an interior

local function spawnOccupants(door)
  for i = 1, math.random(HousingCfg.OccupantCount[1], HousingCfg.OccupantCount[2]) do
    local model = joaat(HousingCfg.OccupantModels[math.random(#HousingCfg.OccupantModels)])
    RequestModel(model); while not HasModelLoaded(model) do Wait(10) end
    local ped = CreatePed(4, model, door.x + math.random(-3, 3), door.y + math.random(-3, 3), door.z, 0.0, true, true)
    GiveWeaponToPed(ped, `WEAPON_BAT`, 1, false, true)
    SetPedCombatAttributes(ped, 46, true)
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
  end
  lib.notify({ title = 'This place isn\'t empty!', type = 'error' })
end

local function renderBarricade(houseId, door, level)
  for _, p in ipairs(barricadeProps[houseId] or {}) do DeleteEntity(p) end
  barricadeProps[houseId] = {}
  local model = `prop_ld_planks01`
  RequestModel(model); local t = GetGameTimer()
  while not HasModelLoaded(model) and GetGameTimer() - t < 2000 do Wait(10) end
  if not HasModelLoaded(model) then model = `prop_mb_crate_01a`; RequestModel(model); while not HasModelLoaded(model) do Wait(10) end end
  for i = 1, level do
    local prop = CreateObject(model, door.x, door.y, door.z - 0.9 + (i * 0.4), false, false, false)
    SetEntityRotation(prop, 0.0, 0.0, 90.0 * i, 2, true)
    FreezeEntityPosition(prop, true)
    barricadeProps[houseId][#barricadeProps[houseId] + 1] = prop
  end
end

RegisterNetEvent('outbreak:client:barricadeLevel', function(houseId, level)
  for _, h in ipairs(HousingCfg.Houses) do if h.id == houseId then renderBarricade(houseId, h.door, level) end end
end)

local function teleport(pos, heading)
  DoScreenFadeOut(500); Wait(600)
  SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z)
  SetEntityHeading(PlayerPedId(), heading or 0.0)
  Wait(300); DoScreenFadeIn(500)
end

local function doorMenu(h)
  local info = lib.callback.await('outbreak:houseInfo', false, h.id)
  if not info then return end
  if info.occupiedRoll then spawnOccupants(h.door) return end
  if info.story then lib.notify({ title = h.label, description = info.story, type = 'inform', duration = 10000 }) end
  local opts = {}
  -- temporary shelter: nobody owns it -> you can go in and search it without claiming
  if not info.owner and h.interior then
    opts[#opts + 1] = { title = 'Shelter inside (no claim)', icon = 'person-shelter', description = 'Wait out the night. Anyone can walk in.', onSelect = function() inside = h.id; teleport(h.interior, h.interior.w) end }
  end
  if not info.owner or info.hasKey then
    local sub = {}
    for i, sp in ipairs(HousingCfg.SearchSpots) do
      sub[#sub + 1] = { title = sp.name, onSelect = function()
        if exports.outbreak_emotes:action('search', 6000, 'Searching ' .. sp.name:lower() .. '...') then TriggerServerEvent('outbreak:server:houseSearch', h.id, i) end end }
    end
    lib.registerContext({ id = 'house_search_' .. h.id, title = 'Search ' .. h.label, menu = 'house_' .. h.id, options = sub })
    opts[#opts + 1] = { title = 'Search the house', icon = 'magnifying-glass', menu = 'house_search_' .. h.id }
  end
  if not info.owner then
    opts[#opts + 1] = { title = 'Claim safehouse', description = 'No paperwork. You just take it.', event = 'outbreak:client:doClaim', args = h.id }
  end
  if info.hasKey then
    if h.interior then
      opts[#opts + 1] = { title = 'Go inside', icon = 'door-open', onSelect = function()
        inside = h.id; teleport(h.interior, h.interior.w) end }
    end
    opts[#opts + 1] = { title = 'Open storage', icon = 'box', event = 'outbreak:client:openStash', args = h.id }
    opts[#opts + 1] = { title = ('Barricade (lvl %d)'):format(info.barricade), icon = 'hammer', event = 'outbreak:client:doBarricade', args = h.id }
  end
  if info.isMine then
    opts[#opts + 1] = { title = 'Cut a spare key', icon = 'key', description = 'Hand it to whoever you trust.', event = 'outbreak:client:cutKey', args = h.id }
  end
  if not info.hasKey and info.owner then
    opts[#opts + 1] = { title = 'Force the lock', icon = 'user-secret',
      description = 'Someone lives here. Their barricades make this harder.',
      event = 'outbreak:client:forceLock', args = { id = h.id, barricade = info.barricade, interior = h.interior ~= nil } }
  end
  lib.registerContext({ id = 'house_' .. h.id, title = h.label, options = opts })
  lib.showContext('house_' .. h.id)
end

CreateThread(function()
  for _, h in ipairs(HousingCfg.Houses) do
    exports.ox_target:addSphereZone({ coords = h.door, radius = 1.5, options = {
      { label = 'Door — ' .. h.label, icon = 'fa-solid fa-house', onSelect = function() doorMenu(h) end } } })
    if h.interior then
      -- exit point just inside the door
      exports.ox_target:addSphereZone({ coords = vec3(h.interior.x, h.interior.y, h.interior.z), radius = 1.5, options = {
        { label = 'Leave', icon = 'fa-solid fa-door-closed', onSelect = function()
            inside = nil; teleport(h.door, 0.0) end } } })
    end
    local blip = AddBlipForCoord(h.door.x, h.door.y, h.door.z)
    SetBlipSprite(blip, 40); SetBlipScale(blip, 0.6); SetBlipColour(blip, 0)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(h.label); EndTextCommandSetBlipName(blip)
  end
end)

RegisterNetEvent('outbreak:client:forceLock', function(data)
  TriggerEvent('outbreak:noise:spike', 30)
  local pins = 2 + (data.barricade or 0)
  if exports.outbreak_minigames:play('pinsweep', { pins = pins, speed = 1.0 + pins * 0.1 }) then
    lib.notify({ title = 'You\'re in.', type = 'success' })
    TriggerServerEvent('outbreak:server:forcedEntry', data.id)
  else
    TriggerEvent('outbreak:noise:spike', 75)
    lib.notify({ title = 'The lock jams shut.', type = 'error' })
  end
end)

RegisterNetEvent('outbreak:client:doClaim', function(id) TriggerServerEvent('outbreak:server:claimHouse', id) end)
RegisterNetEvent('outbreak:client:cutKey', function(id) TriggerServerEvent('outbreak:server:cutKey', id) end)
RegisterNetEvent('outbreak:client:doBarricade', function(id)
  if exports.outbreak_emotes:action('barricade', 8000, 'Nailing planks...') then TriggerServerEvent('outbreak:server:barricade', id) end
end)
RegisterNetEvent('outbreak:client:openStash', function(id) TriggerServerEvent('outbreak:server:openHouseStash', id) end)

-- Wardrobe inside every interior (free — the apocalypse has no clothing stores)
CreateThread(function()
  for _, h in ipairs(HousingCfg.Houses) do
    if h.interior then
      exports.ox_target:addSphereZone({ coords = vec3(h.interior.x + 2.0, h.interior.y, h.interior.z), radius = 1.2, options = { {
        label = 'Wardrobe', icon = 'fa-solid fa-shirt', onSelect = function() ExecuteCommand('wardrobe') end } } })
    end
  end
end)
