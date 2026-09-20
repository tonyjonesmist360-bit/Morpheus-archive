-- outbreak_faction/client/faction.lua
local myJob = 'unemployed'

AddRelationshipGroup('OUTBREAK_RAIDERS')
local function applyRelations()
  local me = PlayerPedId()
  -- both factions hate the dead, and the dead hate them back; the two factions hate each other
  SetRelationshipBetweenGroups(5, `OUTBREAK_MIL`, `OUTBREAK_ZOMBIES`); SetRelationshipBetweenGroups(5, `OUTBREAK_ZOMBIES`, `OUTBREAK_MIL`)
  SetRelationshipBetweenGroups(5, `OUTBREAK_RAIDERS`, `OUTBREAK_ZOMBIES`); SetRelationshipBetweenGroups(5, `OUTBREAK_ZOMBIES`, `OUTBREAK_RAIDERS`)
  SetRelationshipBetweenGroups(5, `OUTBREAK_MIL`, `OUTBREAK_RAIDERS`); SetRelationshipBetweenGroups(5, `OUTBREAK_RAIDERS`, `OUTBREAK_MIL`)
  if myJob == 'military' then
    SetRelationshipBetweenGroups(0, `OUTBREAK_MIL`, `PLAYER`) -- soldiers treat you as one of their own
    SetRelationshipBetweenGroups(0, `PLAYER`, `OUTBREAK_MIL`)
    SetRelationshipBetweenGroups(5, `OUTBREAK_RAIDERS`, `PLAYER`)
    pcall(function() exports.outbreak_radio:learnChannel(FactionCfg.Military.radioChannel) end)
  elseif myJob == 'raider' then
    SetRelationshipBetweenGroups(5, `OUTBREAK_MIL`, `PLAYER`) -- shot on sight
    SetRelationshipBetweenGroups(0, `OUTBREAK_RAIDERS`, `PLAYER`); SetRelationshipBetweenGroups(0, `PLAYER`, `OUTBREAK_RAIDERS`)
    pcall(function() exports.outbreak_radio:learnChannel(FactionCfg.Raider.radioChannel) end)
  else
    SetRelationshipBetweenGroups(3, `OUTBREAK_MIL`, `PLAYER`)
    SetRelationshipBetweenGroups(3, `OUTBREAK_RAIDERS`, `PLAYER`)
  end
end

