-- outbreak_core/client/zombies.lua
-- Replaces GTA ambient population with zombies around the player.
local zombies = {}
local spawnZombie -- forward-declared: exports above call it
local hotZone     -- forward-declared: exports above call it
local variantOf = {} -- ped -> variant name (declared up here: the exports below read it)
local suspicion = {}     -- ped -> 0..100
local topSuspicion = 0   -- highest in range this tick, for the HUD eye
local ZGROUP = `OUTBREAK_ZOMBIES`
local DEBUG = function() return GlobalState.obDebug == true end

-- ── TICK BUS: the ONE loop that samples the player. Everyone else subscribes. ──
-- Emits outbreak:tick every 500ms with a snapshot table. No other resource may
-- run its own "what is the player doing" loop.
local lastTick = {}
CreateThread(function()
  while true do
    Wait(500)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local veh = GetVehiclePedIsIn(ped, false)
    local nearest, nd, count = nil, math.huge, 0
    for z in pairs(zombies) do
      if DoesEntityExist(z) and not IsEntityDead(z) then
        local d = #(GetEntityCoords(z) - pos)
        if d < 60.0 then count = count + 1 end
        if d < nd then nd = d; nearest = z end
      end
    end
    lastTick = {
      ped = ped, pos = pos, veh = veh,
      speedKmh = (veh ~= 0 and GetEntitySpeed(veh) or GetEntitySpeed(ped)) * 3.6,
      engineOn = veh ~= 0 and GetIsVehicleEngineRunning(veh),
      sprinting = IsPedSprinting(ped), running = IsPedRunning(ped), walking = IsPedWalking(ped),
      stealth = GetPedStealthMovement(ped), shooting = IsPedShooting(ped), melee = IsPedInMeleeCombat(ped),
      moving = IsPedWalking(ped) or IsPedRunning(ped) or IsPedSprinting(ped) or IsPedJumping(ped),
      zombiesNear = count, nearestZombie = nearest, nearestDist = nd,
      down = LocalPlayer.state.downState,
    }
    TriggerEvent('outbreak:tick', lastTick)
  end
end)

