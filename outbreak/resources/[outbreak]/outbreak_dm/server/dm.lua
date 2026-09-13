-- outbreak_dm/server/dm.lua — every action lands here, is ace-checked, and is logged.
local QBCore = exports['qb-core']:GetCoreObject()
local function dm(src) return src == 0 or IsPlayerAceAllowed(src, DMCfg.Ace) end
local function log(src, action, data)
  MySQL.insert('INSERT INTO outbreak_dm_log (actor, action, data, at) VALUES (?, ?, ?, NOW())', { src == 0 and 'console' or GetPlayerName(src), action, json.encode(data or {}) })
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
  local ok, ent = pcall(function() local e = exports.outbreak_vehicles:spawnManaged(a.model, p, GetEntityHeading(GetPlayerPed(src)), ('DM' .. math.random(1000, 9999)), a.state or { locked = false, battery = 'ok', fuel = 50, hotwired = true }) return e end)
  if not ok or not ent then TriggerClientEvent('outbreak:dm:spawnVehicle', src, a.model, p) end
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
