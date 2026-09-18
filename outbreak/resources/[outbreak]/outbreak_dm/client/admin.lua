-- outbreak_dm/client/admin.lua — the admin half of the Director: movement (noclip/flight), god,
-- spectate, entity gun, coords, zombie tools, vehicle kit, player panel. Every state change that
-- other players must see (god/ghost) goes through the server; the rest is the admin's own client.
local function act(action, a) TriggerServerEvent('outbreak:dm:do', action, a or {}) end
local function isDM() return LocalPlayer.state.isDM == true end
local function deny() lib.notify({ title = 'Not a director.', type = 'error' }) end

-- ── aimed entity / ground point (same raycast the debug tools use) ──
local function camRay(dist)
  local cam = GetGameplayCamCoord(); local rot = GetGameplayCamRot(2)
  local dir = vector3(-math.sin(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.cos(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.sin(math.rad(rot.x)))
  local to = cam + dir * (dist or 60.0)
  local ray = StartShapeTestRay(cam.x, cam.y, cam.z, to.x, to.y, to.z, 1 + 2 + 4 + 8 + 16, PlayerPedId(), 0)
  local _, hit, pos, _, ent = GetShapeTestResult(ray)
  return hit == 1, pos, ent
end

-- ── NOCLIP / FLIGHT ──
local noclip, noclipSpeed = false, 1.0
RegisterCommand('noclip', function()
  if not isDM() then deny() return end
  noclip = not noclip
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, noclip); SetEntityCollision(ped, not noclip, not noclip); SetEntityInvincible(ped, noclip)
  if noclip then lib.showTextUI('NOCLIP  WASD move · Space up · Ctrl down · Shift fast · /noclip off', { position = 'top-center' }) else lib.hideTextUI(); SetEntityVisible(ped, not (LocalPlayer.state.obGhost == true), false) end
  lib.notify({ title = noclip and 'Noclip on.' or 'Noclip off.', type = 'inform', duration = 2000 })
end, false)
CreateThread(function()
  while true do
    if noclip then
      Wait(0)
      local ped = PlayerPedId()
      local rot = GetGameplayCamRot(2)
      local fwd = vector3(-math.sin(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.cos(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.sin(math.rad(rot.x)))
      local right = vector3(math.cos(math.rad(rot.z)), math.sin(math.rad(rot.z)), 0.0)
      local spd = (IsControlPressed(0, 21) and 3.0 or 1.0) * noclipSpeed
      local pos = GetEntityCoords(ped)
      if IsControlPressed(0, 32) then pos = pos + fwd * spd end
      if IsControlPressed(0, 33) then pos = pos - fwd * spd end
      if IsControlPressed(0, 34) then pos = pos - right * spd end
      if IsControlPressed(0, 35) then pos = pos + right * spd end
      if IsControlPressed(0, 22) then pos = pos + vector3(0, 0, spd) end
      if IsControlPressed(0, 36) then pos = pos - vector3(0, 0, spd) end
      SetEntityCoordsNoOffset(ped, pos.x, pos.y, pos.z, true, true, true)
      SetEntityHeading(ped, rot.z)
      for _, c in ipairs({ 24, 25, 37, 44, 140, 141, 142 }) do DisableControlAction(0, c, true) end
    else Wait(300) end
  end
end)

-- ── GOD (visible, unkillable) — separate from ghost ──
RegisterNetEvent('outbreak:dm:god', function(on)
  local ped = PlayerPedId()
  SetEntityInvincible(ped, on); SetPlayerInvincible(PlayerId(), on)
  if on then SetEntityHealth(ped, 200) end
  if not LocalPlayer.state.obTest then lib.notify({ title = on and 'God mode on. Visible, unkillable.' or 'God mode off.', type = 'inform' }) end
end)
-- god holds: invincibility does not stop scripts that SET health (survival damage, down pipeline); those check obGod,
-- and this tops the bar up from the core tick so nothing can chip it
AddEventHandler('outbreak:tick', function(t)
  if LocalPlayer.state.obGod and GetEntityHealth(t.ped) < 200 then SetEntityHealth(t.ped, 200) end
end)

-- ── GHOST: other clients hide a ghosted player's ped; NPCs ignore the ghost ──
AddStateBagChangeHandler('obGhost', nil, function(bag, _, value)
  local sid = tonumber(bag:match('player:(%d+)')); if not sid then return end
  if sid == GetPlayerServerId(PlayerId()) then return end   -- own ghost look is handled by outbreak:dm:ghost in dm.lua
  local pid = GetPlayerFromServerId(sid); if pid == -1 then return end
  local ped = GetPlayerPed(pid); if ped == 0 then return end
  SetEntityVisible(ped, not value, false)
end)

-- ── SPECTATE ──
local spectating = nil
RegisterNetEvent('outbreak:dm:spectate', function(target)
  local me = PlayerPedId()
  if spectating or not target then
    NetworkSetInSpectatorMode(false, me); spectating = nil
    lib.hideTextUI(); lib.notify({ title = 'Spectate off.', type = 'inform' })
    if not target then return end
  end
  local pid = GetPlayerFromServerId(target)
  local ped = pid ~= -1 and GetPlayerPed(pid) or 0
  if ped == 0 then lib.notify({ title = 'Too far to spectate.', description = 'Teleport near them first (Player panel → Teleport), then spectate.', type = 'error', duration = 7000 }) return end
  spectating = target
  NetworkSetInSpectatorMode(true, ped)
  lib.showTextUI(('SPECTATING %s  ·  /spectate to stop'):format(GetPlayerName(pid) or target), { position = 'top-center' })
end)
RegisterCommand('spectate', function() if isDM() then act('spectate', { target = nil }) else deny() end end, false)

-- ── per-player effects the server asks for ──
RegisterNetEvent('outbreak:dm:heal', function() local p = PlayerPedId(); SetEntityHealth(p, 200); ClearPedBloodDamage(p); lib.notify({ title = 'An admin patched you up.', type = 'success' }) end)
RegisterNetEvent('outbreak:dm:freeze', function(on) FreezeEntityPosition(PlayerPedId(), on); lib.notify({ title = on and 'You cannot move. An admin froze you.' or 'You can move again.', type = on and 'error' or 'inform' }) end)

-- ── ENTITY GUN ──
local gun = false
RegisterCommand('entitygun', function()
  if not isDM() then deny() return end
  gun = not gun
  if gun then lib.showTextUI('ENTITY GUN  aim + left click = delete · /entitygun off', { position = 'top-center' }) else lib.hideTextUI() end
end, false)
CreateThread(function()
  while true do
    if gun then
      Wait(0)
      DisableControlAction(0, 24, true); DisableControlAction(0, 257, true)
      local hit, pos, ent = camRay(80.0)
      if hit and ent and ent ~= 0 then DrawMarker(28, pos.x, pos.y, pos.z, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, 180, 85, 45, 120, false, true, 2, false, nil, nil, false) end
      if IsDisabledControlJustPressed(0, 24) and hit and ent and ent ~= 0 and not IsPedAPlayer(ent) then
        if NetworkGetEntityIsNetworked(ent) then act('entitydel', { netId = NetworkGetNetworkIdFromEntity(ent) })
        else SetEntityAsMissionEntity(ent, true, true); DeleteEntity(ent) end
        lib.notify({ title = 'Deleted.', type = 'inform', duration = 1200 })
      end
    else Wait(300) end
  end
end)

-- ── COORDS ──
RegisterCommand('coords', function()
  local p = GetEntityCoords(PlayerPedId()); local h = GetEntityHeading(PlayerPedId())
  local s = ('vec4(%.2f, %.2f, %.2f, %.1f)'):format(p.x, p.y, p.z, h)
  pcall(function() lib.setClipboard(s) end)
  lib.notify({ title = 'Copied to clipboard', description = s, type = 'inform', duration = 8000 })
  print('[COORDS] ' .. s)
end, false)

-- ── ZOMBIE TOOLS (the DM's client owns the spawns it makes; clear/freeze act on core's registry) ──
RegisterNetEvent('outbreak:dm:zombieAtCursor', function(count, variant)
  local hit, pos = camRay(120.0)
  if not hit then lib.notify({ title = 'Aim at the ground.', type = 'error' }) return end
  for i = 1, count or 1 do exports.outbreak_core:spawnZombieAt(pos + vector3(math.random(-3, 3), math.random(-3, 3), 0.5)); Wait(120) end
end)
RegisterNetEvent('outbreak:dm:zombieClear', function(radius)
  local me = GetEntityCoords(PlayerPedId()); local n = 0
  for _, z in ipairs(exports.outbreak_core:getZombies() or {}) do
    if DoesEntityExist(z) and #(GetEntityCoords(z) - me) <= (radius or 60.0) then SetEntityAsMissionEntity(z, true, true); DeleteEntity(z); n = n + 1 end
  end
  lib.notify({ title = ('Cleared %d within %dm.'):format(n, radius or 60), type = 'inform' })
end)
local zFrozen = false
RegisterNetEvent('outbreak:dm:zombieFreeze', function()
  zFrozen = not zFrozen
  for _, z in ipairs(exports.outbreak_core:getZombies() or {}) do
    if DoesEntityExist(z) then FreezeEntityPosition(z, zFrozen); if zFrozen then ClearPedTasksImmediately(z) end end
  end
  lib.notify({ title = zFrozen and 'Zombie AI frozen (the ones loaded now).' or 'Zombie AI released.', type = 'inform' })
end)

-- ── TELEPORT ──
RegisterNetEvent('outbreak:dm:tpWaypoint', function()
  local b = GetFirstBlipInfoId(8)
  if not DoesBlipExist(b) then lib.notify({ title = 'No waypoint set.', type = 'error' }) return end
  local c = GetBlipInfoIdCoord(b)
  local ped = PlayerPedId()
  DoScreenFadeOut(300); Wait(350)
  local z = 800.0
  for _ = 1, 40 do
    SetEntityCoordsNoOffset(ped, c.x, c.y, z, false, false, false); Wait(50)
    local ok, gz = GetGroundZFor_3dCoord(c.x, c.y, z, false)
    if ok then z = gz + 1.0 break end
    z = z - 25.0
  end
  SetEntityCoords(ped, c.x, c.y, z); Wait(200); DoScreenFadeIn(300)
end)

-- ── VEHICLE KIT (current vehicle, or the one you aim at) ──
local function targetVehicle()
  local ped = PlayerPedId()
  local v = GetVehiclePedIsIn(ped, false)
  if v ~= 0 then return v end
  local hit, _, ent = camRay(40.0)
  if hit and ent and ent ~= 0 and IsEntityAVehicle(ent) then return ent end
  return 0
end
RegisterNetEvent('outbreak:dm:vehicle', function(op)
  local v = targetVehicle()
  if v == 0 then lib.notify({ title = 'No vehicle: sit in one or aim at one.', type = 'error' }) return end
  if op == 'repair' then SetVehicleFixed(v); SetVehicleDeformationFixed(v); SetVehicleEngineHealth(v, 1000.0); SetVehicleBodyHealth(v, 1000.0); SetVehicleDirtLevel(v, 0.0); lib.notify({ title = 'Repaired.', type = 'success' })
  elseif op == 'refuel' then SetVehicleFuelLevel(v, 100.0); if NetworkGetEntityIsNetworked(v) then act('vehfuel', { netId = NetworkGetNetworkIdFromEntity(v) }) end; lib.notify({ title = 'Refuelled.', type = 'success' })
  elseif op == 'keys' or op == 'lock' then
    if not NetworkGetEntityIsNetworked(v) then lib.notify({ title = 'That vehicle is not networked.', type = 'error' }) return end
    if op == 'keys' then SetVehicleFixed(v); SetVehicleEngineHealth(v, 1000.0) end
    act(op == 'keys' and 'vehkeys' or 'vehlock', { netId = NetworkGetNetworkIdFromEntity(v) })
  elseif op == 'delete' then
    if NetworkGetEntityIsNetworked(v) then act('entitydel', { netId = NetworkGetNetworkIdFromEntity(v) }) else SetEntityAsMissionEntity(v, true, true); DeleteEntity(v) end
    lib.notify({ title = 'Deleted.', type = 'inform' })
  end
end)

-- ── GIVE with a searchable item list (ox_inventory's own catalogue) ──
RegisterNetEvent('outbreak:dm:giveSearch', function(target)
  local items = {}
  local ok, cat = pcall(function() return exports.ox_inventory:Items() end)
  if ok and type(cat) == 'table' then
    for name, def in pairs(cat) do items[#items + 1] = { value = name, label = (def.label or name) .. '  (' .. name .. ')' } end
  end
  table.sort(items, function(a, b) return a.label < b.label end)
  local i = lib.inputDialog('Give item', {
    { type = 'select', label = 'Item', options = items, searchable = true, required = true },
    { type = 'number', label = 'Count', default = 1, min = 1, max = 250 } })
  if i then act('item', { target = target, name = i[1], count = i[2] }) end
end)

AddEventHandler('onResourceStop', function(r)
  if r ~= GetCurrentResourceName() then return end
  local ped = PlayerPedId()
  if noclip then FreezeEntityPosition(ped, false); SetEntityCollision(ped, true, true) end
  if spectating then NetworkSetInSpectatorMode(false, ped) end
  lib.hideTextUI()
end)
