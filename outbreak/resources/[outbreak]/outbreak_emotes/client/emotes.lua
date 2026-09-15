-- outbreak_emotes/client/emotes.lua
local current = nil
local restThread = false

local function stopEmote()
  local ped = PlayerPedId()
  ClearPedTasks(ped)
  current = nil
end

local function bearingOf(from, to)
  local dx, dy = to.x - from.x, to.y - from.y
  local deg = (math.deg(math.atan(dy, dx)) - 90) % 360
  local dirs = { 'north', 'north-west', 'west', 'south-west', 'south', 'south-east', 'east', 'north-east' }
  return dirs[math.floor(((deg + 22.5) % 360) / 45) + 1]
end

local function doListen()
  local me = GetEntityCoords(PlayerPedId())
  local n, nearest, nd = 0, nil, math.huge
  for _, p in ipairs(GetGamePool('CPed')) do
    if GetPedRelationshipGroupHash(p) == `OUTBREAK_ZOMBIES` and not IsEntityDead(p) then
      local d = #(GetEntityCoords(p) - me)
      if d < EmoteCfg.ListenRadius then n = n + 1; if d < nd then nd = d; nearest = p end end
    end
  end
  if n == 0 then lib.notify({ title = 'Quiet. Too quiet, or just quiet.', type = 'inform' })
  else lib.notify({ title = ('You hear %s... %s.'):format(n == 1 and 'one' or (n < 6 and 'a few' or (n < 15 and 'many' or 'a horde')), bearingOf(me, GetEntityCoords(nearest))), description = ('Closest about %dm out.'):format(math.floor(nd)), type = 'warning' }) end
end

local function playEmote(id)
  local e = EmoteCfg.Emotes[id]; if not e then return end
  if LocalPlayer.state.downState then return end
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) and id ~= 'handsup' then return end
  stopEmote()
  current = id
  if e.scenario then
    TaskStartScenarioInPlace(ped, e.scenario, 0, true)
  elseif e.anim then
    RequestAnimDict(e.anim[1]); local t = GetGameTimer()
    while not HasAnimDictLoaded(e.anim[1]) and GetGameTimer() - t < 2000 do Wait(10) end
    TaskPlayAnim(ped, e.anim[1], e.anim[2], 8.0, -8.0, e.once or -1, e.anim[3], 0, false, false, false)
  end
  if e.effect == 'whistle' then
    TriggerEvent('outbreak:noise:spike', 70)
    lib.notify({ title = 'You whistle, sharp and long.', description = 'Somewhere, something turns its head.', type = 'warning' })
    SetTimeout(e.once or 1500, function() if current == id then current = nil end end)
  elseif e.effect == 'listen' then
    SetTimeout(4000, function() if current == 'listen' then doListen() end end)
  elseif e.effect == 'noisy' then
    TriggerEvent('outbreak:noise:spike', 50)
  elseif e.effect == 'rest' and not restThread then
    restThread = true
    CreateThread(function()
      while current == 'rest' do
        Wait(5000)
        TriggerServerEvent('outbreak:server:rest')
      end
      restThread = false
    end)
  end
end

