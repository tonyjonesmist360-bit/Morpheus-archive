-- outbreak_supply/server/supply.lua
-- AUTHORITATIVE for: residents, morale, the settlement log, the consumption/spoilage tick, cooking.
-- NOT authoritative for stock: the stockpile IS the house stash (ox_inventory owns it); we read
-- it and remove from it, never mirror it. Housing owns claim/keys/barricade; we read those via
-- its exports. One server tick, scheduled through outbreak_core so it only runs with players on.
local QBCore = exports['qb-core']:GetCoreObject()
local C = SupplyCfg
local S = {}              -- house_id -> { residents, morale, names, debt, flags, log, lastTick }
local hotMealAt = {}      -- house_id -> os.time() of the last hot-meal morale bonus
local houseList = nil

local function now() return os.time() end
local function clamp(v) return math.max(C.Morale.min, math.min(C.Morale.max, v)) end
local function stashOf(id) return 'safehouse_' .. id end
local function houses() if not houseList then houseList = exports.outbreak_housing:houses() or {} end return houseList end
local function houseCfg(id) for _, h in ipairs(houses()) do if h.id == id then return h end end end
local function house(id) local ok, h = pcall(function() return exports.outbreak_housing:getHouse(id) end); return ok and h or nil end
local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
local function nameOf(src)
  local p = QBCore.Functions.GetPlayer(src)
  local ci = p and p.PlayerData.charinfo
  return (ci and ci.firstname) or 'someone'
end
local function notify(src, title, kind, desc) TriggerClientEvent('ox_lib:notify', src, { title = title, description = desc, type = kind or 'inform', duration = 8000 }) end

-- ── persistence ──
local function fresh() return { residents = 0, morale = C.Morale.start, names = {}, debt = {}, flags = {}, log = {}, lastTick = 0 } end
local function dec(s, d) if type(s) ~= 'string' or s == '' then return d end local ok, v = pcall(json.decode, s); return (ok and type(v) == 'table') and v or d end
CreateThread(function()
  local rows = MySQL.query.await('SELECT * FROM outbreak_settlements') or {}
  for _, r in ipairs(rows) do
    S[r.house_id] = { residents = r.residents or 0, morale = r.morale or C.Morale.start, names = dec(r.names, {}), debt = dec(r.debt, {}),
                      flags = dec(r.flags, {}), log = dec(r.log, {}), lastTick = r.last_tick or 0 }
  end
end)
local function save(id)
  local s = S[id]; if not s then return end
  MySQL.prepare([[INSERT INTO outbreak_settlements (house_id, residents, morale, names, debt, flags, log, last_tick) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ON DUPLICATE KEY UPDATE residents=VALUES(residents), morale=VALUES(morale), names=VALUES(names), debt=VALUES(debt), flags=VALUES(flags), log=VALUES(log), last_tick=VALUES(last_tick)]],
    { id, s.residents, math.floor(s.morale), json.encode(s.names), json.encode(s.debt), json.encode(s.flags), json.encode(s.log), s.lastTick })
end
local function get(id) if not S[id] then S[id] = fresh() end return S[id] end
local function logIt(id, text)
  local s = get(id)
  table.insert(s.log, 1, { at = now(), text = text })
  while #s.log > C.LogMax do table.remove(s.log) end
  if GlobalState.obDebug then print(('^5[OB-SUPPLY]^7 %s: %s'):format(id, text)) end
end

