-- outbreak_debug/client/debug.lua
RegisterCommand('ob_zombie', function(_, a)
  if not GlobalState.obDebug then return end
  local n = tonumber(a[1]) or 1
  local pos = GetEntityCoords(PlayerPedId())
  for i = 1, n do exports.outbreak_core:spawnZombieAt(pos + vector3(math.random(-8, 8), math.random(-8, 8), 0)) end
end, false)
RegisterCommand('ob_wound', function(_, a)
  if not GlobalState.obDebug then return end
  TriggerServerEvent('outbreak:server:wound', a[1] or 'left_arm', a[2] or 'bite')
end, false)
RegisterCommand('ob_down', function(_, a)
  if not GlobalState.obDebug then return end
  SetEntityHealth(PlayerPedId(), 101) -- lets outbreak_down intercept
end, false)
RegisterCommand('ob_tp', function(_, a)
  if not GlobalState.obDebug then return end
  local spots = { sandy_bungalow = vec3(1893.45, 3768.72, 32.94), grove_house = vec3(-14.28, -1441.44, 31.10), motel = vec3(1961.24, 3742.4, 32.34) }
  local p = spots[a[1] or 'sandy_bungalow']; if p then SetEntityCoords(PlayerPedId(), p.x, p.y, p.z) end
end, false)
RegisterCommand('ob_debugmenu', function()
  if not GlobalState.obDebug then return end
  lib.registerContext({ id = 'ob_debug', title = 'OUTBREAK DEBUG', options = {
    { title = 'Give slice kit', onSelect = function() ExecuteCommand('ob_kit') end },
    { title = 'Give key: sandy_bungalow', onSelect = function() ExecuteCommand('ob_key sandy_bungalow') end },
    { title = 'Spawn 3 zombies', onSelect = function() ExecuteCommand('ob_zombie 3') end },
    { title = 'Horde (10)', onSelect = function() ExecuteCommand('ob_horde 10') end },
    { title = 'Wound: left arm bite', onSelect = function() ExecuteCommand('ob_wound left_arm bite') end },
    { title = 'Wound: right leg fracture', onSelect = function() ExecuteCommand('ob_wound right_leg fracture') end },
    { title = 'Go down (test downed)', onSelect = function() ExecuteCommand('ob_down') end },
    { title = 'Give adrenaline shot', onSelect = function() ExecuteCommand('ob_give adrenaline_shot 1') end },
    { title = 'Needs 20/20/20', onSelect = function() ExecuteCommand('ob_needs 20 20 20') end },
    { title = 'Night + thunder', onSelect = function() ExecuteCommand('ob_time 23'); ExecuteCommand('ob_weather THUNDER') end },
    { title = 'Test radio (ch 0)', onSelect = function() ExecuteCommand('ob_radio 0 hello survivor') end },
    { title = 'Persistence snapshot', onSelect = function() ExecuteCommand('ob_persist') end },
    { title = 'Teleport: bungalow', onSelect = function() ExecuteCommand('ob_tp sandy_bungalow') end },
  } })
  lib.showContext('ob_debug')
end, false)

-- ── "What am I looking at" — the model-name limitation killer ──
-- /ob_look        : prints model name (if in any of our catalogs) + hash + coords of the entity under your crosshair
-- /ob_scan [r]    : lists every object within r metres with hash, and the catalog name if we know it
-- /ob_walk        : while on, every object you aim at is printed once (walk a store, read the shelves)
local Known = {}
local function buildKnown()
  local function add(name) Known[joaat(name)] = name end
  for _, n in ipairs({ 'prop_paper_bag_small' }) do add(n) end
  local ok, cfg = pcall(function() return WorldItemsCfg end)
  if ok and cfg then for _, m in pairs(cfg.Models) do add(m) end end
  local ok2, l = pcall(function() return LootCfg end)
  -- hash-keyed tables: we can only echo the hash, but catalogs that stored names get resolved above
end
CreateThread(function() Wait(2000); buildKnown() end)

