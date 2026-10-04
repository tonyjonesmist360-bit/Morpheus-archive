-- outbreak_editor/server/store.lua — every editor object lives here and is published as GlobalState.obEditor.
local QBCore = exports['qb-core']:GetCoreObject()
local S = { npcs = {}, hidden = {}, interactions = {}, zones = {}, kv = {}, missions = {} }
local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
local function allowed(src) return src == 0 or IsPlayerAceAllowed(src, EditorCfg.Ace) end
-- base64 (for uploaded item icons). FiveM has no built-in decoder.
local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function base64decode(data)
  data = data:gsub('[^' .. B64 .. '=]', '')
  return (data:gsub('.', function(x)
    if x == '=' then return '' end
    local r, f = '', (B64:find(x, 1, true) - 1)
    for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and '1' or '0') end
    return r
  end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
    if #x ~= 8 then return '' end
    local c = 0
    for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2 ^ (8 - i) or 0) end
    return string.char(c)
  end))
end
local function dec(s, d) local ok, t = pcall(json.decode, s or ''); return ok and type(t) == 'table' and t or (d or {}) end
local function publish()
  GlobalState.obEditor = { npcs = S.npcs, hidden = S.hidden, interactions = S.interactions, zones = S.zones, loot = S.kv['loot'] or {}, rev = (GlobalState.obEditor and (GlobalState.obEditor.rev or 0) or 0) + 1 }
end
local function load()
  local okq, qerr = pcall(function()
    S.npcs, S.hidden, S.interactions, S.zones, S.kv, S.missions = {}, {}, {}, {}, {}, {}
    for _, r in ipairs(MySQL.query.await('SELECT * FROM outbreak_editor_npcs') or {}) do S.npcs[r.id] = { id = r.id, name = r.name, look = r.look, model = r.model, x = r.x, y = r.y, z = r.z, h = r.h, behaviour = dec(r.behaviour), stance = r.stance or 'neutral', data = dec(r.data) } end
    for _, r in ipairs(MySQL.query.await('SELECT * FROM outbreak_editor_hidden_peds') or {}) do S.hidden[r.id] = { id = r.id, model = r.model, x = r.x, y = r.y, z = r.z, note = r.note } end
    for _, r in ipairs(MySQL.query.await('SELECT * FROM outbreak_editor_interactions') or {}) do S.interactions[r.id] = { id = r.id, target = dec(r.target), label = r.label, icon = r.icon, hold = r.hold_ms or 0, anim = r.anim, conditions = dec(r.conditions), actions = dec(r.actions), enabled = r.enabled == 1 } end
    for _, r in ipairs(MySQL.query.await('SELECT * FROM outbreak_editor_zones') or {}) do S.zones[r.id] = { id = r.id, name = r.name, kind = r.kind, x = r.x, y = r.y, z = r.z, radius = r.radius, data = dec(r.data) } end
    for _, r in ipairs(MySQL.query.await('SELECT * FROM outbreak_editor_kv') or {}) do S.kv[r.k] = dec(r.v) end
    for _, r in ipairs(MySQL.query.await('SELECT * FROM outbreak_editor_missions') or {}) do S.missions[r.id] = { id = r.id, def = dec(r.def), enabled = r.enabled == 1 } end
  end)
  if not okq then
    print(('^1[outbreak_editor] load failed: %s^7'):format(tostring(qerr)))
    print('^1[outbreak_editor] if that says a table does not exist: run setup/03-apply-migrations.ps1 -Base <txData> (010_editor.sql). Otherwise the DB was not ready yet; retrying.^7')
    return false
  end
  S = { npcs = S.npcs, hidden = S.hidden, interactions = S.interactions, zones = S.zones, kv = S.kv, missions = S.missions }
  publish()
  local n = 0; for _ in pairs(S.interactions) do n = n + 1 end
  print(('^5[OB-EDITOR]^7 loaded: %d npcs, %d hidden peds, %d interactions, %d zones, %d missions'):format((function() local c = 0 for _ in pairs(S.npcs) do c = c + 1 end return c end)(), (function() local c = 0 for _ in pairs(S.hidden) do c = c + 1 end return c end)(), n, (function() local c = 0 for _ in pairs(S.zones) do c = c + 1 end return c end)(), (function() local c = 0 for _ in pairs(S.missions) do c = c + 1 end return c end)()))
  TriggerEvent('outbreak:editor:loaded')
  return true
