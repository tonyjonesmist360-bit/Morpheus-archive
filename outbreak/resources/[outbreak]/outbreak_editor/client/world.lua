-- outbreak_editor/client/world.lua — what everyone sees: persistent NPCs, hidden map peds, interactions (ox_target),
-- zones (consumed by the spawner and loot), data-mission guidance. Reads GlobalState.obEditor; re-syncs on rev change.
EditorWorld = {}
local npcs = {}        -- id -> ped
local zonesReg = {}    -- interaction id -> ox_target zone id
local modelsReg = {}   -- model hash -> true (addModel registered)
local missionBlip, missionStep, missionId = nil, nil, nil
local function st() return GlobalState.obEditor or { npcs = {}, hidden = {}, interactions = {}, zones = {}, rev = 0 } end
local Groups = { friendly = `PLAYER`, neutral = `CIVMALE`, hostile = `OUTBREAK_HOSTILE`, military = `OUTBREAK_MIL`, raider = `OUTBREAK_RAIDERS`, yard = `OUTBREAK_YARD` }
local AnimDict = { search = { dict = 'anim@gangops@facility@servers@bodysearch@', clip = 'player_search', flag = 49 }, treat = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 }, repair = { dict = 'mini@repair', clip = 'fixing_a_ped', flag = 49 },
  read = { dict = 'missheistdockssetup1clipboard@base', clip = 'base', flag = 49 }, eat = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger', flag = 49 }, drink = { dict = 'mp_player_intdrink', clip = 'loop_bottle', flag = 49 },
  pulse = { dict = 'amb@medic@standing@kneel@base', clip = 'base', flag = 1 }, radio = { dict = 'random@arrests', clip = 'generic_radio_chatter', flag = 49 }, pry = { dict = 'missexile2', clip = 'swat_plant_bomb', flag = 49 }, siphon = { dict = 'amb@world_human_bum_wash@male@low@idle_a', clip = 'idle_a', flag = 49 }, barricade = { dict = 'amb@world_human_hammering@male@base', clip = 'base', flag = 49 } }

-- ── interactions: one ox_target option per record ──
local function runInteraction(inter)
  if (inter.hold or 0) > 0 then
    local a = AnimDict[inter.anim or '']
    local ok = lib.progressCircle({ duration = inter.hold, label = inter.label, position = 'bottom', useWhileDead = false, canCancel = true, disable = { move = true, car = true, combat = true }, anim = a })
    if not ok then return end
  end
  TriggerServerEvent('outbreak:editor:interact', inter.id)
end
local function optionFor(inter)
  return { name = 'ed_' .. inter.id, label = inter.label, icon = inter.icon ~= '' and inter.icon or 'fa-solid fa-hand', distance = 2.5, onSelect = function() runInteraction(inter) end }
end
local function clearInteractions()
  for id, z in pairs(zonesReg) do pcall(function() exports.ox_target:removeZone(z) end); zonesReg[id] = nil end
  for h in pairs(modelsReg) do pcall(function() exports.ox_target:removeModel(h) end); modelsReg[h] = nil end
  for id, ped in pairs(npcs) do if DoesEntityExist(ped) then pcall(function() exports.ox_target:removeLocalEntity(ped) end) end end
end
local function registerInteractions()
  local S = st()
  local byNpc, byModel = {}, {}
  for id, inter in pairs(S.interactions) do
    if inter.enabled ~= false then
      local t = inter.target
      if t.kind == 'npc' then byNpc[tonumber(t.id)] = byNpc[tonumber(t.id)] or {}; table.insert(byNpc[tonumber(t.id)], optionFor(inter))
      elseif t.kind == 'model' then local h = tonumber(t.model) or joaat(t.model); byModel[h] = byModel[h] or {}; table.insert(byModel[h], optionFor(inter))
      elseif t.kind == 'entity' or t.kind == 'point' or t.kind == 'zone' then
        local r = t.kind == 'zone' and (tonumber(t.radius) or 5.0) or 1.6
        local o = optionFor(inter); if t.kind == 'zone' then o.distance = r + 1.0 end
        zonesReg[id] = exports.ox_target:addSphereZone({ coords = vector3(tonumber(t.x) or 0, tonumber(t.y) or 0, (tonumber(t.z) or 0) + (t.kind == 'zone' and 0.0 or 0.5)), radius = r, debug = false, options = { o } })
      end
    end
  end
  for h, opts in pairs(byModel) do exports.ox_target:addModel(h, opts); modelsReg[h] = true end
  for id, ped in pairs(npcs) do
    if DoesEntityExist(ped) then
      local n = S.npcs[id] or S.npcs[tostring(id)]
      local opts = byNpc[id] or {}
      if n and n.name and n.name ~= '' then table.insert(opts, 1, { name = 'ed_name_' .. id, label = n.name, icon = 'fa-solid fa-user', distance = 3.0, onSelect = function() lib.notify({ title = n.name, description = n.look ~= '' and n.look or 'They look at you.', type = 'inform' }) end }) end
      if #opts > 0 then exports.ox_target:addLocalEntity(ped, opts) end
    end
  end
  EditorWorld.byNpc = byNpc
