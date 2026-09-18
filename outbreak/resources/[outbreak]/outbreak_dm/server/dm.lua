-- outbreak_dm/server/dm.lua — every action lands here, is ace-checked, and is logged.
local QBCore = exports['qb-core']:GetCoreObject()
local function dm(src) return src == 0 or IsPlayerAceAllowed(src, DMCfg.Ace) end
local function log(src, action, data)
  MySQL.insert('INSERT INTO outbreak_dm_log (actor, action, data, at) VALUES (?, ?, ?, NOW())', { src == 0 and 'console' or GetPlayerName(src), action, json.encode(data or {}) })
  pcall(function() exports.outbreak_log:log('dm.' .. action, src, data or {}) end)
  print(('^6[OB-DM]^7 %s: %s %s'):format(src == 0 and 'console' or GetPlayerName(src), action, json.encode(data or {})))
end
local function notify(src, t, ty) if src ~= 0 then TriggerClientEvent('ox_lib:notify', src, { title = t, type = ty or 'inform' }) end end
local function posOf(src, offset) local p = GetEntityCoords(GetPlayerPed(src)); return offset and (p + vector3(offset[1] or 0, offset[2] or 0, 0)) or p end

-- mark DMs on load so the client can show the menu entry
AddEventHandler('QBCore:Server:PlayerLoaded', function(player) local src = player.PlayerData.source; Player(src).state:set('isDM', dm(src), true) end)

local Actions = {}
Actions.horde = function(src, a) pcall(function() exports.outbreak_core:fireEvent('horde', a.target or src, { size = a.size or 15 }) end) end
Actions.zombies = function(src, a) TriggerClientEvent('outbreak:dm:spawnZombies', src, a.count or 5, posOf(src, a.offset), a.variant) end
Actions.peds = function(src, a) TriggerClientEvent('outbreak:dm:spawnPeds', src, a, posOf(src, a.offset)) end
Actions.vehicle = function(src, a)
  local p = posOf(src, a.offset)
  local ok, ent, netId = pcall(function() return exports.outbreak_vehicles:spawnManaged(a.model, p, GetEntityHeading(GetPlayerPed(src)), ('DM' .. math.random(1000, 9999)), a.state or { locked = false, battery = 'ok', fuel = 80, hotwired = true }) end)
  if ok and ent and ent ~= 0 then
    if netId and a.keys ~= false then pcall(function() exports.outbreak_vehicles:giveKeys(a.target or src, netId) end); notify(src, 'Spawned. The key is in your pocket.', 'success') end
  else TriggerClientEvent('outbreak:dm:spawnVehicle', src, a.model, p) end
end
-- keys + a running state for any networked vehicle (client-spawned fallback, or the one you aim at)
Actions.vehkeys = function(src, a)
  if not a.netId then return end
  pcall(function()
    local Veh = exports.outbreak_vehicles
    local v, plate = Veh:byNet(a.netId)
    if not v then TriggerEvent('outbreak:veh:register', a.netId); v, plate = Veh:byNet(a.netId) end
    if not plate then notify(src, 'No state for that vehicle yet. Drive it a moment and try again.', 'error') return end
    if a.fix ~= false then Veh:set(plate, { locked = false, battery = 'ok', hotwired = true, part = false, fuel = math.max(v.fuel or 0, 80) }, 'dm keys') end
    Veh:giveKeys(a.target or src, a.netId, plate)
    notify(a.target or src, 'Key · ' .. plate .. ' is in your pocket.', 'success')
  end)
end
-- SCENE CLEAR: undo a scene. Props (persisted) + unclaimed vehicles within radius of the DM.
-- Backup JSON lands in outbreak_worlditems/; ob_scene_restore <file> puts the props back.
Actions.sceneclear = function(src, a)
  local p = a.pos and vector3(a.pos.x, a.pos.y, a.pos.z) or posOf(src)
  local r = a.radius or 40.0
  local props, file, vehs = 0, nil, 0
  pcall(function() props, file = exports.outbreak_worlditems:clearSystemNear(p, r, a.notes == true) end)
  pcall(function() vehs = exports.outbreak_vehicles:clearNear(p, r) end)
  notify(src, ('Scene cleared: %d props, %d vehicles.'):format(props or 0, vehs or 0), 'success')
  if file then notify(src, 'Backup: ' .. file, 'inform') end
