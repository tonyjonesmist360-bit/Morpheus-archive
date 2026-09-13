-- outbreak_opportunities/server/registry.lua — the state machine every chain registers into
local QBCore = exports['qb-core']:GetCoreObject()
local Defs, Recs = {}, {}   -- id -> def, id -> record { state, stage, data, participants, startedAt, resolvedAt, outcome, cooldownUntil }
local lastReport = {}

local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
local function log(id, event, src, data)
  MySQL.insert('INSERT INTO outbreak_opp_log (opp_id, event, citizenid, data, at) VALUES (?, ?, ?, ?, NOW())', { id, event, src and cid(src) or nil, json.encode(data or {}) })
  if GlobalState.obDebug then print(('^5[OB-OPP]^7 %s %s %s'):format(id, event, json.encode(data or {}))) end
end
local function save(id)
  local r = Recs[id]
  MySQL.prepare([[INSERT INTO outbreak_opportunities (opp_id, state, stage, data, started_at, resolved_at, outcome, cooldown_until) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE state=VALUES(state), stage=VALUES(stage), data=VALUES(data), started_at=VALUES(started_at), resolved_at=VALUES(resolved_at), outcome=VALUES(outcome), cooldown_until=VALUES(cooldown_until)]],
    { id, r.state, r.stage, json.encode(r.data), r.startedAt, r.resolvedAt, r.outcome, r.cooldownUntil })
end
local function saveParticipant(id, c)
  local p = Recs[id].participants[c]
  MySQL.prepare('INSERT INTO outbreak_opp_participants (opp_id, citizenid, role, contributions) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE role=VALUES(role), contributions=VALUES(contributions)', { id, c, p.role, json.encode(p.contrib) })
end

local function view(id, src)
  local d, r = Defs[id], Recs[id]
  local remaining = r.data.deadline and math.max(0, r.data.deadline - os.time()) or nil
  local mine = src and cid(src) and r.participants[cid(src)]
  return { id = id, title = d.title, summary = d.summary, state = r.state, stage = r.stage, stages = d.stages, solutions = d.solutions,
           chosen = r.data.solution, deadline = r.data.deadline, remaining = remaining, stub = d.stub or false,
           contrib = r.data.contrib or {}, outcome = r.outcome, joined = mine ~= nil }
end
local function broadcast(id) TriggerClientEvent('outbreak:opp:state', -1, id, view(id)) end

local function setState(id, state, extra)
  local r = Recs[id]; r.state = state
  if extra then for k, v in pairs(extra) do r[k] = v end end
  save(id); broadcast(id); log(id, 'state:' .. state, nil, { stage = r.stage })
end

-- ── public API ──
local function registerOpportunity(def)
  Defs[def.id] = def
  Recs[def.id] = { state = 'dormant', stage = 0, data = {}, participants = {} }
  -- restore
  CreateThread(function()
    local row = MySQL.single.await('SELECT * FROM outbreak_opportunities WHERE opp_id = ?', { def.id })
    if row then
      local r = Recs[def.id]
      r.state, r.stage, r.data, r.startedAt, r.resolvedAt, r.outcome, r.cooldownUntil = row.state, row.stage, json.decode(row.data or '{}'), row.started_at, row.resolved_at, row.outcome, row.cooldown_until
      for _, p in ipairs(MySQL.query.await('SELECT citizenid, role, contributions FROM outbreak_opp_participants WHERE opp_id = ?', { def.id }) or {}) do
        r.participants[p.citizenid] = { role = p.role, contrib = json.decode(p.contributions or '{}') }
      end
      if r.state == 'active' and def.onRestore then def.onRestore(r) end
      if (r.state == 'resolved' or r.state == 'failed' or r.state == 'expired') and r.cooldownUntil and os.time() > r.cooldownUntil and def.repeatable then
        r.state = 'dormant'; r.stage = 0; r.data = {}; r.participants = {}; save(def.id)
      end
    end
  end)
end

local function makeAvailable(id) local r = Recs[id]; if r.state == 'dormant' then setState(id, 'available') end end

local function activate(id, src)
  local d, r = Defs[id], Recs[id]
  if d.stub then log(id, 'refused:stub', src); return false end
  if r.state ~= 'available' and r.state ~= 'dormant' then return false end
  r.stage = 1; r.startedAt = os.time()
  if d.onStart then d.onStart(r, src) end
  setState(id, 'active')
  for c in pairs(r.participants) do
    for _, iid in ipairs(d.intel or {}) do pcall(function() exports.outbreak_intel:setState(GetSrcByCid(c), iid, 'active', 'opportunity') end) end
  end
  return true
end

function GetSrcByCid(c) for _, s in ipairs(GetPlayers()) do if cid(tonumber(s)) == c then return tonumber(s) end end end

local function join(id, src, role)
  local r = Recs[id]; local c = cid(src); if not c then return false end
  if r.state ~= 'available' and r.state ~= 'active' then return false end
  if not r.participants[c] then
    r.participants[c] = { role = role or 'volunteer', contrib = {} }; saveParticipant(id, c); log(id, 'join', src)
    if r.state == 'active' then for _, iid in ipairs(Defs[id].intel or {}) do pcall(function() exports.outbreak_intel:setState(src, iid, 'active', 'opportunity') end) end end
  end
  if r.state == 'available' then activate(id, src) else broadcast(id) end
  return true
