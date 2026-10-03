-- outbreak_editor/server/missions.lua — a data mission becomes a real opportunity (journal, persistence, state machine)
-- def = { id, title, summary, steps = { { label, type = 'goto'|'collect'|'deliver'|'talk'|'kill'|'flag', x,y,z, radius, item, count, npc, flag, text } },
--         rewards = { { type='give', item, count } | { type='rep', faction, delta } | { type='flag', name, value } | { type='notify', text } },
--         failMinutes, repeatable, cooldownMinutes, solo = true }
local O = function() return exports.outbreak_opportunities end
local Ed = function() return exports.outbreak_editor end
local Kills = {}   -- missionId -> count (while active)
local function notify(src, t, d, ty) TriggerClientEvent('ox_lib:notify', src, { title = t, description = d, type = ty or 'inform', duration = 8000 }) end

local function stepDone(def, r, src, stage)
  local nxt = stage + 1
  if nxt > #def.steps then
    for _, rw in ipairs(def.rewards or {}) do
      if rw.type == 'give' then exports.ox_inventory:AddItem(src, rw.item, tonumber(rw.count) or 1)
      elseif rw.type == 'rep' then pcall(function() exports.outbreak_faction:addRep(src, rw.faction, tonumber(rw.delta) or 5, def.id) end)
      elseif rw.type == 'flag' then Ed():flagSet(rw.name, rw.value == nil and true or rw.value)
      elseif rw.type == 'notify' then notify(src, def.title, rw.text, 'success') end
    end
    O():resolve(def.id, 'done', { by = src })
  else
    O():advance(def.id, nxt, src, {})
    local s = def.steps[nxt]; if s and s.text then notify(src, def.title, s.text, 'inform') end
    TriggerClientEvent('outbreak:editor:missionStep', -1, def.id, nxt, def.steps[nxt])
  end
end
local function register(rec)
  local def = rec.def; if not rec.enabled or not def or not def.id or type(def.steps) ~= 'table' or #def.steps == 0 then return end
  local stages = {}
  for i, s in ipairs(def.steps) do stages[i] = { label = s.label or (s.type .. ' ' .. (s.item or s.npc or '')) } end
  O():registerOpportunity({
    id = def.id, title = def.title or def.id, summary = def.summary or '', stages = stages,
    solutions = { { id = 'do', label = 'Do it', desc = def.summary or '', solo = def.solo ~= false } },
    cooldownMinutes = tonumber(def.cooldownMinutes) or 0, repeatable = def.repeatable == true,
    onStart = function(r, src)
      Kills[def.id] = 0
      if def.failMinutes then r.data.deadline = os.time() + tonumber(def.failMinutes) * 60 end
      local s = def.steps[1]; if src and s and s.text then notify(src, def.title or def.id, s.text, 'inform') end
      TriggerClientEvent('outbreak:editor:missionStep', -1, def.id, 1, def.steps[1])
    end,
    onRestore = function(r) TriggerClientEvent('outbreak:editor:missionStep', -1, def.id, r.stage, def.steps[r.stage]) end,
    onReport = function(r, src, kind, p)
      local s = def.steps[r.stage]; if not s then return end
      local here = GetEntityCoords(GetPlayerPed(src))
      if s.type == 'goto' and kind == 'arrived' then
        if #(here - vector3(tonumber(s.x) or 0, tonumber(s.y) or 0, tonumber(s.z) or 0)) <= (tonumber(s.radius) or 8.0) + 2.0 then stepDone(def, r, src, r.stage) end
      elseif s.type == 'collect' and kind == 'check' then
        if exports.ox_inventory:GetItemCount(src, s.item or '') >= (tonumber(s.count) or 1) then stepDone(def, r, src, r.stage) else notify(src, def.title, ('You need %d × %s.'):format(tonumber(s.count) or 1, tostring(s.item):gsub('_', ' ')), 'error') end
      elseif s.type == 'deliver' and kind == 'talk' and (not s.npc or tostring(p and p.npc) == tostring(s.npc)) then
        if exports.ox_inventory:RemoveItem(src, s.item or '', tonumber(s.count) or 1) then stepDone(def, r, src, r.stage) else notify(src, def.title, ('Bring %d × %s.'):format(tonumber(s.count) or 1, tostring(s.item):gsub('_', ' ')), 'error') end
      elseif s.type == 'talk' and kind == 'talk' and (not s.npc or tostring(p and p.npc) == tostring(s.npc)) then stepDone(def, r, src, r.stage)
      elseif s.type == 'kill' and kind == 'kill' then
        Kills[def.id] = (Kills[def.id] or 0) + 1
        if Kills[def.id] >= (tonumber(s.count) or 5) then Kills[def.id] = 0; stepDone(def, r, src, r.stage) end
      elseif s.type == 'flag' and kind == 'check' then
        if tostring(Ed():flagGet(s.flag or '')) == tostring(s.value == nil and true or s.value) then stepDone(def, r, src, r.stage) end
      end
    end,
    onResolve = function(r, state, outcome) TriggerClientEvent('outbreak:editor:missionStep', -1, def.id, nil, nil) end,
  })
end
AddEventHandler('outbreak:editor:loaded', function() for _, rec in pairs(Ed():get().missions) do register(rec) end end)
AddEventHandler('outbreak:editor:missionChanged', function(rec) register(rec) end)
-- reports arrive from the interaction runner (talk/deliver), from the client (arrived/kill), or from /job commands
AddEventHandler('outbreak:editor:missionReport', function(src, id, kind, p) if id then TriggerEvent('outbreak:editor:reportInternal', src, id, kind, p) end end)
AddEventHandler('outbreak:editor:reportInternal', function(src, id, kind, p)
  local def = Ed():mission(id); if not def then return end
  pcall(function() local rec = O():get(id); if rec and rec.state == 'active' and def.def then
    -- route through the registry's own report path so rate limits and logging apply
    local d = O():def(id); if d and d.onReport then d.onReport(rec, src, kind, p) end end end)
end)
RegisterNetEvent('outbreak:editor:missionStart', function(id)
  local src = source
  if not IsPlayerAceAllowed(src, EditorCfg.Ace) then return end
  if not Ed():mission(id) then return end
  pcall(function() O():makeAvailable(id); O():activate(id, src) end)
end)
RegisterNetEvent('outbreak:editor:clientReport', function(id, kind, p) TriggerEvent('outbreak:editor:reportInternal', source, id, kind, p) end)
AddEventHandler('outbreak:editor:joinMission', function(src, id) pcall(function() TriggerEvent('outbreak:opp:join', id) end); pcall(function() local O2 = exports.outbreak_opportunities; O2:makeAvailable(id); O2:activate(id, src) end) end)
-- a data mission's deadline is enforced here (the registry stores it; nothing else expires it)
CreateThread(function()
  while true do
    Wait(30000)
    for id, rec in pairs(Ed():get().missions) do
      pcall(function() local r = O():get(id); if r and r.state == 'active' and r.data.deadline and os.time() > r.data.deadline then O():fail(id, 'out of time', {}) end end)
    end
  end
end)