end
RegisterCommand('ob_scene_clear', function(src, args)
  if src ~= 0 and not dm(src) then return end
  local x, y, z, r = tonumber(args[1]), tonumber(args[2]), tonumber(args[3]), tonumber(args[4]) or 40.0
  if not (x and y and z) then print('usage: ob_scene_clear <x> <y> <z> [radius]   e.g. the Sandy 24/7: ob_scene_clear 1960.5 3740.6 32.3 45') return end
  local props, file, vehs = 0, nil, 0
  pcall(function() props, file = exports.outbreak_worlditems:clearSystemNear(vector3(x, y, z), r, false) end)
  pcall(function() vehs = exports.outbreak_vehicles:clearNear(vector3(x, y, z), r) end)
  print(('^6[OB-DM]^7 scene clear @ %.1f,%.1f r=%.0f: %d props (%s), %d vehicles'):format(x, y, r, props or 0, file or 'no backup needed', vehs or 0))
  log(src, 'sceneclear', { x = x, y = y, z = z, r = r, props = props, vehicles = vehs, backup = file })
end, true)
RegisterCommand('ob_scene_restore', function(src, args)
  if src ~= 0 and not dm(src) then return end
  if not args[1] then print('usage: ob_scene_restore cleared-YYYYMMDD-HHMMSS.json') return end
  local n = 0; pcall(function() n = exports.outbreak_worlditems:restoreCleared(args[1]) end)
  print(('^6[OB-DM]^7 restored %d props'):format(n or 0))
end, true)
Actions.vehera = function(src, a) pcall(function() if exports.outbreak_vehicles:setEra(a.era, GetPlayerName(src)) then notify(src, 'Vehicle era: ' .. a.era, 'success') end end) end
Actions.vehlock = function(src, a)
  pcall(function() local v, plate = exports.outbreak_vehicles:byNet(a.netId); if v then exports.outbreak_vehicles:set(plate, { locked = not v.locked }, 'dm lock'); notify(src, v.locked and 'Unlocked.' or 'Locked.') end end)
end
Actions.props = function(src, a) local p = posOf(src); for _, pr in ipairs(a.list or {}) do pcall(function() exports.outbreak_worlditems:placeSystem('__prop', 1, { model = pr[1] }, p + vector3(pr[2] or 0, pr[3] or 0, 0), vector3(0, 0, GetEntityHeading(GetPlayerPed(src))), 'the scene') end) end end
Actions.cache = function(src, a)
  local id = ('dmcache_%d'):format(os.time())
  exports.ox_inventory:RegisterStash(id, a.label or 'Cache', 15, 80000, nil)
  for _, it in ipairs(a.items or {}) do exports.ox_inventory:AddItem(id, it[1], it[2]) end
  TriggerClientEvent('outbreak:dm:cache', -1, id, a.label or 'Cache', posOf(src, a.offset), a.model or 'prop_mil_crate_01')
end
Actions.radio = function(src, a) pcall(function() exports.outbreak_radio:transmit(a.ch or 0, a.title or 'STATIC', a.text or '', nil, (a.range and a.range > 0) and posOf(src) or nil, a.range) end) end
Actions.weather = function(src, a) pcall(function() exports.outbreak_world:setWeather(a.type or 'CLEAR') end) end
Actions.time = function(src, a) pcall(function() exports.outbreak_world:setTime(a.hour or 12) end) end
Actions.item = function(src, a) exports.ox_inventory:AddItem(a.target or src, a.name, a.count or 1) end
Actions.note = function(src, a) pcall(function() exports.outbreak_worlditems:placeSystem('note', 1, { text = a.text }, posOf(src, a.offset or { 1, 0 }), vector3(0, 0, 0), a.by or 'someone') end) end
Actions.document = function(src, a) pcall(function() exports.outbreak_intel:giveDocument(a.target or src, a.intel) end) end
Actions.opp = function(src, a) pcall(function() local O = exports.outbreak_opportunities; if a.op == 'available' then O:makeAvailable(a.id) elseif a.op == 'start' then O:activate(a.id) elseif a.op == 'expire' then O:expire(a.id, { reason = 'dm' }) end end) end
Actions.camp = function(src, a) pcall(function() exports.outbreak_opportunities:modifyCamp(a.id, a.deltas or {}, 'dm') end) end
Actions.rep = function(src, a) pcall(function() exports.outbreak_faction:addRep(a.target or src, a.faction, a.delta or 10, 'dm') end) end
Actions.repeater = function(src, a) pcall(function() exports.outbreak_radio:setRepeater(a.id, a.active ~= false, 'dm') end) end
Actions.director = function(src, a) pcall(function() exports.outbreak_director:evaluate() end) end
Actions.defend = function(src, a) pcall(function() exports.outbreak_director:defend(a.house) end) end
Actions.settlement = function(src, a)
  pcall(function()
    if (a.residents or 0) > 0 then for _ = 1, a.residents do exports.outbreak_supply:addResident(a.house) end end
    if (a.residents or 0) < 0 or (a.morale or 0) ~= 0 then exports.outbreak_supply:modify(a.house, { residents = (a.residents or 0) < 0 and a.residents or nil, morale = a.morale or 0 }, 'The Director adjusted the settlement.') end
  end)