end

local function advance(id, stage, by, data)
  local d, r = Defs[id], Recs[id]
  if r.state ~= 'active' then return false end
  if stage ~= r.stage + 1 then log(id, 'refused:stage', by, { want = stage, at = r.stage }); return false end
  r.stage = stage
  if d.onStage then d.onStage(r, stage, data) end
  save(id); broadcast(id); log(id, 'stage:' .. stage, by, data)
  TriggerClientEvent('outbreak:opp:stage', -1, id, stage, data)
  return true
end

local function finish(id, state, outcome, data)
  local d, r = Defs[id], Recs[id]
  if r.state ~= 'active' and not (state == 'expired' and r.state == 'available') then return end
  r.resolvedAt = os.time(); r.outcome = outcome
  r.cooldownUntil = d.cooldownMinutes and (os.time() + d.cooldownMinutes * 60) or nil
  setState(id, state)
  if d.onResolve then d.onResolve(r, state, outcome, data) end
  local intelState = state == 'resolved' and 'completed' or 'failed'
  for c in pairs(r.participants) do
    local s = GetSrcByCid(c)
    if s then for _, iid in ipairs(d.intel or {}) do pcall(function() exports.outbreak_intel:setState(s, iid, intelState, 'opportunity') end) end end
  end
  log(id, 'finish:' .. state, nil, { outcome = outcome, data = data })
end

local function contribute(id, src, key, amount)
  local r = Recs[id]; local c = cid(src)
  if r.state ~= 'active' or not c then return 0 end
  r.participants[c] = r.participants[c] or { role = 'volunteer', contrib = {} }
  r.participants[c].contrib[key] = (r.participants[c].contrib[key] or 0) + amount
  r.data.contrib = r.data.contrib or {}; r.data.contrib[key] = (r.data.contrib[key] or 0) + amount
  saveParticipant(id, c); save(id); broadcast(id)
  return r.data.contrib[key]
end

exports('registerOpportunity', registerOpportunity)
exports('get', function(id) return Recs[id] end)
exports('def', function(id) return Defs[id] end)
exports('makeAvailable', makeAvailable)
exports('activate', activate)
exports('advance', advance)
exports('resolve', function(id, outcome, data) finish(id, 'resolved', outcome, data) end)
exports('fail', function(id, reason, data) finish(id, 'failed', reason, data) end)
exports('expire', function(id, data) finish(id, 'expired', 'ignored', data) end)
exports('participants', function(id) return Recs[id] and Recs[id].participants or {} end)
exports('participantCount', function(id) local n = 0 for _ in pairs(Recs[id].participants) do n = n + 1 end return n end)
exports('contribute', contribute)
exports('setData', function(id, k, v) Recs[id].data[k] = v; save(id); broadcast(id) end)
exports('journalView', function(src) local out = {} for id in pairs(Defs) do out[id] = view(id, src) end return out end)
exports('log', log)

-- intel confirmed -> opportunity becomes available
AddEventHandler('outbreak:intel:confirmed', function(src, intelId, oppId)
  local d = Defs[oppId]; if not d then return end
  if d.trigger == intelId or (not d.trigger) then makeAvailable(oppId) end
  if d.onIntel then d.onIntel(Recs[oppId], src, intelId) end
end)

-- ── client → server (validated) ──
RegisterNetEvent('outbreak:opp:join', function(id) if Defs[id] then join(id, source) end end)
RegisterNetEvent('outbreak:opp:choose', function(id, sol)
  local src = source; local d, r = Defs[id], Recs[id]; if not d or r.state ~= 'active' then return end
  local ok = false; for _, s in ipairs(d.solutions or {}) do if s.id == sol then ok = true end end
  if not ok or not r.participants[cid(src)] then return end
  if d.onChoose and d.onChoose(r, src, sol) ~= false then r.data.solution = sol; save(id); broadcast(id); log(id, 'choose:' .. sol, src) end
end)
RegisterNetEvent('outbreak:opp:deliver', function(id, item)
  local src = source; local d, r = Defs[id], Recs[id]; if not d or r.state ~= 'active' or not d.onDeliver then return end
  d.onDeliver(r, src, item)
end)
RegisterNetEvent('outbreak:opp:report', function(id, kind, payload)
  local src = source; local d = Defs[id]; if not d or not d.onReport then return end
  local k = src .. id .. kind; local now = GetGameTimer()
  if lastReport[k] and now - lastReport[k] < OppCfg.ReportRateMs then return end
  lastReport[k] = now
  d.onReport(Recs[id], src, kind, payload)
end)

-- Debug/test: /ob_opp <warn|start|expire|status> <id>  (ace outbreak.debug + ob_debug)
RegisterCommand('ob_opp', function(src, a)
  if not GlobalState.obDebug or (src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.debug')) then return end
  local id = a[2]; local d = Defs[id]; if not d then print('unknown opp') return end
  if a[1] == 'status' then print(json.encode(view(id), { indent = true }))
  elseif a[1] == 'available' then makeAvailable(id)
  elseif a[1] == 'start' then if src ~= 0 then join(id, src) else activate(id) end
  elseif a[1] == 'expire' then finish(id, 'expired', 'debug')
  elseif d.debug and d.debug[a[1]] then d.debug[a[1]](Recs[id], src, a) end
end, true)