end

-- ── persistent NPCs: local peds near you (same pattern as faction posts), behaviour from the record ──
local function behave(ped, n)
  local b = n.behaviour or {}; local kind = b.kind or 'stand'
  SetBlockingOfNonTemporaryEvents(ped, true); SetPedFleeAttributes(ped, 0, false); SetPedCombatAttributes(ped, 46, true)
  SetPedRelationshipGroupHash(ped, Groups[n.stance or 'neutral'] or Groups.neutral)
  if b.weapon and b.weapon ~= '' then GiveWeaponToPed(ped, joaat(b.weapon), 250, false, true) end
  if n.stance == 'hostile' then SetPedAsEnemy(ped, true) end
  if kind == 'guard' then
    SetPedCombatAttributes(ped, 5, true); SetPedCombatAbility(ped, 2); SetPedAccuracy(ped, 55); SetPedSeeingRange(ped, 60.0)
    TaskStartScenarioInPlace(ped, b.scenario and EditorCfg.Scenarios[b.scenario] or 'WORLD_HUMAN_GUARD_STAND', 0, true)
    CreateThread(function()
      while DoesEntityExist(ped) and not IsEntityDead(ped) do
        Wait(2000)
        if not IsPedInCombat(ped, 0) then
          local z = nil; pcall(function() z = exports.outbreak_core:nearestZombie(45.0) end)
          if z then TaskCombatPed(ped, z, 0, 16) elseif #(GetEntityCoords(ped) - vector3(n.x, n.y, n.z)) > 6.0 then TaskGoStraightToCoord(ped, n.x, n.y, n.z, 1.0, -1, n.h, 0.5) end
        end
      end
    end)
  elseif kind == 'wander' then TaskWanderInArea(ped, n.x, n.y, n.z, tonumber(b.radius) or 15.0, 2.0, 4.0)
  elseif kind == 'patrol' and type(b.points) == 'table' and #b.points > 0 then
    CreateThread(function()
      local i = 0
      while DoesEntityExist(ped) and not IsEntityDead(ped) do
        i = (i % #b.points) + 1; local p = b.points[i]
        TaskGoStraightToCoord(ped, p.x, p.y, p.z, 1.0, -1, 0.0, 0.5)
        local t = 0
        while DoesEntityExist(ped) and #(GetEntityCoords(ped) - vector3(p.x, p.y, p.z)) > 1.5 and t < 60 do Wait(500); t = t + 1 end
        Wait(tonumber(b.pause) or 3000)
      end
    end)
  elseif kind == 'sleep' then TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_BUM_SLUMPED', 0, true)
  else TaskStartScenarioInPlace(ped, EditorCfg.Scenarios[b.scenario or 'stand'] or 'WORLD_HUMAN_STAND_IMPATIENT', 0, true) end
end
local function spawnNpc(n)
  local h = joaat(n.model); if not IsModelInCdimage(h) then return nil end
  lib.requestModel(h, 5000)
  local ped = CreatePed(4, h, n.x, n.y, n.z, n.h or 0.0, false, false)
  SetEntityAsMissionEntity(ped, true, true); SetPedCanRagdollFromPlayerImpact(ped, false); SetEntityInvincible(ped, n.data and n.data.invincible ~= false)
  if n.data and n.data.outfit then pcall(function() SetPedComponentVariation(ped, tonumber(n.data.outfit.comp) or 0, tonumber(n.data.outfit.draw) or 0, tonumber(n.data.outfit.tex) or 0, 0) end) end
  Entity(ped).state:set('obNpc', n.id, false)
  behave(ped, n)
  SetModelAsNoLongerNeeded(h)
  return ped
end
local function syncNpcs()
  local S = st(); local me = GetEntityCoords(PlayerPedId())
  for id, ped in pairs(npcs) do
    local n = S.npcs[id] or S.npcs[tostring(id)]
    if not n or not DoesEntityExist(ped) or #(me - vector3(n.x, n.y, n.z)) > EditorCfg.NpcDespawnRadius then
      if DoesEntityExist(ped) then pcall(function() exports.ox_target:removeLocalEntity(ped) end); DeleteEntity(ped) end
      npcs[id] = nil
    end
  end
  for k, n in pairs(S.npcs) do
    local id = tonumber(k)
    if not npcs[id] and #(me - vector3(n.x, n.y, n.z)) < EditorCfg.NpcSpawnRadius then
      local ped = spawnNpc(n); if ped then npcs[id] = ped
        local opts = (EditorWorld.byNpc or {})[id] or {}
        if n.name and n.name ~= '' then table.insert(opts, 1, { name = 'ed_name_' .. id, label = n.name, icon = 'fa-solid fa-user', distance = 3.0, onSelect = function() lib.notify({ title = n.name, description = n.look ~= '' and n.look or 'They look at you.', type = 'inform' }) end }) end
        if #opts > 0 then exports.ox_target:addLocalEntity(ped, opts) end
      end
    end
  end
end
-- ── hidden map peds: ambient peds of a suppressed model near a suppressed spot are removed ──
local function sweepHidden()
  local S = st(); if next(S.hidden) == nil then return end
  local me = GetEntityCoords(PlayerPedId())
  for _, ped in ipairs(GetGamePool('CPed')) do
    if not IsPedAPlayer(ped) and not Entity(ped).state.obNpc then
      local m = GetEntityModel(ped); local p = GetEntityCoords(ped)
      for _, hrec in pairs(S.hidden) do
        if hrec.model == m and #(p - vector3(hrec.x, hrec.y, hrec.z)) < 30.0 and #(me - p) < EditorCfg.HiddenSweepRadius then
          local isZ = false; pcall(function() isZ = exports.outbreak_core:variantOf(ped) ~= nil end)
          if not isZ then SetEntityAsMissionEntity(ped, true, true); DeleteEntity(ped) end
          break
        end
      end
    end
  end
end
-- ── zones: a multiplier for the spawner, a bias for loot. Both read here, by anyone. ──
local function zoneAt(pos, kind)
  local best, bd
  for _, zn in pairs(st().zones) do
    if not kind or zn.kind == kind then local d = #(pos - vector3(zn.x, zn.y, zn.z)); if d <= zn.radius and (not bd or d < bd) then best, bd = zn, d end end
  end
  return best
end
exports('zoneMult', function(pos) local zn = zoneAt(pos); if not zn then return nil end; local k = EditorCfg.ZoneKinds[zn.kind]; return k and k.mult or nil end)
exports('zoneAt', function(pos, kind) return zoneAt(pos, kind) end)
function EditorWorld.drawZones()
  local me = Editor.pos or GetEntityCoords(PlayerPedId())
  for id, zn in pairs(st().zones) do
    if #(me - vector3(zn.x, zn.y, zn.z)) < 250.0 then
      local col = ({ safe = { 125, 138, 92 }, infested = { 142, 47, 47 }, territory = { 95, 143, 163 }, loot = { 201, 143, 61 }, quarantine = { 180, 85, 45 } })[zn.kind] or { 216, 210, 192 }
      local a = (Editor.selected and Editor.selected.kind == 'zone' and Editor.selected.id == id) and 90 or 40
      DrawMarker(1, zn.x, zn.y, zn.z - 1.0, 0, 0, 0, 0, 0, 0, zn.radius * 2, zn.radius * 2, 2.5, col[1], col[2], col[3], a, false, false, 2, false, nil, nil, false)
    end
  end
end
function EditorWorld.drawLabels()
  local S = st(); local me = Editor.pos or GetEntityCoords(PlayerPedId())
  for id, n in pairs(S.npcs) do
    local p = vector3(n.x, n.y, n.z); if #(me - p) < 80.0 then
      local sel = Editor.selected and Editor.selected.kind == 'npc' and Editor.selected.id == tonumber(id)
      DrawMarker(0, p.x, p.y, p.z + 2.2, 0, 0, 0, 0, 0, 0, 0.3, 0.3, 0.3, sel and 180 or 216, sel and 85 or 210, sel and 45 or 192, 160, true, false, 2, false, nil, nil, false)
    end
  end
  for id, inter in pairs(S.interactions) do
    local t = inter.target
    if t.x then local p = vector3(tonumber(t.x), tonumber(t.y), tonumber(t.z)); if #(me - p) < 80.0 then
      local sel = Editor.selected and Editor.selected.kind == 'interaction' and Editor.selected.id == tonumber(id)
      DrawMarker(2, p.x, p.y, p.z + 1.2, 0, 0, 0, 0, 0, 0, 0.25, 0.25, 0.25, sel and 180 or 95, sel and 85 or 143, sel and 45 or 163, 170, true, false, 2, true, nil, nil, false)
    end end
  end
end
-- pick the editor object nearest the cursor (for select / move / delete)
function EditorWorld.pick(c, radius)
  local S = st(); local best, bd, bk = nil, radius or 2.0, nil
  for id, n in pairs(S.npcs) do local d = #(c - vector3(n.x, n.y, n.z)); if d < bd then best, bd, bk = n, d, 'npc' end end
  for id, inter in pairs(S.interactions) do local t = inter.target; if t.x then local d = #(c - vector3(tonumber(t.x), tonumber(t.y), tonumber(t.z))); if d < bd then best, bd, bk = inter, d, 'interaction' end end end
  for id, zn in pairs(S.zones) do local d = #(c - vector3(zn.x, zn.y, zn.z)); if d < math.max(bd, 3.0) then best, bd, bk = zn, d, 'zone' end end
  return best, bk
end

-- ── missions: goto blips + arrival / kill reports ──
RegisterNetEvent('outbreak:editor:missionStep', function(id, stage, step)
  if missionBlip then RemoveBlip(missionBlip); missionBlip = nil end
  missionId, missionStep = stage and id or nil, stage and step or nil
  if step and step.x and (step.type == 'goto' or step.type == 'deliver' or step.type == 'talk') then
    missionBlip = AddBlipForCoord(tonumber(step.x), tonumber(step.y), tonumber(step.z))
    SetBlipSprite(missionBlip, 1); SetBlipColour(missionBlip, 5); SetBlipScale(missionBlip, 0.9); SetBlipRoute(missionBlip, true)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(step.label or 'Objective'); EndTextCommandSetBlipName(missionBlip)
  end
end)
AddEventHandler('gameEventTriggered', function(name, args)
  if name ~= 'CEventNetworkEntityDamage' or not missionStep or missionStep.type ~= 'kill' then return end
  local victim, attacker = args[1], args[2]
  if attacker == PlayerPedId() and IsEntityDead(victim) then local z = false; pcall(function() z = exports.outbreak_core:variantOf(victim) ~= nil end); if z then TriggerServerEvent('outbreak:editor:clientReport', missionId, 'kill', {}) end end
end)

-- one slow loop, off the tick, for sync work
local lastRev = -1
CreateThread(function()
  while true do
    Wait(2000)
    local S = st()
    if S.rev ~= lastRev then lastRev = S.rev; clearInteractions(); registerInteractions() end
    syncNpcs(); sweepHidden()
    if missionStep and missionStep.type == 'goto' and missionStep.x then
      if #(GetEntityCoords(PlayerPedId()) - vector3(tonumber(missionStep.x), tonumber(missionStep.y), tonumber(missionStep.z))) <= (tonumber(missionStep.radius) or 8.0) then TriggerServerEvent('outbreak:editor:clientReport', missionId, 'arrived', {}) ; missionStep = nil end
    end
    if missionStep and (missionStep.type == 'collect' or missionStep.type == 'flag') then TriggerServerEvent('outbreak:editor:clientReport', missionId, 'check', {}) end
  end
end)
AddEventHandler('onResourceStop', function(r) if r ~= GetCurrentResourceName() then return end; clearInteractions(); for _, ped in pairs(npcs) do if DoesEntityExist(ped) then DeleteEntity(ped) end end; if missionBlip then RemoveBlip(missionBlip) end end)
exports('npcPed', function(id) return npcs[tonumber(id)] end)
