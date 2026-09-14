-- outbreak_core/client/quietkill.lua — the quiet kill.
-- Conditions (all): stealth walk or crouched · a blade or blunt in hand · inside range · BEHIND
-- the zombie · its suspicion under 100 and not in combat. Then [E]: one animation, one body, no
-- noise. Bloaters are never quiet. Runners and brutes struggle: half damage, some noise, and it
-- turns on you. The engine's own takedown still exists on top of this; this one has rules.
local Q = OutbreakCfg.QuietKill
local candidate, busy, promptOn = nil, false, false

local function weaponOk(ped)
  local w = GetSelectedPedWeapon(ped)
  for _, name in ipairs(Q.Weapons) do if w == joaat(name) then return true end end
  return false
end
local function crouchedOrStealth(t)
  if t.stealth then return true end
  local ok, _, c = pcall(function() return exports.outbreak_emotes:getWalkStyle() end)
  return ok and c == true
end
local function isBehind(me, ped)
  local fwd = GetEntityForwardVector(ped)
  local toMe = GetEntityCoords(me) - GetEntityCoords(ped)
  local d = #toMe; if d < 0.01 then return false end
  toMe = toMe / d
  return (fwd.x * toMe.x + fwd.y * toMe.y) < Q.BehindDot
end

-- pick a candidate from the core tick (no loop of our own for the search)
AddEventHandler('outbreak:tick', function(t)
  if busy or t.down or t.veh ~= 0 then candidate = nil return end
  if not crouchedOrStealth(t) or not weaponOk(t.ped) then candidate = nil return end
  local ped, d = exports.outbreak_core:nearestZombie(Q.Range)
  if not ped or not d or d > Q.Range then candidate = nil return end
  if IsPedInCombat(ped, t.ped) or (exports.outbreak_core:suspicionOf(ped) or 0) >= 100 then candidate = nil return end
  if not isBehind(t.ped, ped) then candidate = nil return end
  candidate = ped
end)

local function loadAnim()
  for _, a in ipairs(Q.Anims) do
    RequestAnimDict(a.dict); local t0 = GetGameTimer()
    while not HasAnimDictLoaded(a.dict) and GetGameTimer() - t0 < 1500 do Wait(10) end
    if HasAnimDictLoaded(a.dict) then return a end
    if GlobalState.obDebug then print('[OB-QUIETKILL] anim dict INVALID: ' .. a.dict) end
  end
  return nil
end

local function doKill(ped)
  busy = true; candidate = nil
  if promptOn then lib.hideTextUI(); promptOn = false end
  local me = PlayerPedId()
  local variant = exports.outbreak_core:variantOf(ped) or 'shambler'
  if Q.Never[variant] then
    lib.notify({ title = 'Not that one.', description = 'It would burst all over you.', type = 'error', duration = 3000 })
    busy = false; return
  end
  local struggle = Q.Struggle[variant] == true
  -- line up: me directly behind, both facing its way
  local h = GetEntityHeading(ped)
  local back = GetOffsetFromEntityInWorldCoords(ped, 0.0, -Q.Standoff, 0.0)
  SetEntityCoordsNoOffset(me, back.x, back.y, GetEntityCoords(me).z, false, false, false)
  SetEntityHeading(me, h)
  ClearPedTasksImmediately(ped); FreezeEntityPosition(ped, true)
  local a = loadAnim()
  if a then
    TaskPlayAnim(me, a.dict, a.plyr, 8.0, -8.0, Q.Seconds * 1000, 0, 0.0, false, false, false)
    TaskPlayAnim(ped, a.dict, a.victim, 8.0, -8.0, Q.Seconds * 1000, 0, 0.0, false, false, false)
  else
    -- no takedown clip loaded: a plain stab still sells it and the rules still apply
    pcall(function() exports.outbreak_emotes:action('treat', Q.Seconds * 1000, struggle and 'It fights...' or 'Quiet...') end)
  end
  Wait(Q.Seconds * 1000)
  FreezeEntityPosition(ped, false)
  if DoesEntityExist(ped) and not IsEntityDead(ped) then
    if struggle then
      SetEntityHealth(ped, math.max(1, math.floor(GetEntityHealth(ped) * Q.StruggleHealthLeft)))
      TriggerEvent('outbreak:noise:spike', Q.StruggleNoise)
      TaskCombatPed(ped, me, 0, 16)
      lib.notify({ title = 'It twists out of your grip.', description = 'Hurt. Angry. On you.', type = 'error', duration = 4000 })
    else
      exports.outbreak_core:markQuietKill(ped)
      SetEntityHealth(ped, 0)
      SetPedToRagdoll(ped, 3000, 3000, 0, false, false, false)
      TriggerServerEvent('outbreak:server:xp', 'quiet_kill')
      lib.notify({ title = 'Quiet.', type = 'success', duration = 2000 })
    end
  end
  ClearPedTasks(me)
  busy = false
end

-- prompt + key, per frame only while there is a candidate
CreateThread(function()
  while true do
    if candidate and not busy then
      Wait(0)
      if not promptOn then lib.showTextUI('[E] quiet kill', { position = 'right-center' }); promptOn = true end
      if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
        local ped = candidate
        if ped and DoesEntityExist(ped) and not IsEntityDead(ped) then doKill(ped) end
      end
    else
      if promptOn then lib.hideTextUI(); promptOn = false end
      Wait(200)
    end
  end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and promptOn then lib.hideTextUI() end end)
