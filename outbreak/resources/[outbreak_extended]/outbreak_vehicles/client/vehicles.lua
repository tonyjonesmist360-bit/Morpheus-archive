-- outbreak_vehicles/client/vehicles.lua — v2: reads statebags, asks the server, never decides.
local registered = {}
local function st(veh) return Entity(veh).state.veh end
local function netOf(veh) return NetworkGetNetworkIdFromEntity(veh) end

-- register nearby vehicles once (from the core tick — no loop of our own)
local n = 0
AddEventHandler('outbreak:tick', function(t)
  n = n + 1; if n % 4 ~= 0 then return end
  for _, veh in ipairs(GetGamePool('CVehicle')) do
    if not registered[veh] and #(GetEntityCoords(veh) - t.pos) < 60.0 and NetworkGetEntityIsNetworked(veh) then
      registered[veh] = true
      local id = netOf(veh)
      TriggerServerEvent('outbreak:veh:register', id)
      TriggerServerEvent('outbreak:veh:class', id, GetVehicleClass(veh))
      -- a car restored from the DB carries its saved damage until one client applies it
      local v = st(veh)
      if v and v.restore then
        if v.restore.body then SetVehicleBodyHealth(veh, v.restore.body + 0.0) end
        if v.restore.engine then SetVehicleEngineHealth(veh, v.restore.engine + 0.0) end
        TriggerServerEvent('outbreak:veh:restored', id)
      end
    end
  end
end)

-- engine gate + dashboard from statebag (server is the truth)
local lastReason
AddEventHandler('outbreak:tick', function(t)
  if t.veh == 0 or GetPedInVehicleSeat(t.veh, -1) ~= t.ped then if lastReason then lib.hideTextUI(); lastReason = nil end return end
  local v = st(t.veh); if not v then return end
  local reason = (v.battery == 'dead' and (v.boat and 'Dead battery — install a battery' or 'Dead battery — install a car battery')) or (v.part and ('Missing part: ' .. tostring(v.part):gsub('_', ' '))) or (v.fuel <= 0 and 'Tank is dry — pour from a can') or (not v.hotwired and not v.locked and 'No keys — press [E] to splice the ignition') or nil
  if reason then
    SetVehicleEngineOn(t.veh, false, true, true); SetVehicleUndriveable(t.veh, true)
    if reason ~= lastReason then lib.showTextUI(reason, { icon = 'car' }); lastReason = reason end
    if reason:find('splice') and IsControlJustPressed(0, 38) then
      lib.hideTextUI(); lastReason = nil
      local ok, token = exports.outbreak_minigames:play('splice', { length = 5, showMs = 1800 }, 'veh:splice:' .. netOf(t.veh))
      if ok then TriggerServerEvent('outbreak:veh:hotwired', netOf(t.veh), token)
      else TriggerEvent('outbreak:noise:spike', 35) end
    end
  else
    if lastReason then lib.hideTextUI(); lastReason = nil end
    SetVehicleUndriveable(t.veh, false)
    SetVehicleFuelLevel(t.veh, v.fuel * 0.65)
    if v.boat and (GlobalState.obWeather == 'THUNDER') and t.speedKmh > 10 then lib.notify({ title = 'The sea is trying to kill you.', description = 'Fuel burn doubled. Turn back or pray.', type = 'error', duration = 4000 }) end
  end
end)

-- lock enforcement
AddStateBagChangeHandler('veh', nil, function(bag, key, value)
  local ent = GetEntityFromStateBagName(bag); if not ent or ent == 0 then return end
  Wait(0); SetVehicleDoorsLocked(ent, value and value.locked and 2 or 1)
end)

-- a mechanic job: skill check (minigame with a server token) unless your mechanics level waives it, then the hands
function mechanicJob(veh, kind, event, ms, label)
  local M = VehCfg.Mechanics[kind]; local netId = netOf(veh)
  local lvl = 0; pcall(function() lvl = exports.outbreak_skills:getLevel('mechanics') end)
  local token = nil
  if lvl < VehCfg.Mechanics.SkipLevel then
    local ok; ok, token = exports.outbreak_minigames:play(M.game, M.opts, ('veh:%s:%s'):format(kind, netId))
    if not ok then TriggerEvent('outbreak:noise:spike', 40); lib.notify({ title = 'Slipped.', description = 'Try again, or find someone who knows engines.', type = 'error' }) return end
  end
  if exports.outbreak_emotes:action('repair', ms, label) then TriggerServerEvent(event, netId, token) end
end

