-- outbreak_down/client/down.lua
local downState = nil        -- nil | 'unconscious' | 'incapacitated'
local downUntil = 0
local lastUnconscious = 0
local lastDamage = { melee = false, zombie = false }
local beingHelped = false

-- Track what hit us last (weapon hash arrives in the damage event args)
AddEventHandler('gameEventTriggered', function(name, args)
  if name ~= 'CEventNetworkEntityDamage' then return end
  if args[1] ~= PlayerPedId() then return end
  local weapon = args[7]
  local group = GetWeapontypeGroup(weapon)
  lastDamage.melee = (group == `GROUP_MELEE` or group == `GROUP_UNARMED` or weapon == `WEAPON_UNARMED`)
  local attacker = args[2]
  lastDamage.zombie = attacker and GetPedRelationshipGroupHash(attacker) == `OUTBREAK_ZOMBIES` or false
end)

local function setState(s, seconds)
  downState = s
  downUntil = GetGameTimer() + (seconds * 1000)
  LocalPlayer.state:set('downState', s, true)
  SendNUIMessage({ action = 'down', state = s, seconds = seconds })
end

local function clearDown(healthPct)
  local ped = PlayerPedId()
  downState = nil
  LocalPlayer.state:set('downState', nil, true)
  SendNUIMessage({ action = 'down', state = nil })
  ClearPedTasksImmediately(ped)
  SetEntityHealth(ped, 100 + math.floor(healthPct))
  SetPlayerControl(PlayerId(), true, 0)
end

RegisterNetEvent('outbreak:client:enterCritical', function()
  local ped = PlayerPedId()
  setState('critical', DownCfg.Critical.minutes * 60)
  RequestAnimDict('missfinale_c1@'); while not HasAnimDictLoaded('missfinale_c1@') do Wait(10) end
  TaskPlayAnim(ped, 'missfinale_c1@', 'lying_dead_player0', 8.0, -8.0, -1, 1, 0, false, false, false)
  lib.notify({ title = 'You slip under.', description = 'Someone has to get your body to a medic. You have about half an hour.', type = 'error', duration = 12000 })
end)

local function goDown(kind)
  local ped = PlayerPedId()
  if kind == 'unconscious' then
    -- second KO inside the window escalates
    if GetGameTimer() - lastUnconscious < DownCfg.SecondDownWindow * 1000 then
      kind = 'incapacitated'
    else
      lastUnconscious = GetGameTimer()
    end
  end
  if kind == 'unconscious' then
    setState('unconscious', DownCfg.Unconscious.seconds)
    SetPedToRagdoll(ped, DownCfg.Unconscious.seconds * 1000, DownCfg.Unconscious.seconds * 1000, 0, false, false, false)
  else
    setState('incapacitated', DownCfg.Incapacitated.bleedOutSeconds)
    RequestAnimDict('missfinale_c1@')
    while not HasAnimDictLoaded('missfinale_c1@') do Wait(10) end
    TaskPlayAnim(ped, 'missfinale_c1@', 'lying_dead_player0', 8.0, -8.0, -1, 1, 0, false, false, false)
  end
  -- NOTE: no SetPlayerControl(false) here any more. It switched off EVERY input, which is why
  -- chat (T), the wheel (G), F10 and even the self-splint E never registered while down. The
  -- per-frame thread below disables only what a downed body cannot do.
end

-- Death interception: never actually die; route into a down state
CreateThread(function()
  while true do
    Wait(100)
    local ped = PlayerPedId()
    if downState then
      -- keep the state body language + invulnerable-to-finishers window
      SetEntityHealth(ped, 120)
      SetPedCanRagdoll(ped, downState == 'unconscious')
      DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)
      if GetGameTimer() >= downUntil and not beingHelped then
        if downState == 'unconscious' then
          clearDown(DownCfg.Unconscious.wakeHealthPct)
          lib.notify({ title = 'You come to, head pounding.', type = 'inform' })
        else
          if downState == 'incapacitated' then
            TriggerServerEvent('outbreak:server:incapExpired', lastDamage.zombie and 'the dead' or (lastDamage.melee and 'beaten' or 'shot'))
            downUntil = GetGameTimer() + 30000 -- server answers within seconds; guard against double-fire
          else -- critical ran out
            TriggerServerEvent('outbreak:server:bledOut', 'never made it to a medic')
            downUntil = GetGameTimer() + 30000
          end
        end
      end
    elseif IsEntityDead(ped) or GetEntityHealth(ped) <= 101 then
      local pos = GetEntityCoords(ped)
      if IsEntityDead(ped) then
        NetworkResurrectLocalPlayer(pos.x, pos.y, pos.z, GetEntityHeading(ped), true, false)
        Wait(50); ped = PlayerPedId()
      end
      SetEntityHealth(ped, 120)
      local kind = (lastDamage.melee or lastDamage.zombie) and 'unconscious' or 'incapacitated'
      goDown(kind)
    end
  end