-- ── POSTS: recruiter + guards, spawned locally when you are near ──
local posts = {}   -- which -> { peds = {}, recruiter = ped }
local function loadModel(name) local m = joaat(name); RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 3000 do Wait(10) end return HasModelLoaded(m) and m or nil end
local function spawnPost(which)
  local P = FactionCfg.Posts[which]; if not P or posts[which] then return end
  local grp = joaat(P.group)
  local rm = loadModel(P.recruiter); local gm = loadModel(P.guard)
  if not rm or not gm then lib.notify({ title = ('Post model INVALID: %s / %s'):format(P.recruiter, P.guard), type = 'error' }) posts[which] = { peds = {} } return end
  local rec = { peds = {} }
  local r = CreatePed(4, rm, P.pos.x, P.pos.y, P.pos.z, P.pos.w, false, false)
  SetEntityAsMissionEntity(r, true, true); SetBlockingOfNonTemporaryEvents(r, true); SetPedRelationshipGroupHash(r, grp)
  SetPedCanRagdollFromPlayerImpact(r, false); SetEntityInvincible(r, true); FreezeEntityPosition(r, false)
  TaskStartScenarioInPlace(r, 'WORLD_HUMAN_GUARD_STAND', 0, true)
  rec.recruiter = r
  local opts
  if which == 'military' then
    opts = {
      { label = 'Enlist with the Remnant', icon = 'fa-solid fa-flag', canInteract = function() return myJob ~= 'military' end,
        onSelect = function() if lib.alertDialog({ header = 'Enlist', content = FactionCfg.Blurbs.military .. '\n\nJoin them? Leaving later costs standing.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:joinFaction', 'military') end end },
      { label = 'Walk out on the Remnant', icon = 'fa-solid fa-person-walking-arrow-right', canInteract = function() return myJob == 'military' end,
        onSelect = function() if lib.alertDialog({ header = 'Leave', content = 'Hand back the fatigues. Standing drops.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:leaveFaction') end end },
      { label = 'Armory', icon = 'fa-solid fa-box-open', canInteract = function() return myJob == 'military' end, onSelect = function() TriggerServerEvent('outbreak:server:openFactionStash', 'military') end },
      { label = 'Talk', icon = 'fa-solid fa-comment', onSelect = function() lib.notify({ title = 'Sergeant', description = myJob == 'military' and 'Gate is holding. Keep it that way.' or 'Channel 7 is ours. Earn it or move along.', type = 'inform', duration = 6000 }) end },
    }
  else
    opts = {
      { label = 'Join the Boneyard', icon = 'fa-solid fa-skull-crossbones', canInteract = function() return myJob ~= 'raider' end,
        onSelect = function() if lib.alertDialog({ header = 'Join the Boneyard', content = FactionCfg.Blurbs.raider .. '\n\nThe soldiers will shoot you on sight. Join?', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:joinFaction', 'raider') end end },
      { label = 'Leave the Boneyard', icon = 'fa-solid fa-person-walking-arrow-right', canInteract = function() return myJob == 'raider' end,
        onSelect = function() if lib.alertDialog({ header = 'Leave', content = 'They do not forget. Standing drops.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:leaveFaction') end end },
      { label = 'Raider cache', icon = 'fa-solid fa-skull', canInteract = function() return myJob == 'raider' end, onSelect = function() TriggerServerEvent('outbreak:server:openFactionStash', 'raider') end },
      { label = 'Talk', icon = 'fa-solid fa-comment', onSelect = function() lib.notify({ title = 'Warlord', description = myJob == 'raider' and 'Bring something back or do not come back.' or 'Thirteen is our channel. You are not on it.', type = 'inform', duration = 6000 }) end },
    }
  end
  exports.ox_target:addLocalEntity(r, opts)
  for _, off in ipairs(P.guards or {}) do
    local g = CreatePed(4, gm, P.pos.x + off[1], P.pos.y + off[2], P.pos.z, P.pos.w + math.random(-40, 40), false, false)
    SetEntityAsMissionEntity(g, true, true); SetBlockingOfNonTemporaryEvents(g, true); SetPedRelationshipGroupHash(g, grp)
    GiveWeaponToPed(g, joaat(P.weapon), 250, false, true); SetPedInfiniteAmmo(g, true, joaat(P.weapon)); SetPedAccuracy(g, 55)
    SetPedCombatAttributes(g, 46, true); SetPedCombatAttributes(g, 5, true); SetPedCombatAbility(g, 2); SetPedCombatRange(g, 2)
    SetPedSeeingRange(g, FactionCfg.GuardSight or 70.0); SetPedHearingRange(g, 60.0); SetPedFleeAttributes(g, 0, false)
    SetPedArmour(g, 100); SetEntityMaxHealth(g, 300); SetEntityHealth(g, 300)
    TaskStartScenarioInPlace(g, 'WORLD_HUMAN_GUARD_STAND_ARMY', 0, true)
    rec.peds[#rec.peds + 1] = g
  end
  posts[which] = rec
end
local function despawnPost(which)
  local rec = posts[which]; if not rec then return end
  if rec.recruiter and DoesEntityExist(rec.recruiter) then DeleteEntity(rec.recruiter) end
  for _, g in ipairs(rec.peds) do if DoesEntityExist(g) then DeleteEntity(g) end end
  posts[which] = nil
end
-- from the core tick, every 5 s: spawn near, remove far, and re-arm guards that fell idle
local lastPost = 0
AddEventHandler('outbreak:tick', function(t)
  if GetGameTimer() - lastPost < 5000 then return end
  lastPost = GetGameTimer()
  for which, P in pairs(FactionCfg.Posts or {}) do
    local d = #(t.pos - vector3(P.pos.x, P.pos.y, P.pos.z))
    if d < (FactionCfg.SpawnRadius or 180.0) and not posts[which] then spawnPost(which)
    elseif d > (FactionCfg.DespawnRadius or 260.0) and posts[which] then despawnPost(which)
    elseif posts[which] then
      for _, g in ipairs(posts[which].peds) do
        if DoesEntityExist(g) and not IsEntityDead(g) and not IsPedInCombat(g) then TaskCombatHatedTargetsAroundPed(g, FactionCfg.GuardSight or 70.0, 0) end
      end
    end
  end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then despawnPost('military'); despawnPost('raider') end end)

local function refreshJob()
  myJob = lib.callback.await('outbreak:faction:job', false) or 'unemployed'
  applyRelations()
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', refreshJob)
RegisterNetEvent('QBCore:Client:OnJobUpdate', refreshJob)

CreateThread(function()
  Wait(3000); refreshJob()
  local M, R = FactionCfg.Military, FactionCfg.Raider
  -- the armory stash also stays reachable at its own coordinates inside the base
  exports.ox_target:addSphereZone({ coords = M.Armory.coords, radius = 1.5, options = {
    { label = 'Armory', icon = 'fa-solid fa-box-open', onSelect = function() TriggerServerEvent('outbreak:server:openFactionStash', 'military') end },
    { label = 'Enlist with the Remnant', icon = 'fa-solid fa-flag', canInteract = function() return myJob ~= 'military' end,
      onSelect = function() if lib.alertDialog({ header = 'Enlist', content = FactionCfg.Blurbs.military .. '\n\nJoin them? Leaving later costs standing.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:joinFaction', 'military') end end },
    { label = 'Walk out on the Remnant', icon = 'fa-solid fa-person-walking-arrow-right', canInteract = function() return myJob == 'military' end,
      onSelect = function() if lib.alertDialog({ header = 'Leave', content = 'Hand back the fatigues. Standing drops.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:leaveFaction') end end },
    { label = 'Change into fatigues', icon = 'fa-solid fa-shirt', onSelect = function()
        local ok = pcall(function() exports['illenium-appearance']:setPlayerOutfit(M.Uniform.name) end)
        if not ok then lib.notify({ title = 'Outfit "' .. M.Uniform.name .. '" not saved yet — make it once in appearance.', type = 'inform' }) end
      end },
  }})
  exports.ox_target:addSphereZone({ coords = R.Camp.coords, radius = 1.5, options = {
    { label = 'Raider cache', icon = 'fa-solid fa-skull', onSelect = function() TriggerServerEvent('outbreak:server:openFactionStash', 'raider') end },
    { label = 'Join the Boneyard', icon = 'fa-solid fa-skull-crossbones', canInteract = function() return myJob ~= 'raider' end,
      onSelect = function() if lib.alertDialog({ header = 'Join the Boneyard', content = FactionCfg.Blurbs.raider .. '\n\nThe soldiers will shoot you on sight. Join?', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:joinFaction', 'raider') end end },
    { label = 'Leave the Boneyard', icon = 'fa-solid fa-person-walking-arrow-right', canInteract = function() return myJob == 'raider' end,
      onSelect = function() if lib.alertDialog({ header = 'Leave', content = 'They do not forget. Standing drops.', centered = true, cancel = true }) == 'confirm' then TriggerServerEvent('outbreak:server:leaveFaction') end end },
  }})
end)

exports('getJob', function() return myJob end)
exports('getStandings', function() return lib.callback.await('outbreak:faction:standings', false) or {} end)

RegisterNetEvent('outbreak:client:rep', function(faction, value, reason)
  lib.notify({ title = ('%s reputation: %d'):format(faction:gsub('^%l', string.upper), value), description = reason, type = value >= 0 and 'inform' or 'error', duration = 5000 })
end)