end
Actions.revive = function(src, a) TriggerClientEvent('outbreak:client:adminRevive', a.target or src) end
Actions.tp = function(src, a) if a.target then local p = GetEntityCoords(GetPlayerPed(a.target)); TriggerClientEvent('outbreak:dm:tp', src, p) elseif a.pos then TriggerClientEvent('outbreak:dm:tp', src, a.pos) end end
Actions.bring = function(src, a) if a.target then TriggerClientEvent('outbreak:dm:tp', a.target, posOf(src)) end end
Actions.ghost = function(src, a)
  local on = a.on and true or false
  -- outbreak_core does its own targeting, so GTA invisibility alone does not stop the
  -- horde. The statebag is what the aggro loop actually reads.
  Player(src).state:set('obGhost', on, true)
  TriggerClientEvent('outbreak:dm:ghost', src, on)
end
Actions.wait = function(src, a) Wait((a.seconds or 10) * 1000) end
-- ── admin console (2026-09-14) ──
Actions.god = function(src, a) local on = a.on and true or false; Player(src).state:set('obGod', on, true); TriggerClientEvent('outbreak:dm:god', src, on) end
-- TEST MODE (2026-09-18): one switch for testing. god (unkillable, needs paused, never downed) + ghost (invisible to
-- players and NPCs, ignored by the dead, still visible to yourself). Off puts everything back.
Actions.testmode = function(src, a)
  local on = a.on and true or false
  Player(src).state:set('obGod', on, true); Player(src).state:set('obGhost', on, true); Player(src).state:set('obTest', on, true)
  TriggerClientEvent('outbreak:dm:god', src, on); TriggerClientEvent('outbreak:dm:ghost', src, on)
  if on then pcall(function() exports.outbreak_needs:consume(src, { hunger = 100, thirst = 100, fatigue = 100 }) end) end
  TriggerClientEvent('outbreak:dm:testmode', src, on)
end
Actions.testkit = function(src, a)
  local t = a.target or src
  for _, it in ipairs(DMCfg.TestKit or {}) do exports.ox_inventory:AddItem(t, it[1], it[2]) end
  notify(t, 'Test kit in your pockets.', 'success')
end
RegisterCommand('testmode', function(src, a)
  if src == 0 or not dm(src) then return end
  local on = a[1] ~= 'off' and not (a[1] == nil and Player(src).state.obTest == true)
  Actions.testmode(src, { on = on }); log(src, 'testmode', { on = on })
end, false)
Actions.spectate = function(src, a) TriggerClientEvent('outbreak:dm:spectate', src, a.target) end
Actions.heal = function(src, a) local t = a.target or src; pcall(function() exports.outbreak_needs:reset(t) end); TriggerClientEvent('outbreak:dm:heal', t) end
Actions.feed = function(src, a) local t = a.target or src; pcall(function() exports.outbreak_needs:consume(t, { hunger = 100, thirst = 100, fatigue = 100 }) end); notify(t, 'An admin fed you.', 'success') end
Actions.freeze = function(src, a) if a.target then TriggerClientEvent('outbreak:dm:freeze', a.target, a.on and true or false) end end
Actions.entitydel = function(src, a)
  local e = a.netId and NetworkGetEntityFromNetworkId(a.netId)
  if e and e ~= 0 and DoesEntityExist(e) then DeleteEntity(e) end
end
Actions.vehfuel = function(src, a)
  pcall(function() local v, plate = exports.outbreak_vehicles:byNet(a.netId); if v then exports.outbreak_vehicles:set(plate or v.plate, { fuel = 100 }, 'dm') end end)
