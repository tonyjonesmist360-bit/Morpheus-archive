-- outbreak_radio/server/range.lua — RANGE MODEL. Server computes who can hear whom; clients only apply volumes.
local Rep = {}   -- id -> { active }
local Base = {}  -- citizenid -> pos (placed base stations)
local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
  for id, r in pairs(RadioCfg.Repeaters) do
    local row = MySQL.single.await('SELECT active FROM outbreak_repeaters WHERE repeater_id = ?', { id })
    Rep[id] = { active = row and row.active == 1 or (not row and r.defaultActive) }
  end
  for _, b in ipairs(MySQL.query.await('SELECT citizenid, x, y, z FROM outbreak_base_radios') or {}) do Base[b.citizenid] = vector3(b.x, b.y, b.z) end
  GlobalState.obRepeaters = Rep
end)

local function jobOf(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.job and p.PlayerData.job.name or 'unemployed' end
local function inRepeater(pos, r) return #(pos - r.pos) <= r.radius end

-- quality between a and b (positions), given the best equipment each side has and repeater coverage
local function quality(pa, pb, rangeA, rangeB, jobA, jobB)
  local best = 0.0
  -- direct
  local d = #(pa - pb)
  local range = math.max(rangeA, rangeB)
  if d <= range then
    best = 1.0 - (d / range) * 0.85
    best = best + math.abs(pa.z - pb.z) / 100.0 * RadioCfg.HeightBonusPer100m
  end
  -- repeaters
  for id, r in pairs(RadioCfg.Repeaters) do
    if Rep[id] and Rep[id].active and (not r.military or (jobA == 'military' and jobB == 'military')) then
      if inRepeater(pa, r) and inRepeater(pb, r) then best = math.max(best, r.quality) end
    end
  end
  local w = GlobalState.obWeather
  if w and RadioCfg.Weather[w] then best = best + RadioCfg.Weather[w] end
  return math.max(0.0, math.min(1.0, best))
end

local channels = {} -- src -> channel (reported by client heartbeat; trust gap, radio item required)
RegisterNetEvent('outbreak:radio:channel', function(ch)
  local src = source
  if type(ch) ~= 'number' then return end
  if ch > 0 and exports.ox_inventory:GetItemCount(src, 'radio_handheld') < 1 then ch = 0 end
  channels[src] = ch
end)
AddEventHandler('playerDropped', function() channels[source] = nil end)

local function rangeOf(src)
  local r = RadioCfg.Handheld.range
  local c = QBCore.Functions.GetPlayer(src); c = c and c.PlayerData.citizenid
  if c and Base[c] and #(GetEntityCoords(GetPlayerPed(src)) - Base[c]) < 30.0 then r = RadioCfg.Base.range end -- at your radio room
  return r
end

-- recompute reach matrix per channel every N seconds; push each player their own row as a statebag
CreateThread(function()
  while true do
    Wait(RadioCfg.RecomputeSeconds * 1000)
    local byCh = {}
    for src, ch in pairs(channels) do if ch > 0 then byCh[ch] = byCh[ch] or {}; table.insert(byCh[ch], src) end end
    local pos, rng, job = {}, {}, {}
    for _, list in pairs(byCh) do for _, s in ipairs(list) do pos[s] = GetEntityCoords(GetPlayerPed(s)); rng[s] = rangeOf(s); job[s] = jobOf(s) end end
    for _, list in pairs(byCh) do
      for _, a in ipairs(list) do
        local row = {}
        for _, b in ipairs(list) do if a ~= b then row[tostring(b)] = quality(pos[a], pos[b], rng[a], rng[b], job[a], job[b]) end end
        Player(a).state:set('radioReach', row, true)
      end
    end
  end
end)

-- quality from a world point to a player (server transmissions with an origin)
exports('qualityTo', function(src, origin, originRange)
  local p = GetEntityCoords(GetPlayerPed(src))
  return quality(p, origin, originRange or RadioCfg.Base.range, rangeOf(src), jobOf(src), 'none')
end)
exports('setRepeater', function(id, active, reason)
  if not RadioCfg.Repeaters[id] then return false end
  Rep[id] = { active = active }
  MySQL.prepare('INSERT INTO outbreak_repeaters (repeater_id, active) VALUES (?, ?) ON DUPLICATE KEY UPDATE active = VALUES(active)', { id, active and 1 or 0 })
  GlobalState.obRepeaters = Rep
  if GlobalState.obDebug then print(('^5[OB-RADIO]^7 repeater %s -> %s (%s)'):format(id, tostring(active), reason or '-')) end
  return true
end)
exports('isRepeaterActive', function(id) return Rep[id] and Rep[id].active or false end)
exports('placeBase', function(src, pos)
  local p = QBCore.Functions.GetPlayer(src); if not p then return false end
  Base[p.PlayerData.citizenid] = pos
  MySQL.prepare('INSERT INTO outbreak_base_radios (citizenid, x, y, z) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE x=VALUES(x), y=VALUES(y), z=VALUES(z)', { p.PlayerData.citizenid, pos.x, pos.y, pos.z })
  return true
end)
