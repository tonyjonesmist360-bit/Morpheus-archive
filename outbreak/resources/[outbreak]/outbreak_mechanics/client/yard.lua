-- outbreak_mechanics/client/yard.lua — the Foreman and two hands at Beeker's. Same post pattern as outbreak_faction.
local post = nil
AddRelationshipGroup('OUTBREAK_YARD')
SetRelationshipBetweenGroups(5, `OUTBREAK_YARD`, `OUTBREAK_ZOMBIES`); SetRelationshipBetweenGroups(5, `OUTBREAK_ZOMBIES`, `OUTBREAK_YARD`)
SetRelationshipBetweenGroups(3, `OUTBREAK_YARD`, `PLAYER`); SetRelationshipBetweenGroups(3, `PLAYER`, `OUTBREAK_YARD`)
local function loadModel(name) local m = joaat(name); RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 3000 do Wait(10) end return HasModelLoaded(m) and m or nil end
local function spawn()
  local Y = MechCfg.Yard
  local fm = loadModel(Y.foremanModel)
  post = { peds = {} }
  if not fm then lib.notify({ title = 'Foreman model INVALID: ' .. Y.foremanModel, type = 'error' }) return end
  local f = CreatePed(4, fm, Y.foreman.x, Y.foreman.y, Y.foreman.z, Y.foreman.w, false, false)
  SetEntityAsMissionEntity(f, true, true); SetBlockingOfNonTemporaryEvents(f, true); SetPedRelationshipGroupHash(f, `OUTBREAK_YARD`); SetEntityInvincible(f, true)
  TaskStartScenarioInPlace(f, 'WORLD_HUMAN_CLIPBOARD', 0, true)
  post.foreman = f
  exports.ox_target:addLocalEntity(f, {
    { label = 'Take a delivery job', icon = 'fa-solid fa-truck-pickup', onSelect = function() TriggerServerEvent('outbreak:mech:take') end },
    { label = 'Repairs & mods', icon = 'fa-solid fa-wrench', onSelect = function() TriggerEvent('outbreak:mech:openMods') end },
    { label = 'Drop the job', icon = 'fa-solid fa-xmark', canInteract = function() return exports.outbreak_mechanics:hasJob() end, onSelect = function() TriggerServerEvent('outbreak:mech:abandon') end },
    { label = 'Talk', icon = 'fa-solid fa-comment', onSelect = function()
        local s = lib.callback.await('outbreak:mech:standing', false) or {}
        lib.notify({ title = 'Foreman', description = ('%s standing (%s). %s'):format(tostring(s.word), tostring(s.value), s.performance and 'Anything you want, no charge.' or s.repair and 'Repairs and paint. Earn the rest.' or 'Bring me a car and we will talk.'), type = 'inform', duration = 7000 }) end },
  })
  for _, h in ipairs(Y.hands or {}) do
    local m = loadModel(h.model)
    if m then
      local p = CreatePed(4, m, Y.pos.x + h.off[1], Y.pos.y + h.off[2], Y.pos.z, 0.0, false, false)
      SetEntityAsMissionEntity(p, true, true); SetBlockingOfNonTemporaryEvents(p, true); SetPedRelationshipGroupHash(p, `OUTBREAK_YARD`)
      GiveWeaponToPed(p, joaat(Y.handWeapon), 120, false, false); SetPedInfiniteAmmo(p, true, joaat(Y.handWeapon)); SetPedCombatAttributes(p, 46, true); SetPedSeeingRange(p, 50.0)
      TaskStartScenarioInPlace(p, 'WORLD_HUMAN_WELDING', 0, true)
      post.peds[#post.peds + 1] = p
    end
  end
end
local function despawn()
  if not post then return end
  if post.foreman and DoesEntityExist(post.foreman) then DeleteEntity(post.foreman) end
  for _, p in ipairs(post.peds) do if DoesEntityExist(p) then DeleteEntity(p) end end
  post = nil
end
local last = 0
AddEventHandler('outbreak:tick', function(t)
  if GetGameTimer() - last < 5000 then return end
  last = GetGameTimer()
  local d = #(t.pos - MechCfg.Yard.pos)
  if d < MechCfg.Yard.SpawnRadius and not post then spawn()
  elseif d > MechCfg.Yard.DespawnRadius and post then despawn()
  elseif post then for _, p in ipairs(post.peds) do if DoesEntityExist(p) and not IsEntityDead(p) and not IsPedInCombat(p) then TaskCombatHatedTargetsAroundPed(p, 50.0, 0) end end end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then despawn() end end)