-- targets
CreateThread(function()
  exports.ox_target:addGlobalVehicle({
    { label = 'Lock / unlock', icon = 'fa-solid fa-key', canInteract = function(e) local v = st(e); return v and v.claimed end,
      onSelect = function(d) TriggerServerEvent('outbreak:veh:toggleLock', netOf(d.entity)) end },
    { label = 'Pry the door', icon = 'fa-solid fa-door-open', item = VehCfg.LockpickItem, canInteract = function(e) local v = st(e); return v and v.locked end,
      onSelect = function(d)
        TriggerEvent('outbreak:noise:spike', 40)
        local ok, token = exports.outbreak_minigames:play('pry', { pulls = 3, width = 18 }, 'veh:pry:' .. netOf(d.entity))
        if ok then TriggerServerEvent('outbreak:veh:pried', netOf(d.entity), token); TriggerEvent('outbreak:noise:spike', 55)
        else TriggerEvent('outbreak:noise:spike', 70); lib.notify({ title = 'The crowbar skips off the frame. Loudly.', type = 'error' }) end
      end },
    -- MECHANICS (Q1): battery and parts are a skill check. Level >= SkipLevel skips the game; the server knows your level too.
    { label = 'Install battery', icon = 'fa-solid fa-car-battery', item = VehCfg.BatteryItem, canInteract = function(e) local v = st(e); return v and v.battery == 'dead' end,
      onSelect = function(d) mechanicJob(d.entity, 'battery', 'outbreak:veh:battery', 9000, 'Swapping battery...') end },
    { label = 'Fit the missing part', icon = 'fa-solid fa-wrench', canInteract = function(e) local v = st(e); return v and v.part end,
      onSelect = function(d)
        local mult = 1.0; pcall(function() mult = exports.outbreak_skills:effects('mechanics').repairTime end)
        mechanicJob(d.entity, 'part', 'outbreak:veh:part', math.floor(15000 * mult), 'Fitting...') end },
    { label = 'Pull the battery', icon = 'fa-solid fa-car-battery', canInteract = function(e) local v = st(e); return v and v.battery == 'ok' and not v.claimed end,
      onSelect = function(d) mechanicJob(d.entity, 'battery', 'outbreak:veh:stripBattery', VehCfg.Mechanics.StripSeconds, 'Pulling the battery...') end },
    { label = 'Strip engine parts', icon = 'fa-solid fa-screwdriver-wrench', canInteract = function(e) local v = st(e); return v and not v.part and not v.claimed and not v.boat end,
      onSelect = function(d) mechanicJob(d.entity, 'part', 'outbreak:veh:stripPart', VehCfg.Mechanics.StripSeconds, 'Stripping parts...') end },
    { label = 'Siphon fuel', icon = 'fa-solid fa-gas-pump', item = VehCfg.SiphonItem, canInteract = function(e) local v = st(e); return v and v.fuel > 0 end,
      onSelect = function(d) if exports.outbreak_emotes:action('siphon', 10000, 'Siphoning...') then TriggerServerEvent('outbreak:veh:siphon', netOf(d.entity)) end end },
    { label = 'Cut a key (claim)', icon = 'fa-solid fa-key', item = 'key_blank', canInteract = function(e) local v = st(e); return v and v.hotwired and not v.claimed end,
      onSelect = function(d) if exports.outbreak_emotes:action('repair', 6000, 'Cutting a key...') then TriggerServerEvent('outbreak:veh:claim', netOf(d.entity)) end end },
    -- trunk: stand at the back. Locked cars need the key (server checks); the label says so.
    { label = 'Open the trunk', icon = 'fa-solid fa-box-open',
      canInteract = function(e) local v = st(e); if not v then return false end
        local back = GetOffsetFromEntityInWorldCoords(e, 0.0, -2.2, 0.0)
        return #(GetEntityCoords(PlayerPedId()) - back) < 2.6 end,
      onSelect = function(d)
        if exports.outbreak_emotes:action('search', 1200, 'Opening the trunk...') then TriggerServerEvent('outbreak:veh:trunk', netOf(d.entity)) end end },
  })
end)

-- glovebox: from the driver or passenger seat. /glovebox, and the wheel when you sit in a car.
RegisterCommand('glovebox', function()
  local veh = GetVehiclePedIsIn(PlayerPedId(), false)
  if veh == 0 then lib.notify({ title = 'Sit in the car first.', type = 'error' }) return end
  TriggerServerEvent('outbreak:veh:glovebox', netOf(veh))
end, false)

-- pour target: the can was used; pick the vehicle you're next to / in
RegisterNetEvent('outbreak:veh:askPourTarget', function(slot, pct, canName)
  local ped = PlayerPedId(); local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 then local p = GetEntityCoords(ped); veh = GetClosestVehicle(p.x, p.y, p.z, 4.0, 0, 71) end
  if veh == 0 then lib.notify({ title = 'Stand next to the tank.', type = 'error' }) return end
  if exports.outbreak_emotes:action('siphon', 6000, 'Pouring...') then TriggerServerEvent('outbreak:veh:pour', netOf(veh), slot, canName) end
end)

-- zombies vs idlers (uses core registry; drives the drag-out on the *zombie*, not the state store)
local adjacentSince
AddEventHandler('outbreak:tick', function(t)
  if not VehCfg.DragOut.enabled or t.veh == 0 or t.speedKmh > 5.0 then adjacentSince = nil return end
  if t.nearestDist < 2.5 then
    adjacentSince = adjacentSince or GetGameTimer()
    if GetGameTimer() - adjacentSince > VehCfg.DragOut.idleSeconds * 1000 then
      SmashVehicleWindow(t.veh, 0)
      if math.random() < VehCfg.DragOut.dragChance then TaskEnterVehicle(t.nearestZombie, t.veh, 5000, -1, 2.0, 8, 0); lib.notify({ title = 'It\'s coming through the window!', type = 'error' }) end
      adjacentSince = GetGameTimer()
    end
  else adjacentSince = nil end
end)

exports('getState', function(veh) return st(veh) end)