local function aimedEntity()
  local ped = PlayerPedId(); local cam = GetGameplayCamCoord(); local rot = GetGameplayCamRot(2)
  local dir = vector3(-math.sin(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.cos(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.sin(math.rad(rot.x)))
  local to = cam + dir * 12.0
  local ray = StartShapeTestRay(cam.x, cam.y, cam.z, to.x, to.y, to.z, 16 + 2 + 4 + 8, ped, 0)
  local _, hit, pos, _, ent = GetShapeTestResult(ray)
  return hit == 1 and ent or 0, pos
end
local function describe(ent)
  local model = GetEntityModel(ent); local c = GetEntityCoords(ent)
  local t = GetEntityType(ent); local kind = t == 1 and 'ped' or (t == 2 and 'vehicle' or 'object')
  -- GetEntityArchetypeName reads the model name off the entity itself, so every prop in
  -- a store resolves without a hand-maintained table. Known[] stays as the fallback.
  local name = GetEntityArchetypeName(ent)
  if not name or name == '' then name = Known[model] or (kind == 'vehicle' and GetDisplayNameFromVehicleModel(model)) or '?' end
  local shelf = false; pcall(function() shelf = WorldItemsCfg.Shelves[model] ~= nil end)
  local takeable = false; pcall(function() takeable = WorldItemsCfg.Takeables[model] ~= nil end)
  local loot = false; pcall(function() loot = LootCfg.Containers[model] ~= nil end)
  return ('%s | hash %d | name %s | %.2f, %.2f, %.2f | shelf=%s takeable=%s loot=%s worldItem=%s'):format(kind, model, name, c.x, c.y, c.z, tostring(shelf), tostring(takeable), tostring(loot), tostring(Entity(ent).state.worldItem ~= nil))
end
RegisterCommand('ob_look', function()
  if not GlobalState.obDebug then return end
  local ent = aimedEntity()
  if ent == 0 then lib.notify({ title = 'Nothing under the crosshair.', type = 'inform' }) return end
  local d = describe(ent); print('[OB-LOOK] ' .. d); lib.notify({ title = 'Look', description = d, type = 'inform', duration = 12000 })
end, false)
RegisterCommand('ob_scan', function(_, a)
  if not GlobalState.obDebug then return end
  local r = tonumber(a[1]) or 8.0; local me = GetEntityCoords(PlayerPedId()); local n = 0
  for _, o in ipairs(GetGamePool('CObject')) do
    if #(GetEntityCoords(o) - me) <= r then n = n + 1; print('[OB-SCAN] ' .. describe(o)) end
  end
  lib.notify({ title = ('Scanned %d objects within %dm — see F8'):format(n, r), type = 'inform' })
end, false)
local walking = false
RegisterCommand('ob_walk', function()
  if not GlobalState.obDebug then return end
  walking = not walking
  lib.notify({ title = walking and 'Walk mode: aim at things, they print once.' or 'Walk mode off.', type = 'inform' })
  if walking then CreateThread(function()
    local seen = {}
    while walking do Wait(200); local ent = aimedEntity(); if ent ~= 0 and not seen[ent] then seen[ent] = true; print('[OB-WALK] ' .. describe(ent)) end end
  end) end
end, false)
-- native/anim probe: /ob_anim dict clip -> tells you whether the dictionary loads (kills the "anim name from memory" class)
RegisterCommand('ob_anim', function(_, a)
  if not GlobalState.obDebug or not a[1] then return end
  RequestAnimDict(a[1]); local t = GetGameTimer(); while not HasAnimDictLoaded(a[1]) and GetGameTimer() - t < 3000 do Wait(10) end
  local ok = HasAnimDictLoaded(a[1])
  if ok and a[2] then TaskPlayAnim(PlayerPedId(), a[1], a[2], 8.0, -8.0, 3000, 1, 0, false, false, false) end
  lib.notify({ title = ok and ('Loaded: ' .. a[1]) or ('FAILED: ' .. a[1]), type = ok and 'success' or 'error' })
  print(('[OB-ANIM] %s -> %s'):format(a[1], ok and 'ok' or 'MISSING'))
end, false)
-- checks every action anim in the emotes catalog in one go
RegisterCommand('ob_animcheck', function()
  if not GlobalState.obDebug then return end
  local ok, cfg = pcall(function() return EmoteCfg end)
  if not ok or not cfg then lib.notify({ title = 'EmoteCfg not visible here (run it from outbreak_emotes context).', type = 'error' }) return end
  CreateThread(function()
    local bad = 0
    for name, a in pairs(cfg.Actions) do
      RequestAnimDict(a.dict); local t = GetGameTimer(); while not HasAnimDictLoaded(a.dict) and GetGameTimer() - t < 2000 do Wait(10) end
      if not HasAnimDictLoaded(a.dict) then bad = bad + 1; print(('[OB-ANIMCHECK] MISSING %s -> %s'):format(name, a.dict)) end
    end
    for name, e in pairs(cfg.Emotes) do if e.anim then RequestAnimDict(e.anim[1]); local t = GetGameTimer(); while not HasAnimDictLoaded(e.anim[1]) and GetGameTimer() - t < 2000 do Wait(10) end; if not HasAnimDictLoaded(e.anim[1]) then bad = bad + 1; print(('[OB-ANIMCHECK] MISSING emote %s -> %s'):format(name, e.anim[1])) end end end
    lib.notify({ title = ('Anim check done: %d missing (F8)'):format(bad), type = bad == 0 and 'success' or 'error' })
  end)
end, false)
-- model probe for a name list: /ob_models a,b,c
RegisterCommand('ob_models', function(_, a)
  if not GlobalState.obDebug or not a[1] then return end
  for name in a[1]:gmatch('[^,]+') do
    local h = joaat(name); local ok = IsModelInCdimage(h) and IsModelValid(h)
    print(('[OB-MODEL] %s -> %s'):format(name, ok and 'ok' or 'INVALID'))
  end
  lib.notify({ title = 'Model check printed to F8.', type = 'inform' })
end, false)