end
Actions.zcursor = function(src, a) TriggerClientEvent('outbreak:dm:zombieAtCursor', src, a.count or 1, a.variant) end
Actions.zclear = function(src, a) TriggerClientEvent('outbreak:dm:zombieClear', src, a.radius or 60.0) end
Actions.zfreeze = function(src, a) TriggerClientEvent('outbreak:dm:zombieFreeze', src) end
Actions.tpwaypoint = function(src, a) TriggerClientEvent('outbreak:dm:tpWaypoint', src) end
Actions.vehkit = function(src, a) TriggerClientEvent('outbreak:dm:vehicle', src, a.op) end
Actions.givesearch = function(src, a) TriggerClientEvent('outbreak:dm:giveSearch', src, a.target or src) end
Actions.announce = function(src, a) if a.text and a.text ~= '' then ExecuteCommand(('announce %s'):format(tostring(a.text):gsub('[\r\n]', ' '))) end end
Actions.voicereset = function(src, a) TriggerClientEvent('outbreak:client:voiceReset', a.target or src) end

-- ── ADMIN COMMAND SUITE (v0.23). One-word commands with a verb, ace outbreak.admin or console. ──
local function adminOk(src) return src == 0 or IsPlayerAceAllowed(src, 'outbreak.admin') or dm(src) end
local function say(src, t) if src == 0 then print(t) else TriggerClientEvent('chat:addMessage', src, { args = { 'ADMIN', t } }) end end
local function alog(src, kind, d) log(src, kind, d); pcall(function() exports.outbreak_log:log('admin.' .. kind, src, d) end) end
RegisterCommand('time', function(src, a)   -- /time set <hour>
  if not adminOk(src) then return end
  local h = tonumber(a[2] or a[1]); if not h then say(src, 'usage: /time set <0-23>') return end
  pcall(function() exports.outbreak_world:setTime(math.floor(h) % 24) end); say(src, ('time set to %02d:00'):format(math.floor(h) % 24)); alog(src, 'time', { hour = h })
end, true)
RegisterCommand('weather', function(src, a)   -- /weather set <TYPE>
  if not adminOk(src) then return end
  local w = (a[2] or a[1] or ''):upper(); if w == '' then say(src, 'usage: /weather set CLEAR|CLOUDS|OVERCAST|FOGGY|RAIN|THUNDER|CLEARING') return end
  pcall(function() exports.outbreak_world:setWeather(w) end); say(src, 'weather: ' .. w); alog(src, 'weather', { type = w })
end, true)
RegisterCommand('spawn', function(src, a)   -- /spawn mob <zombie|runner|bloater|screamer|horde|survivor|raider|military> [count]
  if not adminOk(src) or src == 0 then return end
  local kind, n = (a[2] or 'zombie'):lower(), tonumber(a[3]) or 5
  if a[1] ~= 'mob' then say(src, 'usage: /spawn mob <zombie|runner|bloater|screamer|horde|survivor|raider|military> [count]') return end
  if kind == 'horde' then Actions.horde(src, { size = n })
  elseif kind == 'zombie' then Actions.zombies(src, { count = n })
  elseif kind == 'runner' or kind == 'bloater' or kind == 'screamer' or kind == 'shambler' then Actions.zombies(src, { count = n, variant = kind })
  else Actions.peds(src, { kind = kind, count = n, hostile = kind == 'raider' }) end
  say(src, ('spawned %d %s'):format(n, kind)); alog(src, 'spawn', { kind = kind, count = n })
end, true)
RegisterCommand('trigger', function(src, a)   -- /trigger encounter <stranger|rumor_food|rumor_medicine|probe|unrest|trader|tide|director> [house]
  if not adminOk(src) then return end
  local what = a[2]; if a[1] ~= 'encounter' or not what then say(src, 'usage: /trigger encounter <stranger|rumor_food|rumor_medicine|probe|unrest|trader|tide|director> [house_id]') return end
  local ok, res = false, 'no director'
  if what == 'director' then ok = pcall(function() exports.outbreak_director:evaluate() end); res = 'pass ran'
  elseif what == 'tide' then ok = pcall(function() ExecuteCommand('ob_tide') end); res = 'tide moved'
  else pcall(function() ok, res = exports.outbreak_director:runAction(what, a[3]) end) end
  say(src, (ok and 'ok: ' or 'failed: ') .. tostring(res)); alog(src, 'trigger', { what = what, house = a[3], ok = ok })
end, true)
RegisterCommand('settle', function(src, a)   -- /settle morale <value> [house] | /settle residents <+n|-n> [house]
  if not adminOk(src) then return end
  local op, v = a[1], tonumber(a[2]); local house = a[3]
  if not op or not v then say(src, 'usage: /settle morale <0-100> [house_id]  |  /settle residents <+n|-n> [house_id]') return end
  if not house then pcall(function() for k in pairs(exports.outbreak_supply:settlements() or {}) do house = k break end end) end
  if not house then say(src, 'no settlement exists yet') return end
  if op == 'morale' then
    local cur = 50; pcall(function() cur = exports.outbreak_supply:getSettlement(house).morale end)
    pcall(function() exports.outbreak_supply:modify(house, { morale = v - cur }, 'admin set morale') end); say(src, ('%s morale -> %d'):format(house, v))
  elseif op == 'residents' then Actions.settlement(src, { house = house, residents = v }); say(src, ('%s residents %+d'):format(house, v)) end
  alog(src, 'settle', { op = op, value = v, house = house })
end, true)
RegisterCommand('loot', function(src, a)   -- /loot reset
  if not adminOk(src) then return end
  if a[1] ~= 'reset' then say(src, 'usage: /loot reset') return end
  local n = 0; pcall(function() n = exports.outbreak_items:resetLoot() end)
  say(src, ('loot reset: %d container(s) fresh again'):format(n or 0)); alog(src, 'lootreset', { cleared = n })
end, true)
RegisterCommand('hotfix', function(src, a)   -- /hotfix reload <resource>
  if not adminOk(src) then return end
  local r = a[2] or a[1]; if not r or not r:find('^outbreak_') then say(src, 'usage: /hotfix reload <outbreak_resource>') return end
  if GetResourceState(r) == 'missing' then say(src, 'no such resource: ' .. r) return end
  alog(src, 'hotfix', { resource = r })
  say(src, 'restarting ' .. r .. ' (players keep playing; that resource re-reads its files)')
  ExecuteCommand('restart ' .. r)
end, true)

