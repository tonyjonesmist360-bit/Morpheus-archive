-- outbreak_editor/server/runner.lua — the generic interaction runner. Clients only ask; every condition and every
-- action is evaluated here. Nothing in it needs Lua from the author: it is data from the editor.
local QBCore = exports['qb-core']:GetCoreObject()
local Ed = function() return exports.outbreak_editor end
local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
local function notify(src, t, d, ty) TriggerClientEvent('ox_lib:notify', src, { title = t, description = d, type = ty or 'inform', duration = 7000 }) end
local cooldowns = {}  -- interactionId -> { [cid] = until }

local Cond = {}
Cond.item = function(src, c) return exports.ox_inventory:GetItemCount(src, c.item or '') >= (tonumber(c.count) or 1), ('You need %s.'):format(tostring(c.item):gsub('_', ' ')) end
Cond.rep = function(src, c) local v = 0; pcall(function() v = exports.outbreak_faction:getRep(src, c.faction or 'military') end); return v >= (tonumber(c.min) or 0), ('They do not trust you enough (%s).'):format(tostring(c.faction)) end
Cond.time = function(src, c) local h = math.floor((tonumber(GlobalState.obTime) or 720) / 60); local a, b = tonumber(c.from) or 0, tonumber(c.to) or 24; local ok = a <= b and (h >= a and h < b) or (h >= a or h < b); return ok, 'Not at this hour.' end
Cond.flag = function(src, c) local v = Ed():flagGet(c.name or ''); local want = c.value; if want == nil then want = true end; return tostring(v) == tostring(want), 'Not yet.' end
Cond.chapter = function(src, c) local v = tonumber(Ed():flagGet('chapter') or 1) or 1; return v >= (tonumber(c.min) or 1), 'Not in this chapter.' end
Cond.job = function(src, c) local j = 'unemployed'; pcall(function() local p = QBCore.Functions.GetPlayer(src); j = p and p.PlayerData.job and p.PlayerData.job.name or j end); return j == (c.job or ''), 'Not your people.' end
Cond.settlement = function(src, c)
  local ok = false
  pcall(function() for _, h in ipairs(exports.outbreak_housing:houses() or {}) do if exports.outbreak_housing:hasKey(src, h.id) then ok = true end end end)
  return ok, 'You hold no door.'
end
Cond.once = function(src, c, inter) local row = MySQL.single.await('SELECT at FROM outbreak_editor_once WHERE interaction_id = ? AND citizenid = ?', { inter.id, cid(src) or '' }); return row == nil, 'You already did this.' end
Cond.cooldown = function(src, c, inter) local u = cooldowns[inter.id] and cooldowns[inter.id][cid(src) or ''] or 0; return os.time() >= u, 'Not yet. Come back later.' end