end
local loaded = false
CreateThread(function()
  -- the DB can come up after us: retry for a minute before giving up (the loader says why each time)
  for attempt = 1, 12 do
    Wait(attempt == 1 and 2000 or 5000)
    if load() then loaded = true break end
  end
end)
RegisterCommand('editor_reload', function(src) if src ~= 0 and not IsPlayerAceAllowed(src, EditorCfg.Ace) then return end; loaded = load(); print('[outbreak_editor] reload: ' .. (loaded and 'ok' or 'failed')) end, true)
exports('isLoaded', function() return loaded end)

-- ── CRUD. One event, one verb, server validates the ace and the shape. Every change is logged and republished. ──
local function log(src, what, d) pcall(function() exports.outbreak_log:log('editor.' .. what, src, d) end) end
local function num(v, d) v = tonumber(v); return v or d end
local function str(v, n) v = tostring(v or ''); return v:sub(1, n or 64) end

local Ops = {}
Ops['npc.save'] = function(src, d)
  local rec = { name = str(d.name, 48), look = str(d.look, 220), model = str(d.model), x = num(d.x, 0), y = num(d.y, 0), z = num(d.z, 0), h = num(d.h, 0), behaviour = type(d.behaviour) == 'table' and d.behaviour or {}, stance = str(d.stance, 16), data = type(d.data) == 'table' and d.data or {} }
  if rec.model == '' then return nil, 'model' end
  if d.id and S.npcs[tonumber(d.id)] then
    rec.id = tonumber(d.id)
    MySQL.update('UPDATE outbreak_editor_npcs SET name=?, look=?, model=?, x=?, y=?, z=?, h=?, behaviour=?, stance=?, data=? WHERE id=?', { rec.name, rec.look, rec.model, rec.x, rec.y, rec.z, rec.h, json.encode(rec.behaviour), rec.stance, json.encode(rec.data), rec.id })
  else
    rec.id = MySQL.insert.await('INSERT INTO outbreak_editor_npcs (name, look, model, x, y, z, h, behaviour, stance, data) VALUES (?,?,?,?,?,?,?,?,?,?)', { rec.name, rec.look, rec.model, rec.x, rec.y, rec.z, rec.h, json.encode(rec.behaviour), rec.stance, json.encode(rec.data) })
  end
  S.npcs[rec.id] = rec; return rec
end
Ops['npc.delete'] = function(src, d) local id = tonumber(d.id); if not S.npcs[id] then return nil, 'no such npc' end; local old = S.npcs[id]; S.npcs[id] = nil; MySQL.update('DELETE FROM outbreak_editor_npcs WHERE id = ?', { id }); return old end
Ops['hidden.add'] = function(src, d)
  local rec = { model = num(d.model, 0), x = num(d.x, 0), y = num(d.y, 0), z = num(d.z, 0), note = str(d.note, 64) }
  rec.id = MySQL.insert.await('INSERT INTO outbreak_editor_hidden_peds (model, x, y, z, note) VALUES (?,?,?,?,?)', { rec.model, rec.x, rec.y, rec.z, rec.note })
  S.hidden[rec.id] = rec; return rec
end
Ops['hidden.delete'] = function(src, d) local id = tonumber(d.id); local old = S.hidden[id]; if not old then return nil, 'no such' end; S.hidden[id] = nil; MySQL.update('DELETE FROM outbreak_editor_hidden_peds WHERE id = ?', { id }); return old end
Ops['interaction.save'] = function(src, d)
  if type(d.target) ~= 'table' or not d.target.kind then return nil, 'target' end
  local rec = { target = d.target, label = str(d.label, 64), icon = str(d.icon, 64), hold = num(d.hold, 0), anim = str(d.anim, 32), conditions = type(d.conditions) == 'table' and d.conditions or {}, actions = type(d.actions) == 'table' and d.actions or {}, enabled = d.enabled ~= false }
  if rec.label == '' then rec.label = 'Use' end
  if d.id and S.interactions[tonumber(d.id)] then
    rec.id = tonumber(d.id)
    MySQL.update('UPDATE outbreak_editor_interactions SET target=?, label=?, icon=?, hold_ms=?, anim=?, conditions=?, actions=?, enabled=? WHERE id=?', { json.encode(rec.target), rec.label, rec.icon, rec.hold, rec.anim, json.encode(rec.conditions), json.encode(rec.actions), rec.enabled and 1 or 0, rec.id })
  else
    rec.id = MySQL.insert.await('INSERT INTO outbreak_editor_interactions (target, label, icon, hold_ms, anim, conditions, actions, enabled) VALUES (?,?,?,?,?,?,?,?)', { json.encode(rec.target), rec.label, rec.icon, rec.hold, rec.anim, json.encode(rec.conditions), json.encode(rec.actions), rec.enabled and 1 or 0 })
  end
  S.interactions[rec.id] = rec; return rec
