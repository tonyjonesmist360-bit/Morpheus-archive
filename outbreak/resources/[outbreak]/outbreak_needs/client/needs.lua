-- outbreak_needs/client/needs.lua
-- CLIENT = sensor + effector. SERVER = authoritative store. The client never
-- decides an outcome; it reports what the ped experienced and applies what the
-- server says the body feels like.
local state = { hunger = 100.0, thirst = 100.0, fatigue = 100.0, infected = false, infectedAt = nil, wounds = {} }
local tick = {}

RegisterNetEvent('outbreak:client:loadNeeds', function(saved)
  if saved then for k, v in pairs(saved) do state[k] = v end end
  state.wounds = state.wounds or {}
  TriggerEvent('outbreak:hud:update', state)
end)

-- server pushes the whole state after any change it made (consume, treat, wound accepted)
RegisterNetEvent('outbreak:client:needsState', function(s)
  state = s; state.wounds = state.wounds or {}
  TriggerEvent('outbreak:hud:update', state)
end)

AddEventHandler('outbreak:tick', function(t) tick = t end)

local function isBleeding()
  for _, w in pairs(state.wounds) do local d = NeedsCfg.WoundTypes[w.kind]; if d and (d.bleed or 0) > 0 and not w.treated then return true end end
  return false
end

-- ── sensors: hits → wound reports ──
AddEventHandler('gameEventTriggered', function(name, args)
  if name ~= 'CEventNetworkEntityDamage' then return end
  local victim, attacker, weapon = args[1], args[2], args[7]
  if victim ~= PlayerPedId() then return end
  local _, bone = GetPedLastDamageBone(victim)
  local part = NeedsCfg.BoneToPart[bone] or 'torso'
  local kind
  if attacker and GetPedRelationshipGroupHash(attacker) == `OUTBREAK_ZOMBIES` then
    kind = math.random() < 0.35 and 'bite' or 'scratch'
  else
    local group = GetWeapontypeGroup(weapon)
    if group == `GROUP_MELEE` then kind = 'laceration'
    elseif group == `GROUP_UNARMED` or weapon == `WEAPON_UNARMED` then kind = 'bruise' -- fists: a bruise; painkillers
    elseif weapon == `WEAPON_FALL` or weapon == `WEAPON_RAMMED_BY_CAR` or weapon == `WEAPON_RUN_OVER_BY_CAR` then
      kind = (part == 'left_leg' or part == 'right_leg') and 'fracture' or 'laceration'
    else kind = 'gunshot' end
  end
  if kind then TriggerServerEvent('outbreak:server:wound', part, kind) end
end)

RegisterNetEvent('outbreak:client:infected', function() TriggerServerEvent('outbreak:server:infect') end)

-- Survival damage: the server decides how much (starvation, bleeding, infection stage)
-- and this applies it, because SetEntityHealth does not exist server-side.
RegisterNetEvent('outbreak:client:survivalDamage', function(dmg)
  if type(dmg) ~= 'number' or dmg <= 0 then return end
  local ped = PlayerPedId()
  SetEntityHealth(ped, math.max(0, GetEntityHealth(ped) - dmg))
end)

-- ── survival tick: sensor reports decay factors; server applies ──
CreateThread(function()
  while true do
    Wait(NeedsCfg.TickSeconds * 1000)
    TriggerServerEvent('outbreak:server:needsTick', { sprinting = tick.sprinting == true })
  end
end)

