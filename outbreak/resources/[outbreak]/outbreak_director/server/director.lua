-- outbreak_director/server/director.lua
-- One pass every 30-60 minutes. For each settlement with a keyholder online: read the model,
-- score the possible nudges, pick ONE, do it, log it. Everything it touches goes through the
-- owning resource's exports (supply for residents/morale/log, core for hordes, radio for words).
local D = DirectorCfg
local last, pending, nextId = {}, {}, 1

local function cd(house, a) return os.time() - (last[house .. ':' .. a] or 0) >= (D.Cooldowns[a] or 0) * 60 end
local function mark(house, a) last[house .. ':' .. a] = os.time() end
local function logDb(house, action, detail)
  pcall(function() exports.outbreak_log:log('director.' .. tostring(action), 0, { house = house, detail = detail }) end)
  pcall(function() MySQL.prepare('INSERT INTO outbreak_director_log (house_id, action, detail) VALUES (?, ?, ?)', { house, action, tostring(detail or ''):sub(1, 250) }) end)
  if GlobalState.obDebug then print(('^5[OB-DIRECTOR]^7 %s: %s - %s'):format(house, action, tostring(detail or ''))) end
end
local function radio(text) pcall(function() exports.outbreak_radio:transmit(D.Channel, 'OVERHEARD', text) end) end
local function line(key, ...) local l = D.Lines[key]; return l[math.random(#l)]:format(...) end
local function slog(id, text) pcall(function() exports.outbreak_supply:log(id, text) end) end
local function tell(srcs, title, desc, kind) for _, s in ipairs(srcs) do TriggerClientEvent('ox_lib:notify', s, { title = title, description = desc, type = kind or 'inform', duration = 10000 }) end end
local function nearestSite(list, pos) local best, bd; for _, s in ipairs(list) do local d = #(s.pos - pos); if not bd or d < bd then best, bd = s, d end end return best end
local function nearestPlayer(srcs, pos, maxD)
  local best, bd = nil, maxD or math.huge
  for _, src in ipairs(srcs) do
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then local d = #(GetEntityCoords(ped) - pos); if d < bd then best, bd = src, d end end
  end
  return best, bd
end
local function W(k) local t = GlobalState.obTune; local v = t and tonumber(t['director.weight.' .. k]); return v or D.Weights[k] end
local function pick(c)
  local total = 0; for _, x in ipairs(c) do total = total + x.w end
  if total <= 0 then return nil end
  local r = math.random() * total
  for _, x in ipairs(c) do r = r - x.w; if r <= 0 then return x.a end end
  return c[#c].a
end
local function houseCfg(id) for _, h in ipairs(exports.outbreak_housing:houses() or {}) do if h.id == id then return h end end end

local Actions = {}
Actions.stranger = function(m, kh)
  local src = nearestPlayer(kh, m.door); if not src then return nil end
  local id = nextId; nextId = nextId + 1
  pending[id] = { house = m.id, expires = os.time() + D.StrangerExpireMinutes * 60 }
  TriggerClientEvent('outbreak:director:stranger', src, { id = id, house = m.id, door = m.door, label = m.label, line = D.StrangerLines[math.random(#D.StrangerLines)] })
  slog(m.id, 'A stranger came to the door.')
  return 'stranger at ' .. m.label
end
Actions.rumor_food = function(m) local s = nearestSite(D.Rumors.food, m.door); local t = line('rumor_food', s.label); radio(t); slog(m.id, 'Overheard: ' .. t); return t end
Actions.rumor_medicine = function(m) local s = nearestSite(D.Rumors.medicine, m.door); local t = line('rumor_medicine', s.label); radio(t); slog(m.id, 'Overheard: ' .. t); return t end
-- ── DEFENSE EVENT: warning -> prep -> wave -> consequences. One per house at a time. ──
local defense = {}   -- house -> { stage, deadline, size }
local function model(id) local m; pcall(function() m = exports.outbreak_supply:getSettlement(id) end); return m end
local function keyholders(id) local k = {}; pcall(function() k = exports.outbreak_supply:keyholders(id) or {} end); return k end
local function broadcastStage(id, stage, data)
  data = data or {}; data.house = id
  TriggerClientEvent('outbreak:director:defense', -1, id, stage, data)
end
local function resolveDefense(id)
  local e = defense[id]; if not e then return end
  local m = model(id); if not m then defense[id] = nil return end
  local F = D.Defense
  local held = false
  for _, src in ipairs(keyholders(id)) do
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 and GetEntityHealth(ped) > 101 and not Player(src).state.downState and #(GetEntityCoords(ped) - m.door) <= F.holdRadius then held = true break end
  end
  local text
  if held then
    local spent = 0
    pcall(function() spent = exports.outbreak_supply:takeUnits(id, 'ammo', F.roundsBase + m.residents * F.roundsPerResident, 'scraps') or 0 end)
    pcall(function() exports.outbreak_supply:takeUnits(id, 'materials', F.held.materials, 'scraps') end)
    text = ('The door held. %d rounds spent, a part used on repairs.'):format(math.floor(spent))
    pcall(function() exports.outbreak_supply:modify(id, { morale = F.held.morale }, text) end)
    radio(line('held', m.label))
  else
    pcall(function()
      exports.outbreak_supply:takeUnits(id, 'food', F.overrun.food, 'best'); exports.outbreak_supply:takeUnits(id, 'water', F.overrun.water, 'best'); exports.outbreak_supply:takeUnits(id, 'medicine', F.overrun.medicine, 'best')
    end)
    local lost = nil
    if m.residents > 0 and math.random() < F.overrun.residentLossChance then lost = (m.names or {})[1] or 'someone' end
    pcall(function() exports.outbreak_housing:damageBarricade(id, F.overrun.barricade) end)
    text = ('Overrun. Nobody on the door. Food, water and medicine gone%s. The barricade is down a level.'):format(lost and (', and ' .. lost .. ' with them') or '')
    pcall(function() exports.outbreak_supply:modify(id, { morale = F.overrun.morale, residents = lost and -1 or nil }, text) end)
    radio(line('overrun', m.label))
  end
  tell(keyholders(id), held and 'It held.' or 'Overrun.', text, held and 'success' or 'error')
  broadcastStage(id, 'over', { held = held })
  logDb(id, held and 'defense_held' or 'defense_overrun', text)
  defense[id] = nil
end
local function waveDefense(id)
  local e = defense[id]; if not e then return end
  local m = model(id); if not m then defense[id] = nil return end
  e.stage = 'wave'
  local kh = keyholders(id)
  local src = nearestPlayer(kh, m.door, D.ProbeRange)
  if src then pcall(function() exports.outbreak_core:fireEvent('horde', src, { size = e.size }) end) end
  radio(line('wave', m.label))
  slog(id, ('They are at the door. %d of them.'):format(e.size))
  tell(kh, 'They are at the door.', ('%d of them. Hold it for %d minutes.'):format(e.size, D.Defense.waveMinutes), 'error')
  broadcastStage(id, 'wave', { door = m.door, label = m.label, size = e.size, deadline = os.time() + D.Defense.waveMinutes * 60 })
  SetTimeout(D.Defense.waveMinutes * 60000, function() resolveDefense(id) end)
end
local function startDefense(m, kh)
  if defense[m.id] then return nil end
  local F = D.Defense
  local size = math.max(F.minSize, math.min(F.maxSize, F.baseSize + m.residents * F.perResident + (m.barricade or 0) * F.perBarricade))
  defense[m.id] = { stage = 'warning', deadline = os.time() + F.prepMinutes * 60, size = size }
  radio(line('probe', m.label))
  slog(m.id, ('Movement on the road. %d minutes to get ready.'):format(F.prepMinutes))
  tell(kh, ('They are coming to %s.'):format(m.label), ('%d minutes. Barricade, put rounds in the stockpile, and be at the door.'):format(F.prepMinutes), 'error')
  broadcastStage(m.id, 'warning', { door = m.door, label = m.label, deadline = defense[m.id].deadline, size = size })
  SetTimeout(F.prepMinutes * 60000, function() waveDefense(m.id) end)
  return ('defense: %d in %d min'):format(size, F.prepMinutes)
end
Actions.probe = function(m, kh) return startDefense(m, kh) end
exports('defend', function(id) local m = model(id); if not m then return false end; return startDefense(m, keyholders(id)) ~= nil end)
Actions.unrest = function(m, kh) local t = line('unrest', m.label); tell(kh, 'Word from home', t, 'inform'); slog(m.id, t); return t end
Actions.trader = function(m) local t = line('trader', m.label); radio(t); slog(m.id, 'Overheard: ' .. t); return t end

local function evaluate()
  local settlements = {}
  pcall(function() settlements = exports.outbreak_supply:settlements() or {} end)
  if #settlements == 0 then
    if cd('*', 'safehouse') then
      local free = {}
      for _, h in ipairs(exports.outbreak_housing:houses() or {}) do
        local hh = exports.outbreak_housing:getHouse(h.id)
        if not (hh and hh.owner) then free[#free + 1] = h end
      end
      if #free > 0 then local h = free[math.random(#free)]; local t = line('safehouse', h.label); radio(t); mark('*', 'safehouse'); logDb('*', 'safehouse', t) end
    end
    return
  end
  for _, m in ipairs(settlements) do
    local kh = {}
    pcall(function() kh = exports.outbreak_supply:keyholders(m.id) or {} end)
    if #kh > 0 then
      local c = {}
      local function add(a, w) if (w or 0) > 0 and cd(m.id, a) then c[#c + 1] = { a = a, w = w } end end
      local food, med = m.stock.food, m.stock.medicine
      local fed = (m.residents == 0 and food.units >= 4) or (food.days ~= nil and food.days >= 2)
      if m.residents < m.targetResidents and fed and m.morale >= 45 then add('stranger', W('stranger')) end
      if food.status == 'critical' or food.status == 'low' then add('rumor_food', W('rumor_food')) end
      if med.status == 'critical' or med.status == 'low' then add('rumor_medicine', W('rumor_medicine')) end
      local inTide = false
      do local t = GlobalState.obTide; if t and t.pos and m.door and #(m.door - t.pos) <= (t.radius or 0) then inTide = true end end
      if m.residents > 0 and ((m.barricade or 0) < 1 or m.stock.ammo.status ~= 'good' or inTide) then add('probe', D.Weights.probe * (inTide and (D.Tide and D.Tide.probeWeightMult or 3) or 1)) end
      if m.residents > 0 and m.morale < 30 then add('unrest', W('unrest')) end
      if m.allGood then add('trader', W('trader')); add('quiet', W('quiet')) end
      add('nothing', D.Weights.nothing)
      local a = pick(c)
      if a and Actions[a] then
        local detail = Actions[a](m, kh)
        if detail then mark(m.id, a); logDb(m.id, a, detail) end
      elseif a then
        mark(m.id, a)
      end
    end
  end
end

-- ── THE TIDE ──
local function zoneLabel(id) return (tostring(id):gsub('_', ' ')) end
local function moveTide()
  local T = D.Tide; if not T or not T.enabled then return end
  local cur = GlobalState.obTide
  local cands = {}
  for _, z in ipairs(OutbreakCfg.HotZones or {}) do
    if (z.mult or 1) >= T.minZoneMult and not (cur and cur.zone == z.id) then cands[#cands + 1] = z end
  end
  if #cands == 0 then return end
  local z = cands[math.random(#cands)]
  GlobalState.obTide = { zone = z.id, pos = z.pos, radius = z.radius, mult = T.mult, at = os.time() }
  radio(line('tide', zoneLabel(z.id)))
  logDb('*', 'tide', z.id)
end
exports('tideAt', function() return GlobalState.obTide end)
RegisterCommand('ob_tide', function(src)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.debug') then return end
  moveTide()
  local t = GlobalState.obTide
  if src ~= 0 then TriggerClientEvent('ox_lib:notify', src, { title = 'The Tide moved.', description = t and zoneLabel(t.zone) or '-', type = 'inform' }) end
end, false)

CreateThread(function()
  Wait(6000)
  if D.Tide and D.Tide.enabled then
    pcall(function() exports.outbreak_core:scheduleEvent('tide', D.Tide.everyMinutes[1], D.Tide.everyMinutes[2], moveTide) end)
    SetTimeout(90000, function() if not GlobalState.obTide then moveTide() end end)   -- first placement soon after boot, once someone is on
  end
  local ok = pcall(function() exports.outbreak_core:scheduleEvent('director', D.EveryMinutes[1], D.EveryMinutes[2], evaluate) end)
  if not ok then print('^1[outbreak_director] outbreak_core:scheduleEvent unavailable - the Director will not run^7') end
end)

-- the stranger, resolved
RegisterNetEvent('outbreak:director:takeIn', function(id)
  local src = source; local e = pending[id]; if not e then return end
  if os.time() > e.expires then pending[id] = nil return end
  local ok, k = pcall(function() return exports.outbreak_housing:hasKey(src, e.house) end); if not ok or not k then return end
  local hc = houseCfg(e.house); if not hc or #(GetEntityCoords(GetPlayerPed(src)) - hc.door) > 20.0 then return end
  pending[id] = nil
  local name = exports.outbreak_supply:addResident(e.house)
  TriggerClientEvent('outbreak:director:strangerResolved', src, id, true)
  TriggerClientEvent('ox_lib:notify', src, { title = name .. ' moves in.', description = 'One more mouth. One more pair of hands.', type = 'success', duration = 8000 })
  logDb(e.house, 'took_in', name)
end)
RegisterNetEvent('outbreak:director:sendAway', function(id)
  local src = source; local e = pending[id]; if not e then return end
  pending[id] = nil
  TriggerClientEvent('outbreak:director:strangerResolved', src, id, false)
  slog(e.house, 'You turned someone away at the door.')
  logDb(e.house, 'sent_away', '')
end)

exports('evaluate', evaluate)
-- admin suite: run ONE action at ONE settlement now (`trigger encounter <action> [house]`)
exports('runAction', function(action, houseId)
  local fn = Actions[action]; if not fn then return false, 'unknown action' end
  local id = houseId
  if not id then pcall(function() for k in pairs(exports.outbreak_supply:settlements() or {}) do id = k break end end) end
  if not id then return false, 'no settlement' end
  local m = model(id); if not m then return false, 'no model for ' .. tostring(id) end
  local ok, res = pcall(fn, m, keyholders(id))
  if ok then mark(id, action); logDb(id, action, tostring(res)) end
  return ok, ok and (res or 'ran') or tostring(res)
end)
RegisterCommand('ob_defend', function(src, args)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.debug') then return end
  local id = args[1]; if not id then return end
  local ok = exports.outbreak_director:defend(id)
  if src ~= 0 then TriggerClientEvent('ox_lib:notify', src, { title = ok and ('Defense event started at ' .. id) or 'No such settlement, or one is already running.', type = ok and 'inform' or 'error' }) end
end, false)
-- debug: force a pass (ace outbreak.debug, or the console)
RegisterCommand('ob_director', function(src)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.debug') then return end
  evaluate()
  if src ~= 0 then TriggerClientEvent('ox_lib:notify', src, { title = 'Director pass run.', description = 'See the ledger / console.', type = 'inform' }) end
end, false)
