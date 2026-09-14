-- outbreak_director/server/director.lua
-- One pass every 30-60 minutes. For each settlement with a keyholder online: read the model,
-- score the possible nudges, pick ONE, do it, log it. Everything it touches goes through the
-- owning resource's exports (supply for residents/morale/log, core for hordes, radio for words).
local D = DirectorCfg
local last, pending, nextId = {}, {}, 1

local function cd(house, a) return os.time() - (last[house .. ':' .. a] or 0) >= (D.Cooldowns[a] or 0) * 60 end
local function mark(house, a) last[house .. ':' .. a] = os.time() end
local function logDb(house, action, detail)
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
Actions.probe = function(m, kh)
  local src = nearestPlayer(kh, m.door, D.ProbeRange)
  radio(line('probe', m.label))
  if src then pcall(function() exports.outbreak_core:fireEvent('horde', src, { size = D.ProbeSize }) end) end
  local spent = 0
  if m.residents > 0 then pcall(function() spent = exports.outbreak_supply:takeUnits(m.id, 'ammo', m.residents * 2, 'scraps') or 0 end) end
  local held = spent > 0 or (m.barricade or 0) >= 2
  local text = held and ('They tested the door. %d rounds spent. It held.'):format(math.floor(spent)) or 'They tested the door. Nobody had rounds to spare. It barely held.'
  pcall(function() exports.outbreak_supply:modify(m.id, { morale = held and D.ProbeMorale.held or D.ProbeMorale.failed }, text) end)
  return text
end
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
      if m.residents < m.targetResidents and fed and m.morale >= 45 then add('stranger', D.Weights.stranger) end
      if food.status == 'critical' or food.status == 'low' then add('rumor_food', D.Weights.rumor_food) end
      if med.status == 'critical' or med.status == 'low' then add('rumor_medicine', D.Weights.rumor_medicine) end
      if m.residents > 0 and ((m.barricade or 0) < 1 or m.stock.ammo.status ~= 'good') then add('probe', D.Weights.probe) end
      if m.residents > 0 and m.morale < 30 then add('unrest', D.Weights.unrest) end
      if m.allGood then add('trader', D.Weights.trader); add('quiet', D.Weights.quiet) end
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

CreateThread(function()
  Wait(6000)
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
-- debug: force a pass (ace outbreak.debug, or the console)
RegisterCommand('ob_director', function(src)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.debug') then return end
  evaluate()
  if src ~= 0 then TriggerClientEvent('ox_lib:notify', src, { title = 'Director pass run.', description = 'See the ledger / console.', type = 'inform' }) end
end, false)