-- menu
local function openMenu()
  local opts = {}
  for id, e in pairs(EmoteCfg.Emotes) do
    opts[#opts + 1] = { title = e.label, description = e.desc, onSelect = function() playEmote(id) end }
  end
  table.sort(opts, function(a, b) return a.title < b.title end)
  table.insert(opts, 1, { title = 'Stop', icon = 'xmark', onSelect = stopEmote })
  table.insert(opts, 2, { title = 'Full emote library (scully)', icon = 'masks-theater', description = 'Hundreds more: props, dances, walks.',
    onSelect = function() ExecuteCommand('emotemenu') end })
  lib.registerContext({ id = 'ob_emotes', title = 'SURVIVAL EMOTES', options = opts })
  lib.showContext('ob_emotes')
end

RegisterCommand('semotes', openMenu, false)
RegisterCommand('e', function(_, args) if args[1] then playEmote(args[1]) end end, false)
RegisterCommand('stopemote', stopEmote, false)
for id in pairs(EmoteCfg.Emotes) do RegisterCommand(id, function() playEmote(id) end, false) end

-- moving cancels scenario emotes (via the core tick — no loop of our own)
AddEventHandler('outbreak:tick', function(t)
  if current and current ~= 'handsup' and current ~= 'whistle' and current ~= 'surrender' and current ~= 'carry' and current ~= 'drag' and t.moving then stopEmote() end
end)

-- ── WALK STYLE + CROUCH ──
local walkStyle, crouched, injured = nil, false, false
local function loadSet(name)
  RequestAnimSet(name); local t = GetGameTimer()
  while not HasAnimSetLoaded(name) and GetGameTimer() - t < 2000 do Wait(10) end
  return HasAnimSetLoaded(name)
end
local function applyWalk()
  local ped = PlayerPedId()
  if crouched then
    if loadSet(EmoteCfg.CrouchClipset) then SetPedMovementClipset(ped, EmoteCfg.CrouchClipset, 0.25) else lib.notify({ title = 'Crouch clipset INVALID: ' .. EmoteCfg.CrouchClipset, type = 'error' }) end
    return
  end
  if injured then  -- an untreated leg break: the limp wins over any chosen walk style
    local limp = EmoteCfg.InjuredClipset or 'move_m@injured'
    if loadSet(limp) then SetPedMovementClipset(ped, limp, 0.5) else ResetPedMovementClipset(ped, 0.25) end
    return
  end
  local set = walkStyle and EmoteCfg.WalkStyles[walkStyle] or nil
  if set then
    if loadSet(set) then SetPedMovementClipset(ped, set, 0.25) else lib.notify({ title = ('Walk style INVALID: %s (%s)'):format(walkStyle, set), description = 'Name from memory. Pick another.', type = 'error', duration = 6000 }); walkStyle = nil; ResetPedMovementClipset(ped, 0.25) end
  else ResetPedMovementClipset(ped, 0.25) end
end
RegisterCommand('walkstyle', function(_, a)
  local name = a[1]
  if not name then
    local opts = {}
    for k in pairs(EmoteCfg.WalkStyles) do opts[#opts + 1] = { title = k, description = EmoteCfg.WalkStyles[k] or 'default', onSelect = function() walkStyle = k ~= 'normal' and k or nil; applyWalk(); lib.notify({ title = 'Walk: ' .. k, type = 'inform', duration = 2000 }) end } end
    table.sort(opts, function(x, y) return x.title < y.title end)
    lib.registerContext({ id = 'ob_walk', title = 'Walk style', options = opts }); lib.showContext('ob_walk')
    return
  end
  if name == 'normal' or EmoteCfg.WalkStyles[name] then walkStyle = name ~= 'normal' and name or nil; applyWalk(); lib.notify({ title = 'Walk: ' .. name, type = 'inform', duration = 2000 })
  else lib.notify({ title = 'Unknown walk style.', description = 'Use /walkstyle with no name for the list.', type = 'error' }) end
end, false)
RegisterCommand('crouch', function()
  if LocalPlayer.state.downState then return end
  crouched = not crouched
  applyWalk()
  lib.notify({ title = crouched and 'Crouched.' or 'Standing.', description = crouched and 'Swinging stands you up for the hit.' or nil, type = 'inform', duration = 2000 })
end, false)
-- move_ped_crouched blocks melee entirely (GTA, not us). While crouched, an attack input drops
-- the clipset for the swing and puts it back after, so a crouched player can still fight.
CreateThread(function()
  local standingFor = 0
  while true do
    if crouched then
      Wait(0)
      local ped = PlayerPedId()
      if standingFor == 0 and (IsControlJustPressed(0, 140) or IsControlJustPressed(0, 141) or IsControlJustPressed(0, 142) or IsControlJustPressed(0, 24)) then
        ResetPedMovementClipset(ped, 0.05); standingFor = GetGameTimer() + 1500
      elseif standingFor > 0 and GetGameTimer() > standingFor and not IsPedInMeleeCombat(ped) then
        standingFor = 0; applyWalk()
      end
    else standingFor = 0; Wait(250) end
  end
end)
-- clipsets are per-ped; reapply after a model change / respawn
AddEventHandler('outbreak:client:respawn', function() SetTimeout(3000, applyWalk) end)
exports('getWalkStyle', function() return walkStyle, crouched end)
exports('setInjured', function(on) on = on and true or false; if on == injured then return end; injured = on; applyWalk() end)

exports('play', playEmote)
exports('stop', stopEmote)

-- ── ACTION service ──
-- exports.outbreak_emotes:action('treat', 6000, 'Bandaging...')  -> true if completed (uses ox_lib progress)
-- exports.outbreak_emotes:loopAction('carry') / stopAction()      -> looping anims (carry/drag/surrender)
local function loadDict(d) RequestAnimDict(d); local t = GetGameTimer(); while not HasAnimDictLoaded(d) and GetGameTimer() - t < 2000 do Wait(10) end return HasAnimDictLoaded(d) end

exports('action', function(name, ms, label)
  local a = EmoteCfg.Actions[name]
  if not a then return lib.progressCircle({ duration = ms, label = label or name, canCancel = true }) end
  return lib.progressCircle({ duration = ms, label = label or name, canCancel = true,
    disable = { move = true, car = true, combat = true }, anim = { dict = a.dict, clip = a.clip, flag = a.flag } })
end)

exports('loopAction', function(name)
  local a = EmoteCfg.Actions[name]; if not a then return end
  if loadDict(a.dict) then TaskPlayAnim(PlayerPedId(), a.dict, a.clip, 8.0, -8.0, -1, a.flag, 0, false, false, false) end
  current = name
end)
exports('stopAction', stopEmote)

-- server-triggered anim (eating/drinking after a useable)
RegisterNetEvent('outbreak:anim:play', function(name, ms)
  local a = EmoteCfg.Actions[name]; if not a then return end
  if loadDict(a.dict) then TaskPlayAnim(PlayerPedId(), a.dict, a.clip, 8.0, -8.0, ms or 3000, a.flag, 0, false, false, false) end
end)