end)

-- DOWNED CONTROLS. While down: body inputs off, everything social on. Chat, the wheel, F10,
-- radio, OOC, inventory keys all stay live. Movement, combat, vehicles and the weapon wheel do not.
local BODY_CONTROLS = { 21, 22, 23, 24, 25, 30, 31, 32, 33, 34, 35, 36, 37, 44, 47, 58, 75, 140, 141, 142, 143, 257, 263, 264, 266, 267, 268, 269, 270, 271, 272, 273 }
local promptShown = nil
local function prompt(text)
  if promptShown == text then return end
  promptShown = text
  if text then lib.showTextUI(text, { position = 'bottom-center' }) else lib.hideTextUI() end
end
CreateThread(function()
  while true do
    if downState then
      Wait(0)
      for _, c in ipairs(BODY_CONTROLS) do DisableControlAction(0, c, true) end
      if downState == 'incapacitated' and DownCfg.Incapacitated.selfStabilize then
        prompt('[E] splint yourself   [G] options   [T] chat   [F6] distress')
        if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then -- E
          TriggerServerEvent('outbreak:server:trySelfStabilize')
        end
      else
        prompt('[G] options   [T] chat   [F6] distress')
      end
    else
      if promptShown then prompt(nil) end
      Wait(500)
    end
  end
end)

