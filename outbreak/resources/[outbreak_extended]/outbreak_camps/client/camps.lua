-- outbreak_camps/client/camps.lua : loot-fortresses you have to fight for
local active = {}

local function garrison(c)
  active[c.id] = {}
  for i = 1, c.guards do
    local m = joaat(CampCfg.GuardModels[math.random(#CampCfg.GuardModels)])
    RequestModel(m); while not HasModelLoaded(m) do Wait(10) end
    local a = math.random() * 6.283
    local r = math.random() * (c.radius * 0.6)
    local x, y = c.pos.x + math.cos(a) * r, c.pos.y + math.sin(a) * r
    local found, z = GetGroundZFor_3dCoord(x, y, c.pos.z + 30.0, false)
    local ped = CreatePed(4, m, x, y, found and z or c.pos.z, math.random(0, 359) + 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, `OUTBREAK_MIL`) -- hated by zombies; we set player hostility below
    GiveWeaponToPed(ped, CampCfg.GuardWeapons[math.random(#CampCfg.GuardWeapons)], 60, false, true)
    SetPedCombatAttributes(ped, 46, true); SetPedAccuracy(ped, 35)
    SetPedSeeingRange(ped, 45.0)
    TaskGuardCurrentPosition(ped, 10.0, 10.0, true)
    active[c.id][#active[c.id] + 1] = ped
  end
end

local function aliveGuards(id)
  local n = 0
  for _, p in ipairs(active[id] or {}) do if DoesEntityExist(p) and not IsEntityDead(p) then n = n + 1 end end
  return n
end

CreateThread(function()
  for _, c in ipairs(CampCfg.Camps) do
    local blip = AddBlipForRadius(c.pos.x, c.pos.y, c.pos.z, c.radius)
    SetBlipColour(blip, 1); SetBlipAlpha(blip, 80)
    local b2 = AddBlipForCoord(c.pos.x, c.pos.y, c.pos.z); SetBlipSprite(b2, 84); SetBlipColour(b2, 1); SetBlipScale(b2, 0.7)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(c.label); EndTextCommandSetBlipName(b2)
    exports.ox_target:addSphereZone({ coords = c.pos, radius = 2.0, options = { {
      label = 'Crack the camp cache', icon = 'fa-solid fa-box-open',
      canInteract = function() return aliveGuards(c.id) == 0 end,
      onSelect = function()
        if exports.outbreak_minigames:play('pry', { pulls = 4, width = 14 }) then
          TriggerServerEvent('outbreak:server:campCleared', c.id)
        else TriggerEvent('outbreak:noise:spike', 65) end
      end } } })
  end
  while true do
    Wait(3000)
    local ppos = GetEntityCoords(PlayerPedId())
    for _, c in ipairs(CampCfg.Camps) do
      local d = #(ppos - c.pos)
      if d < 200.0 and not active[c.id] then
        local st = lib.callback.await('outbreak:campState', false, c.id)
        if st and st.garrisoned then garrison(c) else active[c.id] = {} end
      elseif d > 260.0 and active[c.id] then
        for _, p in ipairs(active[c.id]) do if DoesEntityExist(p) then DeleteEntity(p) end end
        active[c.id] = nil
      end
      -- camp guards are hostile to anyone inside the perimeter
      if active[c.id] and d < c.radius then
        for _, p in ipairs(active[c.id]) do
          if DoesEntityExist(p) and not IsEntityDead(p) and not IsPedInCombat(p, PlayerPedId()) then TaskCombatPed(p, PlayerPedId(), 0, 16) end
        end
      end
    end
  end
end)