-- player panel: everything an admin needs to see per player, in one row
lib.callback.register('outbreak:dm:panel', function(src)
  if not dm(src) then return {} end
  local out = {}
  for _, s in ipairs(GetPlayers()) do
    s = tonumber(s)
    local p = QBCore.Functions.GetPlayer(s)
    local ped = GetPlayerPed(s)
    local n = nil; pcall(function() n = exports.outbreak_needs:getNeeds(s) end)
    local pos = ped ~= 0 and GetEntityCoords(ped) or vector3(0, 0, 0)
    out[#out + 1] = {
      id = s, name = GetPlayerName(s), char = p and (p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname) or '?',
      health = ped ~= 0 and math.max(0, GetEntityHealth(ped) - 100) or 0,
      hunger = n and math.floor(n.hunger or 0) or nil, thirst = n and math.floor(n.thirst or 0) or nil, fatigue = n and math.floor(n.fatigue or 0) or nil,
      infected = n and n.infected or false, down = Player(s).state.downState, ghost = Player(s).state.obGhost == true, god = Player(s).state.obGod == true,
      pos = pos, ch = 0,
    }
    pcall(function() out[#out].ch = exports.outbreak_radio:channelOf(s) or 0 end)
  end
  table.sort(out, function(a, b) return a.id < b.id end)
  return out
end)

RegisterNetEvent('outbreak:dm:do', function(action, a)
  local src = source
  if not dm(src) then return end
  local fn = Actions[action]; if not fn then return end
  log(src, action, a)
  fn(src, a or {})
end)
RegisterNetEvent('outbreak:dm:scene', function(id)
  local src = source
  if not dm(src) then return end
  local sc = DMCfg.Scenes[id]; if not sc then return end
  log(src, 'scene:' .. id, {})
  notify(src, 'Scene: ' .. sc.label, 'success')
  CreateThread(function() for _, step in ipairs(sc.steps) do local fn = Actions[step.action]; if fn then fn(src, step) end end end)
end)
-- schedule a scene or action
RegisterNetEvent('outbreak:dm:schedule', function(minutes, kind, id)
  local src = source; if not dm(src) then return end
  log(src, 'schedule', { minutes = minutes, kind = kind, id = id })
  SetTimeout(math.max(1, tonumber(minutes) or 1) * 60000, function()
    if kind == 'scene' then TriggerEvent('outbreak:dm:runScene', src, id) end
  end)
end)
AddEventHandler('outbreak:dm:runScene', function(src, id) local sc = DMCfg.Scenes[id]; if sc then CreateThread(function() for _, step in ipairs(sc.steps) do local fn = Actions[step.action]; if fn then fn(src, step) end end end) end end)
lib.callback.register('outbreak:dm:players', function(src)
  if not dm(src) then return {} end
  local out = {}
  for _, s in ipairs(GetPlayers()) do s = tonumber(s); local p = QBCore.Functions.GetPlayer(s); out[#out + 1] = { id = s, name = GetPlayerName(s), char = p and (p.PlayerData.charinfo.firstname .. ' ' .. p.PlayerData.charinfo.lastname) or '?', down = Player(s).state.downState } end
  return out
end)