-- ── effector: what the body feels like (runs off server-pushed state) ──
-- SPRINT CUT. One place decides whether you may sprint this tick: exhaustion, a crushing pack,
-- a torso wound you keep running on, or recovering after a station save. SetPlayerSprint is
-- re-asserted every tick (unverified whether it persists between calls; if a sprint still
-- slips through, that is the F9 CORE-MECHANICS sprint step and this is the line to look at).
local sprintReasons = {}
local function cutSprint(reason) sprintReasons[reason] = GetGameTimer() + 1500 end
exports('cutSprint', cutSprint)
local limping, swaying, sprintTicks = false, false, 0
AddEventHandler('outbreak:tick', function(t)
  local ped = t.ped
  -- fever
  if state.infected and state.infectedAt and (GetCloudTimeAsInt() - state.infectedAt) / 3600 >= 3 then
    SetPedMotionBlur(ped, true); ShakeGameplayCam('DRUNK_SHAKE', 0.2)
  end
  -- wounds: every untreated wound does something you can feel (NeedsCfg.Effects)
  local slow, limp, armHurt, torsoHurt = 1.0, false, false, false
  for part, w in pairs(state.wounds) do
    local def = NeedsCfg.WoundTypes[w.kind]
    if def and not w.treated then
      if def.slow then slow = math.min(slow, w.kind == 'fracture' and 0.6 or 0.85) end
      if w.kind == 'fracture' then limp = true end
      if part == 'left_arm' or part == 'right_arm' then armHurt = true end
      if part == 'torso' and (def.severity or 0) >= 2 then torsoHurt = true end
    end
  end
  if limp ~= limping then limping = limp; pcall(function() exports.outbreak_emotes:setInjured(limp) end) end
  local aiming = armHurt and IsPlayerFreeAiming(PlayerId())
  if aiming and not swaying then swaying = true; ShakeGameplayCam('HAND_SHAKE', NeedsCfg.Effects.armSway)
  elseif not aiming and swaying then swaying = false; StopGameplayCamShaking(true) end
  if torsoHurt and t.sprinting then
    sprintTicks = sprintTicks + 1
    if sprintTicks * 0.5 >= NeedsCfg.Effects.torsoSprintSeconds then cutSprint('torso'); sprintTicks = 0 end
  else sprintTicks = 0 end
  -- encumbrance
  local ok, weight, max = pcall(function() return exports.ox_inventory:GetPlayerWeight(), exports.ox_inventory:GetPlayerMaxWeight() end)
  if ok and weight and max and max > 0 then
    local pct = weight / max
    if pct > NeedsCfg.Encumbrance.crawlAt then slow = math.min(slow, 0.75); cutSprint('pack')
    elseif pct > NeedsCfg.Encumbrance.slowAt then slow = math.min(slow, 0.9) end
  end
  if state.fatigue < 25 then cutSprint('exhausted') end
  local now, cut = GetGameTimer(), false
  for r, until_ in pairs(sprintReasons) do if until_ > now then cut = true else sprintReasons[r] = nil end end
  SetPlayerSprint(PlayerId(), not cut)
  SetPedMoveRateOverride(ped, slow)
end)

-- BODY SCAN read-model: one entry per part for the HUD silhouette and the F1 panel.
local function scanPart(part)
  local w = state.wounds[part]
  if not w then return { state = 'healthy', text = NeedsCfg.ScanText.healthy } end
  local def = NeedsCfg.WoundTypes[w.kind] or {}
  local s = w.treated and 'treated' or def.state or 'bleeding'
  local fixes = {}
  for _, it in ipairs(def.treat or {}) do fixes[#fixes + 1] = NeedsCfg.ScanText.items[it] or it end
  return { state = s, kind = w.kind, label = def.label or w.kind, treat = def.treat or {}, dirty = w.dirty or false,
    text = (NeedsCfg.ScanText[s] or '') .. (w.dirty and ' Dirty: it will turn if you leave it.' or ''),
    fix = w.treated and 'Nothing more to do.' or ('Treat with: ' .. table.concat(fixes, ' or ')) }
end
exports('bodyScan', function()
  local out = { parts = {}, infected = state.infected or false, bleeding = isBleeding() }
  for _, p in ipairs(NeedsCfg.Parts) do out.parts[p] = scanPart(p) end
  return out
end)

-- SLEEP: black screen, the rest scenario, a clock. E, a zombie inside wakeRadius, or the timer wakes you.
local asleep = false
RegisterNetEvent('outbreak:client:sleep', function(houseId)
  if asleep or LocalPlayer.state.downState then return end
  local Sl = NeedsCfg.Sleep
  asleep = true
  TriggerServerEvent('outbreak:server:sleep', houseId, 'start')
  pcall(function() exports.outbreak_emotes:play('rest') end)
  DoScreenFadeOut(1500); Wait(1600)
  lib.showTextUI('Sleeping   [E] wake up', { position = 'bottom-center' })
  local started, reason = GetGameTimer(), 'rested'
  while asleep do
    Wait(250)
    local left = Sl.seconds - (GetGameTimer() - started) / 1000
    if left <= 0 then break end
    if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then reason = 'woke'; break end
    if LocalPlayer.state.downState then reason = 'hurt'; break end
    if Sl.wakeOnZombies then
      local ok, t = pcall(function() return exports.outbreak_core:getTick() end)
      if ok and t and t.nearestDist and t.nearestDist < Sl.wakeRadius then reason = 'noise'; break end
    end
    if GetEntityHealth(PlayerPedId()) < 120 then reason = 'hurt'; break end
  end
  asleep = false
  lib.hideTextUI()
  TriggerServerEvent('outbreak:server:sleep', houseId, 'stop')
  pcall(function() exports.outbreak_emotes:stop() end)
  DoScreenFadeIn(1500)
  lib.notify({ title = reason == 'rested' and 'You slept.' or reason == 'noise' and 'Something is outside.' or reason == 'hurt' and 'You wake in pain.' or 'You get up.',
    description = reason == 'rested' and 'Rested. Hungrier. Thirstier.' or reason == 'noise' and 'Close. Too close.' or nil, type = reason == 'rested' and 'success' or 'warning', duration = 6000 })
end)
exports('isAsleep', function() return asleep end)

exports('getNeeds', function() return state end)
exports('isBleeding', isBleeding)
exports('getWounds', function() return state.wounds end)
