-- outbreak_needs/server/needs.lua — AUTHORITATIVE CHARACTER STATE
local QBCore = exports['qb-core']:GetCoreObject()
local S = {}          -- src -> state
local lastWound = {}  -- src -> ms

local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
local function fresh() return { hunger = 100.0, thirst = 100.0, fatigue = 100.0, infected = false, infectedAt = nil, wounds = {} } end

local function push(src)
  TriggerClientEvent('outbreak:client:needsState', src, S[src])
  Player(src).state:set('needs', { hunger = S[src].hunger, thirst = S[src].thirst, fatigue = S[src].fatigue, infected = S[src].infected, bleeding = S[src].bleeding }, true)
end

local function save(src)
  local id = cid(src); if not id or not S[src] then return end
  MySQL.prepare('INSERT INTO outbreak_needs (citizenid, data) VALUES (?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)', { id, json.encode(S[src]) })
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
  local src = player.PlayerData.source
  local row = MySQL.single.await('SELECT data FROM outbreak_needs WHERE citizenid = ?', { player.PlayerData.citizenid })
  S[src] = row and json.decode(row.data) or fresh()
  S[src].wounds = S[src].wounds or {}
  TriggerClientEvent('outbreak:client:loadNeeds', src, S[src])
  push(src)
end)
AddEventHandler('playerDropped', function() save(source); S[source] = nil end)
AddEventHandler('outbreak:server:flush', function(src) if S[src] then save(src) end end)   -- pre-restart nudge (outbreak_log)
CreateThread(function() while true do Wait(60000) for src in pairs(S) do save(src) end end end)

local function bleeding(st)
  local b = 0
  for _, w in pairs(st.wounds) do if not w.treated then b = b + (NeedsCfg.WoundTypes[w.kind] and NeedsCfg.WoundTypes[w.kind].bleed or 0) end end
  return b
end

-- the decay tick: client reports factors, server applies rules
RegisterNetEvent('outbreak:server:needsTick', function(f)
  local src = source; local st = S[src]; if not st then return end
  local mult = (f and f.sprinting) and NeedsCfg.SprintMultiplier or 1.0
  local hm, tm, fm = 1.0, 1.0, 1.0
  pcall(function()
    local T = exports.outbreak_skills
    if T:hasTrait(src, 'light_eater') then hm = 0.7 end
    if T:hasTrait(src, 'camel') then tm = 0.7 end
    if T:hasTrait(src, 'heavy_sleeper') then fm = 1.4 end
  end)
  st.hunger  = math.max(0, st.hunger  - NeedsCfg.Decay.hunger  * mult * hm)
  st.thirst  = math.max(0, st.thirst  - NeedsCfg.Decay.thirst  * mult * tm)
  st.fatigue = math.max(0, st.fatigue - NeedsCfg.Decay.fatigue * mult * fm)
  local dmg = 0
  if st.hunger <= 0 or st.thirst <= 0 then dmg = dmg + NeedsCfg.StarveDamage end
  dmg = dmg + bleeding(st)
  if st.infected and st.infectedAt then
    local hours = (os.time() - st.infectedAt) / 3600
    for _, s in ipairs(NeedsCfg.Infection.stages) do if hours >= s.after then dmg = dmg + s.fxDamage end end
  end
  st.bleeding = bleeding(st) > 0
  if dmg > 0 then
    -- SetEntityHealth is a client-only native. The server stays authoritative for the
    -- amount (starvation + bleed + infection stage); the client is the effector.
    TriggerClientEvent('outbreak:client:survivalDamage', src, dmg)
  end
  push(src)
end)

-- wounds: client-detected, server-stored, rate-limited
RegisterNetEvent('outbreak:server:wound', function(part, kind)
  local src = source; local st = S[src]; if not st then return end
  local now = GetGameTimer()
  if lastWound[src] and now - lastWound[src] < NeedsCfg.WoundRateLimitMs then return end
  lastWound[src] = now
  local def = NeedsCfg.WoundTypes[kind]; if not def then return end
  local valid = false
  for _, p in ipairs(NeedsCfg.Parts) do if p == part then valid = true end end
  if not valid then return end
  if def.legOnly and not part:find('leg') then kind = 'laceration'; def = NeedsCfg.WoundTypes[kind] end
  local existing = st.wounds[part]
  local function sev(k) return (NeedsCfg.WoundTypes[k] or {}).severity or 0 end
  if existing and not existing.treated and sev(existing.kind) >= (def.severity or 0) then return end -- worse (or equal) wound already there
  st.wounds[part] = { kind = kind, treated = false, at = os.time(), dirty = def.dirty or nil }
  st.bleeding = bleeding(st) > 0
  TriggerClientEvent('ox_lib:notify', src, { title = def.label .. ' — ' .. part:gsub('_', ' '), description = def.bleed > 0 and 'You\'re bleeding.' or (kind == 'bruise' and 'That will bruise.') or 'It won\'t take weight.', type = 'error' })
  push(src)
end)

