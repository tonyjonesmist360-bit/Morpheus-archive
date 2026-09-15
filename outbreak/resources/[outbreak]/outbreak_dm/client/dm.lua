-- outbreak_dm/client/dm.lua — the director's menu. Everything is a request; the server checks ace.
local function act(action, a) TriggerServerEvent('outbreak:dm:do', action, a or {}) end
-- searchable vehicle picker over DMCfg.Vehicles ({ model, label } pairs, or bare strings)
local function pickVehicle(cb)
  local o = {}
  for _, e in ipairs(DMCfg.Vehicles) do
    local m, l = e, e
    if type(e) == 'table' then m, l = e[1], (e[2] or e[1]) end
    o[#o + 1] = { value = m, label = l .. '  (' .. m .. ')' }
  end
  table.sort(o, function(a, b) return a.label < b.label end)
  local i = lib.inputDialog('Vehicle', { { type = 'select', label = 'Model', options = o, searchable = true, required = true } })
  if i and i[1] then cb(i[1]) end
end
local spawned = {}
local ghost = false

local function players(cb)
  local list = lib.callback.await('outbreak:dm:players', false) or {}
  local opts = {}
  for _, p in ipairs(list) do opts[#opts + 1] = { title = ('%s — %s%s'):format(p.name, p.char, p.down and (' [' .. p.down .. ']') or ''), onSelect = function() cb(p) end } end
  if #opts == 0 then opts[1] = { title = 'Nobody online.' } end
  lib.registerContext({ id = 'dm_players', title = 'Players', menu = 'dm_main', options = opts }); lib.showContext('dm_players')
end

local function menu()
  if not LocalPlayer.state.isDM then lib.notify({ title = 'Not a director.', type = 'error' }) return end
  local scenes = {}
  for id, sc in pairs(DMCfg.Scenes) do scenes[#scenes + 1] = { title = sc.label, description = #sc.steps .. ' steps, at your position', onSelect = function() TriggerServerEvent('outbreak:dm:scene', id) end } end
  table.sort(scenes, function(a, b) return a.title < b.title end)
  table.insert(scenes, { title = 'Schedule a scene…', icon = 'clock', onSelect = function()
    local ids = {}; for id, sc in pairs(DMCfg.Scenes) do ids[#ids + 1] = { value = id, label = sc.label } end
    local i = lib.inputDialog('Schedule', { { type = 'select', label = 'Scene', options = ids, required = true }, { type = 'number', label = 'In minutes', default = 10, min = 1 } })
    if i then TriggerServerEvent('outbreak:dm:schedule', i[2], 'scene', i[1]) end end })
  lib.registerContext({ id = 'dm_scenes', title = 'Scenes', menu = 'dm_main', options = scenes })

  lib.registerContext({ id = 'dm_spawn', title = 'Spawn', menu = 'dm_main', options = {
    { title = 'Horde on me', description = 'size 15', onSelect = function() local i = lib.inputDialog('Horde', { { type = 'number', label = 'Size', default = 15 } }); if i then act('horde', { size = i[1] }) end end },
    { title = 'Zombies here', onSelect = function() local i = lib.inputDialog('Zombies', { { type = 'number', label = 'Count', default = 5 }, { type = 'select', label = 'Variant', options = { { value = 'any', label = 'Mixed' }, { value = 'runner', label = 'Runners' }, { value = 'bloater', label = 'Bloaters' }, { value = 'screamer', label = 'Screamer' } }, default = 'any' } }); if i then act('zombies', { count = i[1], variant = i[2] }) end end },
    { title = 'Survivors (friendly, with a line)', onSelect = function() local i = lib.inputDialog('Survivors', { { type = 'number', label = 'Count', default = 2 }, { type = 'input', label = 'What they say', default = 'We don\'t want trouble.' } }); if i then act('peds', { kind = 'survivor', count = i[1], hostile = false, line = i[2] }) end end },
    { title = 'Raiders (hostile)', onSelect = function() local i = lib.inputDialog('Raiders', { { type = 'number', label = 'Count', default = 3 }, { type = 'select', label = 'Armed with', options = { { value = 'WEAPON_BAT', label = 'Bats' }, { value = 'WEAPON_PUMPSHOTGUN', label = 'Shotguns' }, { value = 'WEAPON_PISTOL', label = 'Pistols' } }, default = 'WEAPON_BAT' } }); if i then act('peds', { kind = 'raider', count = i[1], hostile = true, weapon = i[2] }) end end },
    { title = 'Military patrol', onSelect = function() act('peds', { kind = 'military', count = 3, hostile = false, weapon = 'WEAPON_CARBINERIFLE' }) end },
    { title = 'Vehicle', description = 'keys land in your pocket', onSelect = function() pickVehicle(function(m) act('vehicle', { model = m, offset = { 3, 3 } }) end) end },
    { title = 'Cache crate', onSelect = function() local i = lib.inputDialog('Cache', { { type = 'input', label = 'Label', default = 'Cache' }, { type = 'input', label = 'Items (name:count, comma)', default = 'mre:4,bandage:4,ammo-9:20' } })
        if i then local items = {}; for pair in i[2]:gmatch('[^,]+') do local n, c = pair:match('^%s*([%w%-_]+)%s*:%s*(%d+)'); if n then items[#items + 1] = { n, tonumber(c) } end end; act('cache', { label = i[1], items = items }) end end },
    { title = 'Clear my spawns', description = 'deletes NPCs/vehicles you spawned', onSelect = function() for _, e in ipairs(spawned) do if DoesEntityExist(e) then DeleteEntity(e) end end; spawned = {} end },
    { title = 'Clear scene here (40 m)', icon = 'broom', description = 'removes scene props and unclaimed vehicles around you; a backup file is written', onSelect = function()
        if lib.alertDialog({ header = 'Clear scene', content = 'Every scene prop and every unclaimed, empty vehicle within 40 m goes. Player-placed items and keyed cars stay. Backup is written.', centered = true, cancel = true }) == 'confirm' then act('sceneclear', { radius = 40.0 }) end end },
  } })

  lib.registerContext({ id = 'dm_story', title = 'Story', menu = 'dm_main', options = {
    { title = 'Radio transmission', onSelect = function() local i = lib.inputDialog('Transmit', { { type = 'number', label = 'Channel (0 = any)', default = 0 }, { type = 'input', label = 'Title', default = 'STATIC' }, { type = 'textarea', label = 'Text', required = true }, { type = 'number', label = 'Range from me (m, 0 = everywhere)', default = 0 } }); if i then act('radio', { ch = i[1], title = i[2], text = i[3], range = i[4] }) end end },
    { title = 'Plant a note', onSelect = function() local i = lib.inputDialog('Note', { { type = 'textarea', label = 'Text', required = true }, { type = 'input', label = 'Signed', default = 'someone' } }); if i then act('note', { text = i[1], by = i[2] }) end end },
    { title = 'Hand a document (intel) to a player', onSelect = function() players(function(p) local i = lib.inputDialog('Document', { { type = 'input', label = 'Intel id (see intel.lua)', required = true } }); if i then act('document', { target = p.id, intel = i[1] }) end end) end },
    { title = 'Opportunity control', onSelect = function() local i = lib.inputDialog('Opportunity', { { type = 'input', label = 'Id', required = true }, { type = 'select', label = 'Do', options = { { value = 'available', label = 'Make available' }, { value = 'start', label = 'Start' }, { value = 'expire', label = 'Expire' } }, required = true } }); if i then act('opp', { id = i[1], op = i[2] }) end end },
    { title = 'Camp stats', onSelect = function() local i = lib.inputDialog('Camp', { { type = 'input', label = 'Camp id', default = 'grapeseed' }, { type = 'number', label = 'defenses Δ', default = 0 }, { type = 'number', label = 'morale Δ', default = 0 }, { type = 'number', label = 'population Δ', default = 0 } }); if i then act('camp', { id = i[1], deltas = { defenses = i[2], morale = i[3], population = i[4] } }) end end },
    { title = 'Reputation', onSelect = function() players(function(p) local i = lib.inputDialog('Rep', { { type = 'input', label = 'Faction', default = 'civilian' }, { type = 'number', label = 'Δ', default = 10 } }); if i then act('rep', { target = p.id, faction = i[1], delta = i[2] }) end end) end },
    { title = 'Repeater on/off', onSelect = function() local i = lib.inputDialog('Repeater', { { type = 'input', label = 'Id', default = 'chiliad' }, { type = 'checkbox', label = 'Active', checked = true } }); if i then act('repeater', { id = i[1], active = i[2] }) end end },
    { title = 'World Director: run a pass now', description = 'Reads every settlement and nudges once - stranger, rumour, probe, unrest', onSelect = function() act('director', {}) end },
    { title = 'Settlement: DEFENSE EVENT now', description = 'warning, 4 min prep, wave at the door, consequences', onSelect = function() local i = lib.inputDialog('Defend', { { type = 'input', label = 'House id', default = 'sandy_bungalow', required = true } }); if i then act('defend', { house = i[1] }) end end },
    { title = 'Settlement: residents / morale', onSelect = function() local i = lib.inputDialog('Settlement', { { type = 'input', label = 'House id', default = 'sandy_bungalow', required = true }, { type = 'number', label = 'residents Δ', default = 1 }, { type = 'number', label = 'morale Δ', default = 0 } }); if i then act('settlement', { house = i[1], residents = i[2], morale = i[3] }) end end },
  } })

  lib.registerContext({ id = 'dm_world', title = 'World', menu = 'dm_main', options = {
    { title = 'Time', onSelect = function() local i = lib.inputDialog('Time', { { type = 'number', label = 'Hour', default = 22, min = 0, max = 23 } }); if i then act('time', { hour = i[1] }) end end },
    { title = 'Weather', onSelect = function() local o = {}; for _, w in ipairs(DMCfg.Weathers) do o[#o + 1] = { value = w, label = w } end; local i = lib.inputDialog('Weather', { { type = 'select', label = 'Type', options = o, required = true } }); if i then act('weather', { type = i[1] }) end end },
    { title = 'Give item to a player', onSelect = function() players(function(p) local i = lib.inputDialog('Give', { { type = 'input', label = 'Item', required = true }, { type = 'number', label = 'Count', default = 1 } }); if i then act('item', { target = p.id, name = i[1], count = i[2] }) end end) end },
    { title = 'Revive a player', onSelect = function() players(function(p) act('revive', { target = p.id }) end) end },
    { title = 'Teleport to a player', onSelect = function() players(function(p) act('tp', { target = p.id }) end) end },
    { title = 'Bring a player to me', onSelect = function() players(function(p) act('bring', { target = p.id }) end) end },
    { title = ghost and 'Ghost mode: ON (click to leave)' or 'Ghost mode (invisible, invulnerable)', onSelect = function() ghost = not ghost; act('ghost', { on = ghost }) end },
  } })

  -- ── ADMIN ──
  local god = LocalPlayer.state.obGod == true
  local locs = {}
  for _, l in ipairs(DMCfg.Locations or {}) do locs[#locs + 1] = { title = l.label, onSelect = function() act('tp', { pos = vector3(l.pos.x, l.pos.y, l.pos.z) }) end } end
  lib.registerContext({ id = 'dm_locs', title = 'Saved locations', menu = 'dm_admin', options = locs })
  lib.registerContext({ id = 'dm_zombies', title = 'Zombie controls', menu = 'dm_admin', options = {
    { title = 'Spawn one at cursor', onSelect = function() act('zcursor', { count = 1 }) end },
    { title = 'Spawn a horde at cursor (12)', onSelect = function() act('zcursor', { count = 12 }) end },
    { title = 'Clear area (60 m)', onSelect = function() act('zclear', { radius = 60.0 }) end },
    { title = 'Clear area (200 m)', onSelect = function() act('zclear', { radius = 200.0 }) end },
    { title = 'Freeze / release zombie AI', description = 'the ones loaded around you', onSelect = function() act('zfreeze', {}) end },
  } })
  lib.registerContext({ id = 'dm_vehkit', title = 'Vehicle kit', menu = 'dm_admin', description = 'Acts on the vehicle you sit in, or aim at', options = {
    { title = 'Spawn (search)', icon = 'car', description = 'searchable list, keys land in your pocket', onSelect = function() pickVehicle(function(m) act('vehicle', { model = m, offset = { 3, 3 } }) end) end },
    { title = 'Spawn by model name', description = 'any GTA model, e.g. kamacho', onSelect = function() local i = lib.inputDialog('Vehicle', { { type = 'input', label = 'Model name', required = true } }); if i then act('vehicle', { model = i[1]:lower(), offset = { 3, 3 } }) end end },
    { title = 'Give me the key', icon = 'key', description = 'and make it run: unlocked, battery, part, fuel', onSelect = function() act('vehkit', { op = 'keys' }) end },
    { title = 'Lock / unlock', onSelect = function() act('vehkit', { op = 'lock' }) end },
    { title = 'Repair', onSelect = function() act('vehkit', { op = 'repair' }) end },
    { title = 'Refuel', onSelect = function() act('vehkit', { op = 'refuel' }) end },
    { title = 'Delete', onSelect = function() act('vehkit', { op = 'delete' }) end },
    { title = ('World era: %s'):format(GlobalState.obVehEra or '?'), icon = 'clock', description = 'early = cars mostly run, keys in half of them. live = locked, dead, dry. Cars seen from now on roll the new table',
      onSelect = function() local i = lib.inputDialog('Vehicle era', { { type = 'select', label = 'Era', options = { { value = 'early', label = 'early - day one, most cars run' }, { value = 'live', label = 'live - months in, scavenge for parts' } }, default = GlobalState.obVehEra or 'early', required = true } }); if i then act('vehera', { era = i[1] }) end end },
  } })
  lib.registerContext({ id = 'dm_admin', title = 'Admin', menu = 'dm_main', options = {
    { title = 'Player panel', icon = 'users', description = 'health, needs, location; heal / feed / revive / freeze / tp / spectate', onSelect = function() TriggerEvent('outbreak:dm:openPanel') end },
    { title = 'Noclip / flight', icon = 'plane', description = '/noclip - WASD, Space, Ctrl, Shift', onSelect = function() ExecuteCommand('noclip') end },
    { title = god and 'God mode: ON (click to leave)' or 'God mode (visible, unkillable)', icon = 'shield', onSelect = function() act('god', { on = not god }) end },
    { title = ghost and 'Ghost mode: ON (click to leave)' or 'Ghost mode (invisible to all, ignored by NPCs and the dead)', icon = 'ghost', onSelect = function() ghost = not ghost; act('ghost', { on = ghost }) end },
    { title = 'Teleport to waypoint', icon = 'location-dot', onSelect = function() act('tpwaypoint', {}) end },
    { title = 'Saved locations', icon = 'map', menu = 'dm_locs' },
    { title = 'Copy my coordinates', icon = 'clipboard', description = '/coords', onSelect = function() ExecuteCommand('coords') end },
    { title = 'Entity gun', icon = 'crosshairs', description = '/entitygun - aim and click to delete objects, vehicles, peds', onSelect = function() ExecuteCommand('entitygun') end },
    { title = 'Zombie controls', icon = 'skull', menu = 'dm_zombies' },
    { title = 'Vehicle kit', icon = 'car', menu = 'dm_vehkit' },
    { title = 'Give item (search)', icon = 'gift', onSelect = function() players(function(p) act('givesearch', { target = p.id }) end) end },
    { title = 'Announce', icon = 'bullhorn', onSelect = function() local i = lib.inputDialog('Announce', { { type = 'textarea', label = 'Message', required = true } }); if i then act('announce', { text = i[1] }) end end },
    { title = 'Voice reset a player', icon = 'microphone', onSelect = function() players(function(p) act('voicereset', { target = p.id }) end) end },
  } })

  lib.registerContext({ id = 'dm_main', title = 'DIRECTOR', options = {
    { title = 'Admin', icon = 'user-shield', description = 'Players, noclip, god, ghost, teleport, entity gun, zombies, vehicles', menu = 'dm_admin' },
    { title = 'Scenes', icon = 'clapperboard', description = 'Authored presets at your position', menu = 'dm_scenes' },
    { title = 'Spawn', icon = 'skull', menu = 'dm_spawn' },
    { title = 'Story', icon = 'book', description = 'Radio, notes, intel, opportunities, camps, rep', menu = 'dm_story' },
    { title = 'World', icon = 'earth-americas', description = 'Time, weather, players, ghost', menu = 'dm_world' },
  } })
  lib.showContext('dm_main')
end

-- PLAYER PANEL: one row per player, one submenu per player
AddEventHandler('outbreak:dm:openPanel', function()
  local list = lib.callback.await('outbreak:dm:panel', false) or {}
  local rows = {}
  for _, p in ipairs(list) do
    local tags = {}
    if p.down then tags[#tags + 1] = p.down:upper() end
    if p.infected then tags[#tags + 1] = 'INFECTED' end
    if p.ghost then tags[#tags + 1] = 'ghost' end
    if p.god then tags[#tags + 1] = 'god' end
    local id = 'dm_p_' .. p.id
    lib.registerContext({ id = id, title = ('%s — %s'):format(p.name, p.char), menu = 'dm_panel', options = {
      { title = ('HP %d · Food %s · H2O %s · Rest %s'):format(p.health, tostring(p.hunger or '-'), tostring(p.thirst or '-'), tostring(p.fatigue or '-')), description = ('%.0f, %.0f, %.0f · radio ch %d · id %d'):format(p.pos.x, p.pos.y, p.pos.z, p.ch or 0, p.id), readOnly = true },
      { title = 'Heal (full reset: health, wounds, infection, needs)', icon = 'heart-pulse', onSelect = function() act('heal', { target = p.id }) end },
      { title = 'Feed (needs to 100)', icon = 'utensils', onSelect = function() act('feed', { target = p.id }) end },
      { title = 'Revive (out of any downed state)', icon = 'hand-holding-medical', onSelect = function() act('revive', { target = p.id }) end },
      { title = 'Freeze', icon = 'snowflake', onSelect = function() act('freeze', { target = p.id, on = true }) end },
      { title = 'Unfreeze', icon = 'sun', onSelect = function() act('freeze', { target = p.id, on = false }) end },
      { title = 'Teleport to them', icon = 'person-walking-arrow-right', onSelect = function() act('tp', { target = p.id }) end },
      { title = 'Bring them to me', icon = 'person-arrow-down-to-line', onSelect = function() act('bring', { target = p.id }) end },
      { title = 'Spectate', icon = 'eye', description = 'teleport near them first if they are far', onSelect = function() act('spectate', { target = p.id }) end },
      { title = 'Give item (search)', icon = 'gift', onSelect = function() act('givesearch', { target = p.id }) end },
      { title = 'Voice reset', icon = 'microphone', onSelect = function() act('voicereset', { target = p.id }) end },
    } })
    rows[#rows + 1] = { title = ('%s — %s'):format(p.name, p.char), description = ('HP %d · %s%s'):format(p.health, #tags > 0 and table.concat(tags, ' · ') or 'ok', ''), menu = id }
  end
  if #rows == 0 then rows[1] = { title = 'Nobody online.' } end
  lib.registerContext({ id = 'dm_panel', title = ('Players (%d)'):format(#list), menu = 'dm_main', options = rows })
  lib.showContext('dm_panel')
end)
RegisterCommand('dm', menu, false)

-- client-side executors (spawns happen on the director's client so they're near them; server logged the request)
RegisterNetEvent('outbreak:dm:spawnZombies', function(count, pos, variant)
  for i = 1, count do local z = exports.outbreak_core:spawnZombieAt(pos + vector3(math.random(-8, 8), math.random(-8, 8), 0)); if z then spawned[#spawned + 1] = z end; Wait(150) end
end)
RegisterNetEvent('outbreak:dm:spawnPeds', function(a, pos)
  local models = DMCfg.Peds[a.kind or 'survivor'] or DMCfg.Peds.survivor
  for i = 1, a.count or 1 do
    local m = joaat(models[math.random(#models)]); RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 2000 do Wait(10) end
    local ped = CreatePed(4, m, pos.x + math.random(-3, 3), pos.y + math.random(-3, 3), pos.z, math.random(0, 359) + 0.0, true, true)
    SetEntityAsMissionEntity(ped, true, true); spawned[#spawned + 1] = ped
    if a.weapon then GiveWeaponToPed(ped, joaat(a.weapon), 120, false, true) end
    if a.dead then SetEntityHealth(ped, 0) end
    if a.hostile then SetPedRelationshipGroupHash(ped, `OUTBREAK_MIL`); SetPedCombatAttributes(ped, 46, true); TaskCombatPed(ped, PlayerPedId(), 0, 16)
    else SetPedRelationshipGroupHash(ped, a.kind == 'military' and `OUTBREAK_MIL` or `OUTBREAK_MIL`); SetBlockingOfNonTemporaryEvents(ped, true); TaskStartScenarioInPlace(ped, a.kind == 'military' and 'WORLD_HUMAN_GUARD_STAND' or 'WORLD_HUMAN_STAND_IMPATIENT', 0, true) end
    if a.line then exports.ox_target:addLocalEntity(ped, { { label = 'Talk', icon = 'fa-solid fa-comment', onSelect = function() lib.notify({ title = 'Survivor', description = a.line, type = 'inform', duration = 9000 }) end } }) end
  end
end)
RegisterNetEvent('outbreak:dm:spawnVehicle', function(model, pos)
  local m = joaat(model); RequestModel(m); local t0 = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t0 < 5000 do Wait(10) end
  if not HasModelLoaded(m) then lib.notify({ title = 'Unknown vehicle model: ' .. tostring(model), type = 'error' }) return end
  local v = CreateVehicle(m, pos.x, pos.y, pos.z, GetEntityHeading(PlayerPedId()), true, true); spawned[#spawned + 1] = v
  local t1 = GetGameTimer(); while not NetworkGetEntityIsNetworked(v) and GetGameTimer() - t1 < 2000 do Wait(50) end
  if NetworkGetEntityIsNetworked(v) then act('vehkeys', { netId = NetworkGetNetworkIdFromEntity(v) }) end
end)
RegisterNetEvent('outbreak:dm:cache', function(id, label, pos, model)
  if #(GetEntityCoords(PlayerPedId()) - pos) > 300.0 then return end
  local m = joaat(model); RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 2000 do Wait(10) end
  local o = CreateObject(m, pos.x, pos.y, pos.z, false, false, false); PlaceObjectOnGroundProperly(o); FreezeEntityPosition(o, true)
  exports.ox_target:addLocalEntity(o, { { label = 'Open ' .. label, icon = 'fa-solid fa-box-open', onSelect = function() exports.ox_inventory:openInventory('stash', id) end } })
end)
RegisterNetEvent('outbreak:dm:tp', function(pos) DoScreenFadeOut(300); Wait(350); SetEntityCoords(PlayerPedId(), pos.x, pos.y, pos.z + 0.5); Wait(200); DoScreenFadeIn(300) end)
RegisterNetEvent('outbreak:dm:ghost', function(on)
  local ped = PlayerPedId()
  SetEntityVisible(ped, not on, false); SetEntityInvincible(ped, on); SetPlayerInvincible(PlayerId(), on)
  lib.notify({ title = on and 'Ghost: you are not here.' or 'Back in the world.', type = 'inform' })
end)