end
Ops['interaction.delete'] = function(src, d) local id = tonumber(d.id); local old = S.interactions[id]; if not old then return nil, 'no such' end; S.interactions[id] = nil; MySQL.update('DELETE FROM outbreak_editor_interactions WHERE id = ?', { id }); MySQL.update('DELETE FROM outbreak_editor_once WHERE interaction_id = ?', { id }); return old end
Ops['zone.save'] = function(src, d)
  local rec = { name = str(d.name, 48), kind = str(d.kind, 24), x = num(d.x, 0), y = num(d.y, 0), z = num(d.z, 0), radius = math.max(2.0, num(d.radius, 20)), data = type(d.data) == 'table' and d.data or {} }
  if not EditorCfg.ZoneKinds[rec.kind] then return nil, 'kind' end
  if d.id and S.zones[tonumber(d.id)] then
    rec.id = tonumber(d.id)
    MySQL.update('UPDATE outbreak_editor_zones SET name=?, kind=?, x=?, y=?, z=?, radius=?, data=? WHERE id=?', { rec.name, rec.kind, rec.x, rec.y, rec.z, rec.radius, json.encode(rec.data), rec.id })
  else
    rec.id = MySQL.insert.await('INSERT INTO outbreak_editor_zones (name, kind, x, y, z, radius, data) VALUES (?,?,?,?,?,?,?)', { rec.name, rec.kind, rec.x, rec.y, rec.z, rec.radius, json.encode(rec.data) })
  end
  S.zones[rec.id] = rec; return rec