local function infect(src, why)
  local st = S[src]; if not st or st.infected then return end
  st.infected = true; st.infectedAt = os.time()
  TriggerClientEvent('ox_lib:notify', src, { title = 'The wound burns.', description = why or 'You don\'t feel right.', type = 'error' })
  push(src)
end
RegisterNetEvent('outbreak:server:infect', function()
  local src = source; local st = S[src]; if not st or st.infected then return end
  infect(src)
  push(src)
end)

-- consume: ONLY called by outbreak_items server after it removed the item
local function consume(src, effects)
  local st = S[src]; if not st then return false end
  for k, v in pairs(effects) do
    if type(st[k]) == 'number' then st[k] = math.max(0, math.min(100, st[k] + v)) end
  end
  if effects.antibiotics and st.infectedAt then
    local cureH = tonumber((GlobalState.obTune or {})['infection.cureWithinHours']) or NeedsCfg.Infection.cureWithinHours
    if os.time() - st.infectedAt < cureH * 3600 then
      st.infected = false; st.infectedAt = nil
      TriggerClientEvent('ox_lib:notify', src, { title = 'Caught it early.', description = 'The fever never comes.', type = 'success', duration = 6000 })
    else
      st.infectedAt = st.infectedAt + NeedsCfg.Infection.antibioticsSlowHours * 3600
      TriggerClientEvent('ox_lib:notify', src, { title = 'Too late to cure. It slows.', description = ('Bought about %d hours.'):format(NeedsCfg.Infection.antibioticsSlowHours), type = 'inform', duration = 6000 })
    end
  end
  push(src)
  return true
end
exports('consume', consume)

-- SLEEP. Client runs the fade and the wake conditions; the server holds the clock and pays out
-- by elapsed time, so a client cannot claim a full night from a two-second nap.
local sleeping = {}
RegisterNetEvent('outbreak:server:sleep', function(houseId, phase)
  local src = source
  local Sl = NeedsCfg.Sleep
  if phase == 'start' then
    local ok, k = pcall(function() return exports.outbreak_housing:hasKey(src, houseId) end)
    if not ok or not k then TriggerClientEvent('ox_lib:notify', src, { title = 'Not your bed.', type = 'error' }) return end
    sleeping[src] = os.time()
    Player(src).state:set('sleeping', true, true)
  elseif phase == 'stop' and sleeping[src] then
    local frac = math.max(0, math.min(1, (os.time() - sleeping[src]) / Sl.seconds))
    sleeping[src] = nil
    Player(src).state:set('sleeping', nil, true)
    consume(src, { fatigue = Sl.fatigueGain * frac, hunger = -Sl.hungerCost * frac, thirst = -Sl.thirstCost * frac })
    save(src)
  end
end)
AddEventHandler('playerDropped', function() sleeping[source] = nil end)

-- treat: item validated + removed by outbreak_items; here we change the body
local function treatWound(src, part, item)
  local st = S[src]; if not st then return false end
  local w = st.wounds[part]; if not w or w.treated then return false end
  local def = NeedsCfg.WoundTypes[w.kind]
  local ok = false
  for _, t in ipairs(def.treat) do if t == item then ok = true end end
  if not ok then return false end
  w.treated = true; w.treatedWith = item; w.dirty = nil
  st.bleeding = bleeding(st) > 0
  push(src)
  return true
end
exports('treatWound', treatWound)

-- wound heals fully some hours after treatment (cleanup on tick)
CreateThread(function()
  while true do
    Wait(120000)
    for src, st in pairs(S) do
      local changed = false
      for part, w in pairs(st.wounds) do
        if w.treated and os.time() - (w.at or 0) > 3 * 3600 then st.wounds[part] = nil; changed = true end
        -- a dirty wound left open long enough turns: the infection comes from the wound, not the bite
        local dirtyM = tonumber((GlobalState.obTune or {})['infection.dirtyMinutes']) or NeedsCfg.Infection.dirtyMinutes or 20
        if w.dirty and not w.treated and not st.infected and os.time() - (w.at or 0) > dirtyM * 60 then
          w.dirty = nil; infect(src, ('The %s on your %s has gone bad.'):format((NeedsCfg.WoundTypes[w.kind] or {}).label or 'wound', part:gsub('_', ' '))); changed = false
        end
      end
      if changed then push(src) end
    end
  end
end)

exports('getNeeds', function(src) return S[src] end)
exports('getWounds', function(src) return S[src] and S[src].wounds or {} end)
exports('reset', function(src) S[src] = fresh(); push(src); save(src) end)

-- resting (emote-driven): rate-limited fatigue recovery
local lastRest = {}
RegisterNetEvent('outbreak:server:rest', function()
  local src = source; local st = S[src]; if not st then return end
  if lastRest[src] and GetGameTimer() - lastRest[src] < 4500 then return end
  lastRest[src] = GetGameTimer()
  st.fatigue = math.min(100, st.fatigue + 1.2); push(src)
end)