-- ── who is home ──
local function keyholders(id)
  local out = {}
  for _, p in ipairs(GetPlayers()) do
    local src = tonumber(p)
    local ok, k = pcall(function() return exports.outbreak_housing:hasKey(src, id) end)
    if ok and k then out[#out + 1] = src end
  end
  return out
end
local function homeOf(src)
  local me = cid(src); if not me then return nil end
  local first
  for _, hc in ipairs(houses()) do
    local h = house(hc.id)
    if h and h.owner then
      if h.owner == me then return hc.id end
      if not first then local ok, k = pcall(function() return exports.outbreak_housing:hasKey(src, hc.id) end); if ok and k then first = hc.id end end
    end
  end
  return first
end
local function notifyHome(id, title, kind, desc) for _, src in ipairs(keyholders(id)) do notify(src, 'Word from home: ' .. title, kind, desc) end end

-- ── the stockpile, read ──
local function stock(id)
  local units = {}; for _, c in ipairs(C.Categories) do units[c] = 0 end
  local byItem, unboiled = {}, 0
  local items = exports.ox_inventory:GetInventoryItems(stashOf(id)) or {}
  for _, it in pairs(items) do
    if type(it) == 'table' and it.name and (it.count or 0) > 0 then
      byItem[it.name] = (byItem[it.name] or 0) + it.count
      local v = C.Value[it.name]
      if v then for c, u in pairs(v) do units[c] = (units[c] or 0) + u * it.count end end
      if C.Unboiled[it.name] then unboiled = unboiled + it.count end
    end
  end
  return units, byItem, unboiled
end

-- Remove items worth >= `amount` units of `cat` from the stockpile. 'scraps' eats the soon-to-spoil
-- and lowest-value first (residents); 'best' takes the good stuff (someone leaving). Returns units taken.
local function takeUnits(id, cat, amount, prefer)
  local _, byItem = stock(id)
  local cands = {}
  for name, n in pairs(byItem) do
    local v = C.Value[name]
    if v and (v[cat] or 0) > 0 then cands[#cands + 1] = { name = name, n = n, u = v[cat], spoils = C.Spoil[name] ~= nil } end
  end
  if prefer == 'best' then table.sort(cands, function(a, b) return a.u > b.u end)
  else table.sort(cands, function(a, b) if a.spoils ~= b.spoils then return a.spoils end return a.u < b.u end) end
  local taken = 0
  for _, c in ipairs(cands) do
    while taken < amount and c.n > 0 do
      if exports.ox_inventory:RemoveItem(stashOf(id), c.name, 1) then taken = taken + c.u; c.n = c.n - 1 else break end
    end
    if taken >= amount then break end
  end
  return taken
end

-- ── the read-model ──
local function statusOf(units, perDay, reserve)
  if perDay > 0 then
    local days = units / perDay
    local st = days < 0.75 and 'critical' or days < 1.5 and 'low' or days < C.TargetDays and 'ok' or 'good'
    return st, days, math.max(0, math.ceil(C.TargetDays * perDay - units)), math.min(100, math.floor(days / C.TargetDays * 100))
  end
  local st = units <= 0 and 'critical' or units < reserve * 0.5 and 'low' or units < reserve and 'ok' or 'good'
  return st, nil, math.max(0, math.ceil(reserve - units)), math.min(100, reserve > 0 and math.floor(units / reserve * 100) or 100)
end
local RANK = { critical = 0, low = 1, info = 2, ok = 3, good = 4 }

local function model(id, forSrc)
  local h = house(id); local hc = houseCfg(id)
  if not h or not h.owner or not hc then return nil end
  local s = get(id)
  local units, byItem, unboiled = stock(id)
  local kh = keyholders(id)
  local scale = math.max(1, #kh)
  local stockOut, needs = {}, {}
  local allGood = true
  for _, c in ipairs(C.Categories) do
    local perDay = (C.PerResidentPerDay[c] or 0) * s.residents
    local reserve = (C.Reserve[c] or 0) * scale
    local st, days, ask, pct = statusOf(units[c], perDay, reserve)
    if s.residents == 0 and st == 'critical' then st = 'low' end
    if st == 'critical' or st == 'low' then allGood = false end
    stockOut[c] = { units = math.floor(units[c] * 10) / 10, days = days and math.floor(days * 10) / 10 or nil, status = st, ask = ask, pct = pct, label = C.Labels[c], unit = C.Units[c] }
    if st == 'critical' or st == 'low' then
      local left = days and (days < 0.05 and 'empty' or ('%.1f days left'):format(days)) or ('%d of %d %s'):format(math.floor(units[c]), reserve, C.Units[c])
      needs[#needs + 1] = { cat = c, status = st, text = ('%s: %s. Bring %d %s.'):format(C.Labels[c], left, ask, C.Units[c]) }
    end
  end
  if unboiled > 0 then needs[#needs + 1] = { cat = 'water', status = 'info', text = ('Water: %d unboiled. Boil it at the door.'):format(unboiled) } end
  local ammoNeed = math.max(10, s.residents * 10)
  if (h.barricade or 0) < 1 then needs[#needs + 1] = { cat = 'defense', status = s.residents > 0 and 'low' or 'info', text = 'Defense: no barricade. Hammer, 2 planks, 1 nails at the door.' } end
  if units.ammo < ammoNeed then needs[#needs + 1] = { cat = 'defense', status = s.residents > 0 and 'low' or 'info', text = ('Defense: %d rounds short of %d.'):format(math.ceil(ammoNeed - units.ammo), ammoNeed) } end
  if s.residents < C.TargetResidents then
    local room = C.TargetResidents - s.residents
    needs[#needs + 1] = { cat = 'people', status = 'info', text = ('People: room for %d. Strangers come to a fed house.'):format(room) }
  end
  if s.residents > 0 and units.comfort < s.residents * 0.5 and s.morale < 50 then needs[#needs + 1] = { cat = 'comfort', status = 'info', text = 'Someone is asking for a beer. Or chocolate. Anything.' } end
  table.sort(needs, function(a, b) return (RANK[a.status] or 9) < (RANK[b.status] or 9) end)
  -- recipes: can we cook it right now?
  local recipes = {}
  for _, rid in ipairs(C.RecipeOrder) do
    local r = C.Recipes[rid]; local missing = {}
    for name, n in pairs(r.inp) do if (byItem[name] or 0) < n then missing[#missing + 1] = ('%d %s'):format(n, name:gsub('_', ' ')) end end
    local fuelOk = (r.fuel or 0) == 0
    for _, f in ipairs(C.FuelItems) do if (byItem[f] or 0) >= (r.fuel or 0) then fuelOk = true end end
    if not fuelOk then missing[#missing + 1] = 'fuel' end
    local outs = {}; for name, n in pairs(r.out) do outs[#outs + 1] = ('%d %s'):format(n, name:gsub('_', ' ')) end
    recipes[#recipes + 1] = { id = rid, label = r.label, seconds = r.seconds, can = #missing == 0, missing = table.concat(missing, ', '), makes = table.concat(outs, ', ') }
  end
  local last = s.log[1]
  return {
    id = id, label = hc.label, door = hc.door, owner = h.owner, mine = forSrc and (h.owner == cid(forSrc)) or false,
    barricade = h.barricade or 0, residents = s.residents, targetResidents = C.TargetResidents, names = s.names, morale = math.floor(s.morale),
    stock = stockOut, needs = needs, recipes = recipes, allGood = allGood and s.residents > 0, unboiled = unboiled,
    log = s.log, lastLine = last and last.text or nil, starving = (s.flags.food_out or 0) >= 2, keyholdersOnline = #kh, lastTick = s.lastTick,
  }
end

local function push(id)
  for _, src in ipairs(keyholders(id)) do
    local m = model(id, src)
    if m then TriggerClientEvent('outbreak:supply:update', src, m) end
  end
end

-- ── the tick: spoilage, consumption, morale, behaviour ──
local function behaviours(id, s)
  local M = C.Morale; local hc = houseCfg(id)
  if s.morale < M.leaving.below and math.random() < M.leaving.chance then
    local who = #s.names > 0 and table.remove(s.names, math.random(#s.names)) or 'someone'
    s.residents = math.max(0, s.residents - 1)
    takeUnits(id, 'food', 1.5, 'best'); takeUnits(id, 'water', 1, 'best'); takeUnits(id, 'medicine', 1, 'best')
    local text = C.Notes.leaving[math.random(#C.Notes.leaving)]:format(who)
    if hc then pcall(function() exports.outbreak_worlditems:placeSystem('note', 1, { text = text }, hc.door + vector3(0.8, 0.8, 0.0), vector3(0.0, 0.0, 0.0), who) end) end
    logIt(id, ('%s left in the night with food, water and a bandage. There is a note at the door.'):format(who))
    notifyHome(id, ('%s is gone.'):format(who), 'error', 'There is a note at the door.')
    s.morale = clamp(s.morale + M.leaving.othersMorale)
    return
  end
  if s.morale < M.drinking.below and math.random() < M.drinking.chance then
    local got = takeUnits(id, 'comfort', M.drinking.takes, 'best')
    if got > 0 then
      logIt(id, ('Someone drank through the comfort stock. %d gone.'):format(math.floor(got + 0.5)))
      notifyHome(id, 'Empty bottles by the door.', 'inform', 'Someone had a bad night.')
      s.morale = clamp(s.morale + M.drinking.morale)
      return
    end
  end
  if s.morale < M.dispute.below and math.random() < M.dispute.chance then
    local a, b = s.names[1] or 'someone', s.names[2] or 'someone else'
    local got = takeUnits(id, 'materials', 1, 'scraps')
    logIt(id, ('%s and %s fought over the last of it.%s'):format(a, b, got > 0 and ' A chair is kindling now.' or ''))
    notifyHome(id, 'Shouting at home.', 'inform', got > 0 and 'Something broke.' or nil)
    s.morale = clamp(s.morale + M.dispute.morale)
  end
end

local function moraleTick(id, s)
  local M = C.Morale
  local m = model(id); if not m then return end
  local delta, fed = 0, true
  for _, c in ipairs({ 'food', 'water' }) do
    local st = m.stock[c].status
    if st == 'critical' then delta = delta - M.criticalPenalty; fed = false
    elseif st == 'low' then delta = delta - M.lowPenalty; fed = false end
  end
  if s.residents > 0 then
    if fed then delta = delta + M.fedBonus end
    if m.stock.comfort.units >= s.residents * 0.5 then delta = delta + M.comfortBonus end
    local out = s.flags.food_out or 0
    if out >= 2 then delta = delta - M.starvingPenalty end
    if out >= M.starvingTicksToDeath then
      local who = #s.names > 0 and table.remove(s.names, 1) or 'someone'
      s.residents = math.max(0, s.residents - 1); s.flags.food_out = 2
      logIt(id, ('%s starved. Buried behind the house.'):format(who))
      notifyHome(id, ('%s starved.'):format(who), 'error')
      delta = delta - M.residentDied
    end
    if s.residents > 0 then behaviours(id, s) end
  end
  s.morale = clamp(s.morale + delta)
end

local function tick()
  local dtDays = C.TickMinutes / 1440
  for _, hc in ipairs(houses()) do
    local h = house(hc.id)
    if h and h.owner then
      local s = get(hc.id)
      s.lastTick = now()
      local _, byItem = stock(hc.id)
      for name, hours in pairs(C.Spoil) do
        local n = byItem[name] or 0
        if n > 0 then
          local expect = n * ((C.TickMinutes / 60) / hours)
          local lose = math.floor(expect); if math.random() < (expect - lose) then lose = lose + 1 end
          if lose > 0 and exports.ox_inventory:RemoveItem(stashOf(hc.id), name, lose) then logIt(hc.id, ('%d %s spoiled.'):format(lose, (name:gsub('_', ' ')))) end
        end
      end
      if s.residents > 0 then
        for cat, perDay in pairs(C.PerResidentPerDay) do
          local need = perDay * s.residents
          s.debt[cat] = math.min(need, (s.debt[cat] or 0) + need * dtDays)   -- never more than a day owed, so a restock is not eaten in one tick
          if s.debt[cat] >= 1 then
            local got = takeUnits(hc.id, cat, s.debt[cat], 'scraps')
            if got > 0 then s.debt[cat] = math.max(0, s.debt[cat] - got); s.flags[cat .. '_out'] = nil
            elseif cat == 'food' or cat == 'water' then s.flags[cat .. '_out'] = (s.flags[cat .. '_out'] or 0) + 1
            else s.debt[cat] = 0 end
          end
        end
      end
      moraleTick(hc.id, s)
      save(hc.id); push(hc.id)
    end
  end
end
CreateThread(function()
  Wait(5000)
  local ok = pcall(function() exports.outbreak_core:scheduleEvent('supplyTick', C.TickMinutes, C.TickMinutes, tick) end)
  if not ok then print('^1[outbreak_supply] outbreak_core:scheduleEvent unavailable - settlements will not tick^7') end
end)

-- ── residents ──
local function addResident(id, name)
  local s = get(id)
  if not name then
    local used = {}; for _, n in ipairs(s.names) do used[n] = true end
    local pool = {}; for _, n in ipairs(C.Names) do if not used[n] then pool[#pool + 1] = n end end
    name = #pool > 0 and pool[math.random(#pool)] or ('Survivor ' .. (s.residents + 1))
  end
  s.residents = s.residents + 1; s.names[#s.names + 1] = name
  s.morale = clamp(s.morale + C.Morale.residentJoined)
  logIt(id, ('%s moved in.'):format(name))
  save(id); push(id)
  return name
end

-- ── cooking (at the door, from the stockpile, into the stockpile) ──
RegisterNetEvent('outbreak:supply:cook', function(id, rid)
  local src = source
  local r = C.Recipes[rid]; local hc = houseCfg(id); if not r or not hc then return end
  local ok, k = pcall(function() return exports.outbreak_housing:hasKey(src, id) end); if not ok or not k then return end
  if #(GetEntityCoords(GetPlayerPed(src)) - hc.door) > C.DoorRange then return end
  local _, byItem = stock(id)
  for name, n in pairs(r.inp) do
    if (byItem[name] or 0) < n then notify(src, 'Missing: ' .. name:gsub('_', ' '), 'error') return end
  end
  local fuelItem
  if (r.fuel or 0) > 0 then
    for _, f in ipairs(C.FuelItems) do if (byItem[f] or 0) >= r.fuel then fuelItem = f break end end
    if not fuelItem then notify(src, 'Nothing to burn.', 'error', 'A plank or a fuel can in the stockpile.') return end
  end
  for name, n in pairs(r.inp) do exports.ox_inventory:RemoveItem(stashOf(id), name, n) end
  if fuelItem then exports.ox_inventory:RemoveItem(stashOf(id), fuelItem, r.fuel) end
  for name, n in pairs(r.out) do exports.ox_inventory:AddItem(stashOf(id), name, n) end
  local s = get(id)
  if r.hot and s.residents > 0 and now() - (hotMealAt[id] or 0) > C.Morale.hotMealCooldownMinutes * 60 then
    hotMealAt[id] = now(); s.morale = clamp(s.morale + (r.morale or 0))
    logIt(id, ('%s cooked %s. Everyone ate warm.'):format(nameOf(src), r.label:lower()))
  else
    logIt(id, ('%s cooked %s.'):format(nameOf(src), r.label:lower()))
  end
  notify(src, r.label .. ' done.', 'success', 'It is in the stockpile.')
  save(id); push(id)
end)

-- owner asks a resident to leave (no supplies taken, small morale cost)
RegisterNetEvent('outbreak:supply:dismiss', function(id, name)
  local src = source
  local h = house(id); if not h or h.owner ~= cid(src) then return end
  local s = get(id)
  for i, n in ipairs(s.names) do
    if n == name then
      table.remove(s.names, i); s.residents = math.max(0, s.residents - 1)
      s.morale = clamp(s.morale + C.Morale.turnedAway)
      logIt(id, ('%s asked %s to leave. They went quietly.'):format(nameOf(src), name))
      save(id); push(id); return
    end
  end
end)

-- ── surface ──
lib.callback.register('outbreak:supply:model', function(src, id) return model(id, src) end)
lib.callback.register('outbreak:supply:home', function(src) local id = homeOf(src); return id and model(id, src) or nil end)
RegisterNetEvent('outbreak:supply:hello', function() local src = source; local id = homeOf(src); if id then local m = model(id, src); if m then TriggerClientEvent('outbreak:supply:update', src, m) end end end)

exports('getSettlement', function(id) return model(id) end)
exports('settlements', function()
  local out = {}
  for _, hc in ipairs(houses()) do local m = model(hc.id); if m then out[#out + 1] = m end end
  return out
end)
exports('keyholders', keyholders)
exports('homeOf', homeOf)
exports('addResident', addResident)
exports('takeUnits', takeUnits)
exports('log', function(id, text) logIt(id, text); save(id); push(id) end)
exports('modify', function(id, d, reason)
  local s = get(id)
  if d.morale then s.morale = clamp(s.morale + d.morale) end
  if d.residents and d.residents < 0 then for _ = 1, -d.residents do if #s.names > 0 then table.remove(s.names) end end s.residents = math.max(0, s.residents + d.residents) end
  if reason then logIt(id, reason) end
  save(id); push(id)
end)