end
Ops['zone.delete'] = function(src, d) local id = tonumber(d.id); local old = S.zones[id]; if not old then return nil, 'no such' end; S.zones[id] = nil; MySQL.update('DELETE FROM outbreak_editor_zones WHERE id = ?', { id }); return old end
Ops['kv.set'] = function(src, d)
  local k = str(d.k, 64); if k == '' then return nil, 'key' end
  S.kv[k] = type(d.v) == 'table' and d.v or {}
  MySQL.prepare('INSERT INTO outbreak_editor_kv (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { k, json.encode(S.kv[k]) })
  return { k = k, v = S.kv[k] }
end
Ops['mission.save'] = function(src, d)
  if type(d.def) ~= 'table' or type(d.def.id) ~= 'string' or d.def.id == '' then return nil, 'def.id' end
  local id = d.def.id:gsub('[^%w_]', ''):sub(1, 48)
  d.def.id = id
  local rec = { id = id, def = d.def, enabled = d.enabled ~= false }
  MySQL.prepare('INSERT INTO outbreak_editor_missions (id, def, enabled) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE def = VALUES(def), enabled = VALUES(enabled)', { id, json.encode(rec.def), rec.enabled and 1 or 0 })
  S.missions[id] = rec
  TriggerEvent('outbreak:editor:missionChanged', rec)
  return rec
end
Ops['mission.delete'] = function(src, d) local id = tostring(d.id); local old = S.missions[id]; if not old then return nil, 'no such' end; S.missions[id] = nil; MySQL.update('DELETE FROM outbreak_editor_missions WHERE id = ?', { id }); return old end
-- item drafts: appended to the ox items snippet (managed EDITOR ITEMS section); icon written to ox_inventory/web/images. Restart + 04 paste-in to land.
Ops['item.create'] = function(src, d)
  local name = str(d.name, 32):lower():gsub('[^%w_]', ''); if name == '' then return nil, 'name' end
  local label = str(d.label, 48); local weight = math.floor(num(d.weight, 100)); local desc = str(d.description, 160):gsub("'", "\\'")
  local drafts = S.kv['items'] or {}
  drafts[name] = { label = label, weight = weight, description = desc, image = d.icon and (name .. '.png') or nil, effects = type(d.effects) == 'table' and d.effects or nil }
  S.kv['items'] = drafts
  MySQL.prepare('INSERT INTO outbreak_editor_kv (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { 'items', json.encode(drafts) })
  if type(d.icon) == 'string' and d.icon:find('^data:image/png;base64,') then
    local raw = d.icon:gsub('^data:image/png;base64,', '')
    local okb, bytes = pcall(function() return base64decode(raw) end)
    if okb and bytes then SaveResourceFile('ox_inventory', 'web/images/' .. name .. '.png', bytes, -1) end
  end
  -- rewrite the managed section of the snippet
  local snippet = LoadResourceFile('outbreak_items', 'data/ox_items_snippet.lua') or ''
  snippet = snippet:gsub('\n%-%- >>> EDITOR ITEMS.-%-%- <<< EDITOR ITEMS\n', '\n')
  local lines = { '-- >>> EDITOR ITEMS (managed by outbreak_editor; apply with setup/04-paste-ins.ps1 -Only items, then restart)' }
  for n, it in pairs(drafts) do
    lines[#lines + 1] = ("['%s'] = { label = '%s', weight = %d, description = '%s'%s },"):format(n, (it.label or n):gsub("'", "\\'"), it.weight or 100, it.description or '', it.image and (", client = { image = '" .. it.image .. "' }") or '')
  end
  lines[#lines + 1] = '-- <<< EDITOR ITEMS'
  SaveResourceFile('outbreak_items', 'data/ox_items_snippet.lua', snippet .. '\n' .. table.concat(lines, '\n') .. '\n', -1)
  return { name = name, pending = true }
end

RegisterNetEvent('outbreak:editor:op', function(op, d, reqId)
  local src = source
  if not allowed(src) then return end
  local fn = Ops[op]; if not fn then return end
  d = type(d) == 'table' and d or {}
  local rec, err = fn(src, d)
  if rec then publish(); log(src, op, { id = rec.id or rec.k or rec.name }) end
  TriggerClientEvent('outbreak:editor:opResult', src, reqId, op, rec, err)
end)
lib.callback.register('outbreak:editor:state', function(src) if not allowed(src) then return nil end return { npcs = S.npcs, hidden = S.hidden, interactions = S.interactions, zones = S.zones, kv = S.kv, missions = S.missions } end)

-- read-model exports for the rest of the pack (spawner, loot, raiders...)
local function zoneAt(x, y, z, kind)
  local p = vector3(x, y, z); local best, bd
  for _, zn in pairs(S.zones) do
    if (not kind or zn.kind == kind) then local d = #(p - vector3(zn.x, zn.y, zn.z)); if d <= zn.radius and (not bd or d < bd) then best, bd = zn, d end end
  end
  return best
end
exports('zoneAt', zoneAt)
exports('zoneMult', function(x, y, z)   -- spawner density multiplier at a point; nil = no editor zone here
  local zn = zoneAt(x, y, z); if not zn then return nil end
  local k = EditorCfg.ZoneKinds[zn.kind]; return k and k.mult or nil
end)
exports('lootBias', function(x, y, z) local zn = zoneAt(x, y, z, 'loot'); return zn and ((zn.data and zn.data.bias) or EditorCfg.ZoneKinds.loot.bias) or 1.0 end)
exports('territoryAt', function(x, y, z) local zn = zoneAt(x, y, z, 'territory'); return zn and zn.data and zn.data.faction or nil end)
exports('kv', function(k) return S.kv[k] end)
exports('get', function() return S end)
exports('npc', function(id) return S.npcs[id] end)
exports('interaction', function(id) return S.interactions[id] end)
exports('mission', function(id) return S.missions[id] end)
exports('ops', function(op, src, d) local fn = Ops[op]; if not fn then return nil, 'op' end; local r, e = fn(src or 0, d); if r then publish() end; return r, e end)
exports('flagGet', function(name) local f = S.kv['flags'] or {}; return f[name] end)
exports('flagSet', function(name, value) local f = S.kv['flags'] or {}; f[name] = value; S.kv['flags'] = f; MySQL.prepare('INSERT INTO outbreak_editor_kv (k, v) VALUES (?, ?) ON DUPLICATE KEY UPDATE v = VALUES(v)', { 'flags', json.encode(f) }); publish() end)
