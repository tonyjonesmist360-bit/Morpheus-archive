-- outbreak_supply/client/residents.lua — residents you can see. Bodies around any settlement's
-- door while you are near it, doing what their morale says, with a line to match. Cosmetic:
-- nothing here changes state. Driven from the core tick, throttled to 3 s; no loop of its own.
local R = SupplyCfg.Residents
local bodies = {}     -- house -> { peds = {}, residents = n, morale = m }
local lastAt = 0

local function band(m) return m >= 70 and 'steady' or m >= 45 and 'uneasy' or m >= 25 and 'fraying' or 'breaking' end
local function despawn(id)
  local b = bodies[id]; if not b then return end
  for _, p in ipairs(b.peds) do if DoesEntityExist(p) then DeleteEntity(p) end end
  bodies[id] = nil
end
local function spawn(id, s)
  local n = math.min(R.maxBodies, s.residents or 0)
  if n <= 0 then return end
  local b = { peds = {}, residents = s.residents, morale = s.morale }
  local set = (s.morale or 60) >= 45 and R.scenarios.good or R.scenarios.low
  local lines = R.lines[band(s.morale or 60)]
  for i = 1, n do
    local m = joaat(R.models[math.random(#R.models)])
    RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 2000 do Wait(10) end
    if HasModelLoaded(m) then
      local a = (i / n) * 6.283 + math.random() * 0.6
      local r = 3.0 + math.random() * 3.0
      local x, y = s.door.x + math.cos(a) * r, s.door.y + math.sin(a) * r
      local found, z = GetGroundZFor_3dCoord(x, y, s.door.z + 3.0, false)
      local ped = CreatePed(4, m, x, y, found and z or s.door.z, math.random(0, 359) + 0.0, false, true)
      SetEntityAsMissionEntity(ped, true, true)
      SetBlockingOfNonTemporaryEvents(ped, true)
      SetPedRelationshipGroupHash(ped, `OUTBREAK_MIL`)
      SetModelAsNoLongerNeeded(m)
      TaskStartScenarioInPlace(ped, set[math.random(#set)], 0, true)
      local name = (s.names or {})[i] or 'Resident'
      local line = lines[math.random(#lines)]
      exports.ox_target:addLocalEntity(ped, { { label = 'Talk to ' .. name, icon = 'fa-solid fa-comment', onSelect = function()
        lib.notify({ title = name, description = line, type = 'inform', duration = 8000 }) end } })
      b.peds[#b.peds + 1] = ped
    end
  end
  bodies[id] = b
end

AddEventHandler('outbreak:tick', function(t)
  local now = GetGameTimer()
  if now - lastAt < 3000 then return end
  lastAt = now
  local g = GlobalState.obSettlements or {}
  for id, s in pairs(g) do
    if s.door then
      local d = #(t.pos - s.door)
      local b = bodies[id]
      if d <= R.spawnAt and not b and (s.residents or 0) > 0 then spawn(id, s)
      elseif b and (d > R.despawnAt or b.residents ~= s.residents or math.abs((b.morale or 0) - (s.morale or 0)) >= 20) then
        despawn(id)
        if d <= R.spawnAt and (s.residents or 0) > 0 then spawn(id, s) end
      end
    end
  end
  for id in pairs(bodies) do if not g[id] then despawn(id) end end
end)

AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then for id in pairs(bodies) do despawn(id) end end end)