exports('getTick', function() return lastTick end)
exports('getZombies', function() local t = {} for z in pairs(zombies) do if DoesEntityExist(z) then t[#t + 1] = z end end return t end)
exports('nearestZombie', function(radius)
  local pos = GetEntityCoords(PlayerPedId()); local best, bd = nil, radius or math.huge
  for z in pairs(zombies) do if DoesEntityExist(z) and not IsEntityDead(z) then local d = #(GetEntityCoords(z) - pos) if d < bd then best, bd = z, d end end end
  return best, bd
end)
-- Which mob area the player is standing in, or nil. Read by the HUD strip and the
-- status panel so 'this place is heavy' is legible before it is lethal.
exports('currentZone', function()
  local z = hotZone(GetEntityCoords(PlayerPedId()))
  local t = GlobalState.obTide
  return z and { id = z.id, mult = z.mult, bias = z.bias, tide = (t and t.zone == z.id) or false } or nil
end)
exports('countZombies', function(radius)
  local pos = GetEntityCoords(PlayerPedId()); local n = 0
  for z in pairs(zombies) do if DoesEntityExist(z) and not IsEntityDead(z) and #(GetEntityCoords(z) - pos) < (radius or 60.0) then n = n + 1 end end
  return n
end)
exports('spawnZombieAt', function(pos) return spawnZombie(pos, PlayerPedId()) end) -- debug/test
exports('getSuspicion', function() return topSuspicion end)
exports('suspicionOf', function(ped) return suspicion[ped] or 0 end)
exports('variantOf', function(ped) return variantOf[ped] end)
local quietKilled = {}
exports('markQuietKill', function(ped) quietKilled[ped] = true end)
-- Something made a noise over THERE: every zombie in radius that is not already fighting walks to it.
exports('lureTo', function(pos, radius)
  local n = 0
  for ped in pairs(zombies) do
    if DoesEntityExist(ped) and not IsEntityDead(ped) and #(GetEntityCoords(ped) - pos) <= (radius or 40.0) and not IsPedInCombat(ped, PlayerPedId()) then
      ClearPedTasks(ped)
      TaskGoStraightToCoord(ped, pos.x + math.random(-2, 2), pos.y + math.random(-2, 2), pos.z, 1.0, 20000, 0.0, 1.0)
      n = n + 1
    end
  end
  return n
end)

AddRelationshipGroup('OUTBREAK_ZOMBIES')
SetRelationshipBetweenGroups(5, ZGROUP, `PLAYER`)
SetRelationshipBetweenGroups(5, `PLAYER`, ZGROUP)

-- Kill normal city life + all police response
CreateThread(function()
  for i = 1, 15 do EnableDispatchService(i, false) end
  SetMaxWantedLevel(0)
  while true do
    SetPedDensityMultiplierThisFrame(0.0)
    SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
    SetVehicleDensityMultiplierThisFrame(0.05)
    SetRandomVehicleDensityMultiplierThisFrame(0.05)
    SetParkedVehicleDensityMultiplierThisFrame(0.4)
    SetWantedLevelMultiplier(0.0)
    Wait(0)
  end
end)

local function zombify(ped)
  SetEntityAsMissionEntity(ped, true, true)
  SetPedRelationshipGroupHash(ped, ZGROUP)
  RemoveAllPedWeapons(ped, true)
  SetPedDropsWeaponsWhenDead(ped, false)
  StopPedSpeaking(ped, true)
  DisablePedPainAudio(ped, true)
  SetPedFleeAttributes(ped, 0, false)
  SetPedCombatAttributes(ped, 46, true)  -- always fight
  SetPedCombatAttributes(ped, 5, true)   -- fight armed targets while unarmed
  SetPedCombatRange(ped, 2)
  SetPedSeeingRange(ped, OutbreakCfg.AggroRadius)
  SetPedHearingRange(ped, OutbreakCfg.HearGunshotRadius)
  SetPedConfigFlag(ped, 281, true)       -- no writhe; keeps coming
  SetPedAlertness(ped, 0)
  SetPedAccuracy(ped, 0)
  local style = OutbreakCfg.WalkStyles[math.random(#OutbreakCfg.WalkStyles)]
  RequestAnimSet(style)
  local t = GetGameTimer()
  while not HasAnimSetLoaded(style) and GetGameTimer() - t < 2000 do Wait(10) end
  SetPedMovementClipset(ped, style, 1.0)
  zombies[ped] = true
  TaskWanderStandard(ped, 10.0, 10)
end

local function isNight()
  local h = GetClockHours()
  return h >= 22 or h <= 5
end

local function findSpawnPos(ppos)
  local ang = math.random() * 2 * math.pi
  local dist = math.random(OutbreakCfg.SpawnRadius.min, OutbreakCfg.SpawnRadius.max)
  local x, y = ppos.x + math.cos(ang) * dist, ppos.y + math.sin(ang) * dist
  local found, z = GetGroundZFor_3dCoord(x, y, ppos.z + 50.0, false)
  if not found then return nil end
  return vector3(x, y, z)
end

-- variantOf declared near the top (forward)

-- MOB AREAS: the zone the player is standing in, or nil. Read by the spawner (density)
-- and by pickVariant (which variant this place tends to produce).
local zoneBias = nil
hotZone = function(pos)
  for _, z in ipairs(OutbreakCfg.HotZones or {}) do
    if #(pos - z.pos) < z.radius then return z end
  end
end

-- ZombieModels entries are 'model' or { model = '...', weight = n }. Weight defaults to 10.
local function pickModel(list)
  local total = 0
  for _, e in ipairs(list) do total = total + (type(e) == 'table' and (e.weight or 10) or 10) end
  local r = math.random() * total
  for _, e in ipairs(list) do
    local w = type(e) == 'table' and (e.weight or 10) or 10
    r = r - w
    if r <= 0 then return type(e) == 'table' and e.model or e end
  end
  local last = list[#list]
  return type(last) == 'table' and last.model or last
end

local function pickVariant()
  local night = isNight()
  -- A biased zone produces its signature variant most of the time, but never all of it.
  if zoneBias then
    local v = OutbreakCfg.Variants[zoneBias]
    if v and not (v.nightOnly and not night) and math.random() < 0.6 then return zoneBias, v end
  end
  local total, pool = 0, {}
  for name, v in pairs(OutbreakCfg.Variants) do
    if not (v.nightOnly and not night) then total = total + v.weight; pool[#pool + 1] = { name, v } end
  end
  local r = math.random() * total
  for _, e in ipairs(pool) do r = r - e[2].weight; if r <= 0 then return e[1], e[2] end end
  return 'shambler', OutbreakCfg.Variants.shambler
end

local function weatherMods()
  local w = GlobalState.obWeather
  local m = w and OutbreakCfg.Weather[w]
  return m or { noiseMult = 1.0, spawnMult = 1.0 }
end

spawnZombie = function(pos, combatTarget)
  local vname, v = pickVariant()
  local models = v.models or OutbreakCfg.ZombieModels
  local model = joaat(pickModel(models))
  RequestModel(model)
  local t = GetGameTimer()
  while not HasModelLoaded(model) and GetGameTimer() - t < 3000 do Wait(10) end
  if not HasModelLoaded(model) then return end
  local ped = CreatePed(4, model, pos.x, pos.y, pos.z, math.random(0, 359) + 0.0, false, true)
  zombify(ped)
  -- Blood and wounds are what actually sell "infected" on a human ped model. An unknown
  -- pack name is a silent no-op in GTA, so a wrong entry costs appearance, never stability.
  local packs = OutbreakCfg.DamagePacks
  if packs and #packs > 0 then
    pcall(function() ApplyPedDamagePack(ped, packs[math.random(#packs)], 0.0, 1.0) end)
  end
  variantOf[ped] = vname
  if v.moveRate then SetPedMoveRateOverride(ped, v.moveRate) end
  if v.health then SetEntityMaxHealth(ped, v.health); SetEntityHealth(ped, v.health) end
  if vname == 'runner' then SetPedMovementClipset(ped, 'move_m@hurry@a', 1.0) end
  SetModelAsNoLongerNeeded(model)
  if combatTarget then TaskCombatPed(ped, combatTarget, 0, 16) end
end

-- Bloaters burst on death; screamers call a mini-horde the first time they see you
local screamed = {}
local function onZombieDeath(ped)
  local v = variantOf[ped]
  if v == 'bloater' then
    local c = GetEntityCoords(ped)
    AddExplosion(c.x, c.y, c.z, 9, 0.6, true, false, 0.4) -- gas-canister pop, mostly noise + gas
    if #(GetEntityCoords(PlayerPedId()) - c) < 4.0 and math.random() < OutbreakCfg.Variants.bloater.burstInfect then
      TriggerEvent('outbreak:client:infected')
      lib.notify({ title = 'It bursts. You breathe it in.', type = 'error' })
    end
    TriggerEvent('outbreak:noise:spike', 60)
  end
  variantOf[ped] = nil
end
local function onZombieAggro(ped)
  if variantOf[ped] == 'screamer' and not screamed[ped] then
    screamed[ped] = true
    PlayPain(ped, 7, 0)
    lib.notify({ title = 'A SHRIEK splits the air.', description = 'They\'re coming to it.', type = 'error' })
    TriggerEvent('outbreak:noise:spike', 100)
    TriggerEvent('outbreak:client:horde', OutbreakCfg.Variants.screamer.callsHorde)
  end
end

-- Spawner loop
CreateThread(function()
  while true do
    Wait(2500)
    local target = OutbreakCfg.MaxPerPlayer
    if isNight() then target = math.floor(target * OutbreakCfg.NightMultiplier) end
    local ppos = GetEntityCoords(PlayerPedId())
    -- multiplayer density fix: players sharing an area split the quota
    local nearby = 1
    for _, pid in ipairs(GetActivePlayers()) do
      if pid ~= PlayerId() then
        local other = GetPlayerPed(pid)
        if DoesEntityExist(other) and #(GetEntityCoords(other) - ppos) < 150.0 then
          nearby = nearby + 1
        end
      end
    end
    target = math.ceil(target * weatherMods().spawnMult / nearby)
    local hz = hotZone(ppos)
    zoneBias = hz and hz.bias or nil
    if hz then target = math.max(0, math.ceil(target * hz.mult)) end
    do local t = GlobalState.obTide; if hz and t and t.zone == hz.id then target = math.ceil(target * (t.mult or 2.0)) end end   -- the Tide is here
    local count = 0
    for ped in pairs(zombies) do
      if not DoesEntityExist(ped) or IsEntityDead(ped) then
        if DoesEntityExist(ped) and variantOf[ped] then onZombieDeath(ped) end
        zombies[ped] = nil
      elseif #(GetEntityCoords(ped) - ppos) > OutbreakCfg.DespawnRadius then
        DeleteEntity(ped); zombies[ped] = nil
      else
        count = count + 1
      end
    end
    if count < target then
      local pos = findSpawnPos(ppos)
      if pos then spawnZombie(pos) end
    end
  end
end)

-- Aggro loop: sight OR sound. Your noise level stretches how far they sense you.
local function currentNoise()
  local ok, n = pcall(function() return exports['outbreak_noise']:getNoise() end)
  return ok and n or 20
end

local wasGhost = false
-- suspicion / topSuspicion declared near the top (forward)
local function currentVisibility()
  local ok, v = pcall(function() return exports.outbreak_noise:getVisibility() end)
  return ok and v or 50
end
CreateThread(function()
  while true do
    Wait(1500)
    local me = PlayerPedId()
    -- Director ghost (outbreak_dm): skip targeting entirely, and on the way in let go of
    -- anything already locked on, or the pack keeps chasing a player who is 'not here'.
    local isGhost = LocalPlayer.state.obGhost == true
    if isGhost ~= wasGhost then
      wasGhost = isGhost
      if isGhost then
        for ped in pairs(zombies) do
          if DoesEntityExist(ped) and not IsEntityDead(ped) then ClearPedTasks(ped); TaskWanderStandard(ped, 10.0, 10) end
        end
      end
    end
    local ppos = GetEntityCoords(me)
    local wm = weatherMods()
    local noise = currentNoise() * wm.noiseMult
    -- quiet (crouch) shrinks their senses to half; max noise triples them
    local senseMult = 0.5 + (noise / 100.0) * 2.5
    local frenzy = wm.frenzy and (GetGameTimer() % 90000) < 3000 -- thunder: a 3s agitation window every 90s
    local hearRadius = OutbreakCfg.AggroRadius * senseMult
    local vis = currentVisibility()
    local sightRadius = OutbreakCfg.AggroRadius * (vis / 50.0)
    local S = OutbreakCfg.Suspicion
    local top = 0
    for ped in pairs(zombies) do
      if DoesEntityExist(ped) and not IsEntityDead(ped) then
        local d = #(GetEntityCoords(ped) - ppos)
        local inCombat = IsPedInCombat(ped, me)
        local canSee = d < sightRadius and HasEntityClearLosToEntity(ped, me, 17)
        local hears = d < hearRadius and noise > 25
        if inCombat then suspicion[ped] = 100
        elseif canSee then
          local gain = S.gainPerTick * (vis / 50.0) * (d < sightRadius * 0.4 and S.closeBoost or 1.0)
          suspicion[ped] = math.min(100, (suspicion[ped] or 0) + gain)
          if suspicion[ped] < 100 and not IsPedInCombat(ped, me) then TaskTurnPedToFaceEntity(ped, me, 1200) end
        else
          suspicion[ped] = math.max(0, (suspicion[ped] or 0) - S.decayPerTick)
        end
        local sees = canSee and (suspicion[ped] >= 100 or d < S.instantRadius)
        if not isGhost and (sees or hears or (frenzy and d < 80.0)) then
          suspicion[ped] = 100
          TaskCombatPed(ped, me, 0, 16)
          onZombieAggro(ped)
        end
        if d < sightRadius * 1.5 and (suspicion[ped] or 0) > top then top = suspicion[ped] end
      else suspicion[ped] = nil end
    end
    topSuspicion = top
    TriggerEvent('outbreak:hud:sight', { visibility = vis, suspicion = top, sightRadius = sightRadius })
  end
end)

-- Headshot-only: a body-shot "kill" twitches... and gets back up
local function tryResurrect(ped)
  if not OutbreakCfg.HeadshotOnly then return end
  if quietKilled[ped] then quietKilled[ped] = nil return end   -- a knife in the neck stays down
  local _, bone = GetPedLastDamageBone(ped)
  if bone == 31086 then return end -- SKEL_Head: it stays down
  SetTimeout(math.random(1500, 4000), function()
    if not DoesEntityExist(ped) then return end
    ResurrectPed(ped)
    SetEntityHealth(ped, 120)
    ClearPedTasksImmediately(ped)
    TaskCombatPed(ped, PlayerPedId(), 0, 16)
  end)
end

-- Infection roll + bleed check when a zombie hits you
AddEventHandler('gameEventTriggered', function(name, args)
  if name ~= 'CEventNetworkEntityDamage' then return end
  local victim, attacker = args[1], args[2]
  if zombies[victim] and IsEntityDead(victim) then tryResurrect(victim) end
  if victim == PlayerPedId() and zombies[attacker] then
    local chance = OutbreakCfg.InfectionChancePerHit
    pcall(function() if exports.outbreak_skills:hasTrait('thick_skinned') then chance = chance * 0.75 end end)
    if math.random() < chance then
      TriggerEvent('outbreak:client:infected')
    end
  end
end)

-- Horde event from director
RegisterNetEvent('outbreak:event:horde', function(p) TriggerEvent('outbreak:client:horde', p and p.size or OutbreakCfg.Hordes.size) end)
AddEventHandler('outbreak:client:horde', function(size)
  local ppos = GetEntityCoords(PlayerPedId())
  lib.notify({ title = 'You hear moaning on the wind...', type = 'warning' })
  CreateThread(function()
    for i = 1, size do
      Wait(400)
      local pos = findSpawnPos(ppos)
      if pos then spawnZombie(pos, PlayerPedId()) end
    end
  end)
end)