-- DISTRESS. Works from any state, down or not. Radio if you are tuned in; a scream if not.
local lastDistress = 0
RegisterCommand('ob_distress', function()
  if GetGameTimer() - lastDistress < 30000 then lib.notify({ title = 'You already called. Give it a minute.', type = 'inform' }) return end
  lastDistress = GetGameTimer()
  local pos = GetEntityCoords(PlayerPedId())
  local street = GetStreetNameFromHashKey(GetStreetNameAtCoord(pos.x, pos.y, pos.z))
  TriggerEvent('outbreak:noise:spike', 60)
  TriggerServerEvent('outbreak:server:distress', street, downState)
end, false)
local distressBlips = {}
RegisterNetEvent('outbreak:client:distressPing', function(name, pos, how, state)
  local b = AddBlipForCoord(pos.x, pos.y, pos.z)
  SetBlipSprite(b, 1); SetBlipColour(b, 1); SetBlipScale(b, 0.9); SetBlipFlashes(b, true)
  BeginTextCommandSetBlipName('STRING'); AddTextComponentString(('DISTRESS: %s'):format(name)); EndTextCommandSetBlipName(b)
  distressBlips[#distressBlips + 1] = b
  SetTimeout(5 * 60000, function() if DoesBlipExist(b) then RemoveBlip(b) end end)
  lib.notify({ title = how == 'radio' and ('MAYDAY — %s'):format(name) or ('A scream. %s.'):format(name),
    description = (state and (state .. ', ') or '') .. 'marked on your map for five minutes.', type = 'error', duration = 12000, position = 'top' })
end)

RegisterNetEvent('outbreak:client:adrenaline', function()
  if downState ~= 'incapacitated' then return end
  clearDown(DownCfg.Adrenaline.healthPct)
  lib.notify({ title = 'Your heart slams. You\'re up.', description = 'It won\'t last. Find a medic.', type = 'warning', duration = 8000 })
end)

RegisterNetEvent('outbreak:client:stationSaved', function(ok)
  if ok then
    clearDown(15)
    LocalPlayer.state:set('recovering', GetCloudTimeAsInt() + DownCfg.Critical.recoveringHours * 3600, true)
    lib.notify({ title = 'You come back slow.', description = ('Recovering for %d hours: no sprinting, half speed.'):format(DownCfg.Critical.recoveringHours), type = 'success', duration = 10000 })
  else
    downUntil = GetGameTimer() + math.floor((downUntil - GetGameTimer()) * DownCfg.Critical.failCutsTimerBy)
    SendNUIMessage({ action = 'down', state = 'critical', seconds = math.floor((downUntil - GetGameTimer()) / 1000) })
  end
end)

RegisterNetEvent('outbreak:client:adminRevive', function()
  clearDown(50)
  lib.notify({ title = 'An admin pulled you out.', type = 'inform' })
end)

RegisterNetEvent('outbreak:client:selfStabilizeOk', function()
  beingHelped = true
  if lib.progressCircle({ duration = DownCfg.Incapacitated.selfStabilizeSeconds * 1000,
      label = 'Splinting yourself...', useWhileDead = true, canCancel = true }) then
    clearDown(DownCfg.Incapacitated.stabilizeHealthPct)
    lib.notify({ title = 'You drag yourself back up.', type = 'success' })
  end
  beingHelped = false
end)

-- Being helped by another player
RegisterNetEvent('outbreak:client:revived', function(kind)
  clearDown(kind == 'shake' and DownCfg.Unconscious.wakeHealthPct or DownCfg.Incapacitated.stabilizeHealthPct)
  lib.notify({ title = kind == 'shake' and 'Someone shakes you awake.' or 'Someone patched you up.', type = 'success' })
end)

RegisterNetEvent('outbreak:client:respawn', function()
  local p = DownCfg.Respawn.points[math.random(#DownCfg.Respawn.points)]
  local ped = PlayerPedId()
  DoScreenFadeOut(1500); Wait(1600)
  clearDown(50)
  SetEntityCoords(ped, p.x, p.y, p.z); SetEntityHeading(ped, p.w)
  Wait(500); DoScreenFadeIn(2000)
  lib.notify({ title = 'You wake somewhere unfamiliar.', description = 'Someone dragged you here. Or something.', type = 'inform' })
end)

-- Permadeath screen
RegisterNetEvent('outbreak:client:thisIsHowYouDied', function(days)
  SetNuiFocus(false, false)
  DoScreenFadeOut(2000)
  Wait(2200)
  SendNUIMessage({ action = 'epitaph', days = days })
end)

-- Corpses: a marker + searchable remains where a survivor fell
local corpses = {}
RegisterNetEvent('outbreak:client:corpseSpawned', function(stashId, name, pos)
  RequestModel(DownCfg.CorpseProp); local t = GetGameTimer()
  while not HasModelLoaded(DownCfg.CorpseProp) and GetGameTimer() - t < 2000 do Wait(10) end
  local obj = CreateObject(DownCfg.CorpseProp, pos.x, pos.y, pos.z - 0.9, false, false, false)
  PlaceObjectOnGroundProperly(obj); FreezeEntityPosition(obj, true)
  corpses[stashId] = obj
  exports.ox_target:addLocalEntity(obj, { {
    label = 'Search the remains of ' .. name, icon = 'fa-solid fa-skull',
    onSelect = function() exports.ox_inventory:openInventory('stash', stashId) end } })
end)

-- Load existing corpses on join
CreateThread(function()
  Wait(5000)
  local rows = lib.callback.await('outbreak:corpses', false) or {}
  for _, r in ipairs(rows) do TriggerEvent('outbreak:client:corpseSpawned', r.stash_id, r.name, vec3(r.x, r.y, r.z)) end
end)

-- Memorial wall: /fallen
RegisterCommand('fallen', function()
  local rows = lib.callback.await('outbreak:memorial', false) or {}
  local opts = {}
  for _, r in ipairs(rows) do
    opts[#opts + 1] = { title = r.name, description = ('Survived %d days — %s'):format(r.days_survived, r.cause) }
  end
  if #opts == 0 then opts[1] = { title = 'No names yet.', description = 'Keep it that way.' } end
  lib.registerContext({ id = 'ob_memorial', title = 'THE FALLEN', options = opts })
  lib.showContext('ob_memorial')
end, false)

-- Helping downed players: target them
CreateThread(function()
  exports.ox_target:addGlobalPlayer({
    {
      label = 'Help them',
      icon = 'fa-solid fa-hand-holding-medical',
      canInteract = function(entity)
        local sid = NetworkGetPlayerIndexFromPed(entity)
        local st = Player(GetPlayerServerId(sid)).state.downState
        return st ~= nil
      end,
      onSelect = function(data)
        local target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
        local st = Player(target).state.downState
        local dur = st == 'unconscious' and DownCfg.Unconscious.shakeWakeSeconds or 12
        if lib.progressCircle({ duration = dur * 1000, label = st == 'unconscious' and 'Shaking them...' or 'Stabilizing...', canCancel = true }) then
          TriggerServerEvent('outbreak:server:helpPlayer', target, st)
        end
      end,
    },
    {
      label = 'Search their pockets',
      icon = 'fa-solid fa-hand',
      canInteract = function(entity)
        if not DownCfg.PvP then return false end
        local sid = NetworkGetPlayerIndexFromPed(entity)
        return Player(GetPlayerServerId(sid)).state.downState ~= nil
      end,
      onSelect = function(data)
        local target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
        if lib.progressCircle({ duration = 5000, label = 'Rifling pockets...', canCancel = true }) then
          TriggerServerEvent('outbreak:server:searchDowned', target)
        end
      end,
    },
  })
end)

AddEventHandler('outbreak:tick', function(t)
  local until_ = LocalPlayer.state.recovering
  if until_ and GetCloudTimeAsInt() < until_ then
    SetPedMoveRateOverride(t.ped, 0.6)
    -- recovering = no sprint. Was a DisableControlAction from this 500 ms tick, which disables
    -- the control for one frame in fifteen (a flicker, not a block). outbreak_needs owns the
    -- sprint cut now; ask it. CORE-MECHANICS.md #R1-2.
    pcall(function() exports.outbreak_needs:cutSprint('recovering') end)
  elseif until_ then LocalPlayer.state:set('recovering', nil, true) end
end)

-- Load / unload a carried body into a vehicle (rear seat)
RegisterNetEvent('outbreak:client:loadIntoVehicle', function(netId)
  local veh = NetworkGetEntityFromNetworkId(netId); if not DoesEntityExist(veh) then return end
  DetachEntity(PlayerPedId(), true, false)
  local seat = -1
  for s = 2, 0, -1 do if IsVehicleSeatFree(veh, s) then seat = s break end end
  if seat == -1 then return end
  TaskWarpPedIntoVehicle(PlayerPedId(), veh, seat)
end)
RegisterNetEvent('outbreak:client:unloadFromVehicle', function()
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) then TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16) end
  Wait(1200); if downState then goDown(downState) end
end)

-- Medical stations: blips + "treat critical patient" targets
CreateThread(function()
  for _, st in ipairs(DownCfg.Critical.Stations) do
    local b = AddBlipForCoord(st.pos.x, st.pos.y, st.pos.z); SetBlipSprite(b, 61); SetBlipColour(b, 2); SetBlipScale(b, 0.8)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(st.label); EndTextCommandSetBlipName(b)
    exports.ox_target:addSphereZone({ coords = st.pos, radius = st.radius, options = { {
      label = 'Treat a critical patient here', icon = 'fa-solid fa-kit-medical',
      onSelect = function()
        local mpos = GetEntityCoords(PlayerPedId()); local best, bd = nil, st.radius + 2.0
        for _, pid in ipairs(GetActivePlayers()) do
          if pid ~= PlayerId() then
            local sid = GetPlayerServerId(pid)
            if Player(sid).state.downState == 'critical' then
              local d = #(GetEntityCoords(GetPlayerPed(pid)) - mpos); if d < bd then best, bd = sid, d end end
          end
        end
        if not best then lib.notify({ title = 'No critical patient here.', type = 'error' }) return end
        if exports.outbreak_emotes:action('treat', 20000, 'Working on them...') then TriggerServerEvent('outbreak:server:stationTreat', best, st.id) end
      end } } })
  end
end)

exports('getDownState', function() return downState end)

-- Carry / drag execution (both sides react to server-set statebags)
AddStateBagChangeHandler('carrying', nil, function(bag, key, value)
  local sid = tonumber(bag:match('player:(%d+)')); if sid ~= GetPlayerServerId(PlayerId()) then return end
  if value then exports.outbreak_emotes:loopAction('carry') else exports.outbreak_emotes:stopAction() end
end)
AddStateBagChangeHandler('carriedBy', nil, function(bag, key, value)
  local sid = tonumber(bag:match('player:(%d+)')); if sid ~= GetPlayerServerId(PlayerId()) then return end
  local me = PlayerPedId()
  if value then
    local carrier = GetPlayerPed(GetPlayerFromServerId(value.by))
    if value.mode == 'carry' then
      AttachEntityToEntity(me, carrier, GetPedBoneIndex(carrier, 24818), 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
      exports.outbreak_emotes:loopAction('carried')
    else
      AttachEntityToEntity(me, carrier, GetPedBoneIndex(carrier, 6286), -0.3, -1.0, 0.0, 0.0, 0.0, 180.0, false, false, false, false, 2, false)
      exports.outbreak_emotes:loopAction('dragged')
    end
  else
    DetachEntity(me, true, false)
    if downState then goDown(downState) end
  end
end)