local Act = {}
-- loot: roll a table (editor override first, then the pack's own tables) straight into the pockets
Act.loot = function(src, a)
  local ov = Ed():kv('loot') or {}
  local tbl = (ov.tables or {})[a.table or ''] or LootCfg.Tables[a.table or '']
  if not tbl then notify(src, 'Nothing here.', '', 'inform') return end
  local mult = 1.0; pcall(function() mult = tonumber(GlobalState.obTune and GlobalState.obTune['loot.multiplier']) or 1.0 end)
  pcall(function() local c = GetEntityCoords(GetPlayerPed(src)); mult = mult * (Ed():lootBias(c.x, c.y, c.z) or 1.0) end)
  local found = {}
  for _, e in ipairs(tbl) do
    if math.random() < (tonumber(e[4]) or 0.2) * mult then
      local n = math.random(tonumber(e[2]) or 1, tonumber(e[3]) or 1)
      if exports.ox_inventory:CanCarryItem(src, e[1], n) and exports.ox_inventory:AddItem(src, e[1], n) then found[#found + 1] = ('%d × %s'):format(n, tostring(e[1]):gsub('_', ' ')) end
    end
  end
  notify(src, a.label or 'Searched', #found > 0 and table.concat(found, ', ') or 'Nothing worth taking.', #found > 0 and 'success' or 'inform')
end
Act.give = function(src, a) exports.ox_inventory:AddItem(src, a.item, tonumber(a.count) or 1, type(a.metadata) == 'table' and a.metadata or nil) end
Act.take = function(src, a) return exports.ox_inventory:RemoveItem(src, a.item, tonumber(a.count) or 1) end
Act.stash = function(src, a) local id = 'ed_' .. tostring(a.id or 'stash'); exports.ox_inventory:RegisterStash(id, a.label or 'Stash', tonumber(a.slots) or 20, tonumber(a.weight) or 60000, nil); exports.ox_inventory:forceOpenInventory(src, 'stash', id) end
Act.say = function(src, a) notify(src, a.title or 'Someone', a.text or '', 'inform') end
Act.notify = function(src, a) notify(src, a.title or '', a.text or '', a.type or 'inform') end
Act.mission = function(src, a) pcall(function() local O = exports.outbreak_opportunities; if a.op == 'start' then O:activate(a.id, src) elseif a.op == 'join' then TriggerEvent('outbreak:editor:joinMission', src, a.id) else O:makeAvailable(a.id) end end) end
Act.report = function(src, a) TriggerEvent('outbreak:editor:missionReport', src, a.mission, a.kind or 'talk', a) end
Act.flag = function(src, a) Ed():flagSet(a.name or 'flag', a.value == nil and true or a.value) end
Act.scene = function(src, a) TriggerEvent('outbreak:dm:runScene', src, a.id) end
Act.transmit = function(src, a) pcall(function() exports.outbreak_radio:transmit(tonumber(a.ch) or 0, a.title or 'STATIC', a.text or '', nil, a.here and GetEntityCoords(GetPlayerPed(src)) or nil, tonumber(a.range)) end) end
Act.spawn = function(src, a) if a.kind == 'horde' then pcall(function() exports.outbreak_core:fireEvent('horde', src, { size = tonumber(a.count) or 15 }) end) else TriggerClientEvent('outbreak:dm:spawnZombies', src, tonumber(a.count) or 5, GetEntityCoords(GetPlayerPed(src)), a.variant) end end
Act.rep = function(src, a) pcall(function() exports.outbreak_faction:addRep(src, a.faction or 'military', tonumber(a.delta) or 5, a.reason or 'interaction') end) end
Act.teleport = function(src, a) TriggerClientEvent('outbreak:dm:tp', src, vector3(tonumber(a.x) or 0, tonumber(a.y) or 0, tonumber(a.z) or 0)) end
Act.heal = function(src, a) pcall(function() exports.outbreak_needs:reset(src) end); TriggerClientEvent('outbreak:dm:heal', src) end
Act.learn_channel = function(src, a) TriggerClientEvent('outbreak:radio:learn', src, tonumber(a.ch) or 1, a.why) end
Act.noise = function(src, a) TriggerClientEvent('outbreak:client:noiseSpike', src, tonumber(a.v) or 50) end

local function run(src, inter)
  for _, c in ipairs(inter.conditions or {}) do
    local fn = Cond[c.type]
    if fn then local ok, why = fn(src, c, inter); if not ok then notify(src, inter.label, why, 'error'); return false end end
  end
  for _, a in ipairs(inter.actions or {}) do
    local fn = Act[a.type]
    if fn then local ok, err = pcall(fn, src, a); if not ok then print(('^1[OB-EDITOR] action %s failed: %s^7'):format(tostring(a.type), tostring(err))) end end
  end
  for _, c in ipairs(inter.conditions or {}) do
    if c.type == 'once' then MySQL.prepare('INSERT IGNORE INTO outbreak_editor_once (interaction_id, citizenid, at) VALUES (?, ?, ?)', { inter.id, cid(src) or '', os.time() }) end
    if c.type == 'cooldown' then cooldowns[inter.id] = cooldowns[inter.id] or {}; cooldowns[inter.id][cid(src) or ''] = os.time() + (tonumber(c.seconds) or 60) end
  end
  pcall(function() exports.outbreak_log:log('editor.interact', src, { id = inter.id, label = inter.label }) end)
  return true
end
RegisterNetEvent('outbreak:editor:interact', function(id)
  local src = source
  local inter = Ed():interaction(tonumber(id)); if not inter or not inter.enabled then return end
  -- proximity: the target's position (entity/zone/npc) must be close
  local t = inter.target; local pos
  if t.kind == 'npc' then local n = Ed():npc(tonumber(t.id)); pos = n and vector3(n.x, n.y, n.z) end
  if t.kind == 'entity' or t.kind == 'zone' or t.kind == 'point' then pos = vector3(tonumber(t.x) or 0, tonumber(t.y) or 0, tonumber(t.z) or 0) end
  if pos and #(GetEntityCoords(GetPlayerPed(src)) - pos) > ((t.kind == 'zone' and (tonumber(t.radius) or 5.0)) or 4.0) + 3.0 then return end
  run(src, inter)
end)
exports('run', function(src, id) local inter = Ed():interaction(tonumber(id)); return inter and run(src, inter) or false end)
