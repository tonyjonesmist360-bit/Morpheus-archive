-- outbreak_core/server/director.lua
-- WORLD EVENTS SERVICE. Anything that "happens to the world" is scheduled here.
--   exports.outbreak_core:scheduleEvent(name, minMinutes, maxMinutes, handler)  -- handler(players) runs server-side
--   exports.outbreak_core:fireEvent(name, targetSrc, payload)                    -- TriggerClientEvent('outbreak:event:'..name)
local schedules = {}

local function fireEvent(name, target, payload)
  TriggerClientEvent('outbreak:event:' .. name, target or -1, payload)
  if GlobalState.obDebug then print(('^5[OB-EVENT]^7 %s -> %s'):format(name, tostring(target or 'all'))) end
end

-- schedules[name] = { min, max } minutes, re-read every loop so `rescheduleEvent` (outbreak_tuning) lands
-- on the next wait without a restart. A change shorter than the wait in progress applies after it.
local function scheduleEvent(name, minM, maxM, handler)
  schedules[name] = { min = minM, max = maxM }
  CreateThread(function()
    while schedules[name] do
      local s = schedules[name]
      local lo, hi = math.floor(tonumber(s.min) or minM), math.floor(tonumber(s.max) or maxM)
      if hi < lo then hi = lo end
      Wait(math.random(math.max(1, lo), math.max(1, hi)) * 60000)
      local players = GetPlayers()
      if #players > 0 and schedules[name] then handler(players) end
    end
  end)
end

exports('scheduleEvent', scheduleEvent)
exports('rescheduleEvent', function(name, minM, maxM) local s = schedules[name]; if not s then return false end; s.min, s.max = minM or s.min, maxM or s.max; return true end)
exports('schedules', function() local out = {}; for k, s in pairs(schedules) do out[k] = { min = s.min, max = s.max } end; return out end)
exports('fireEvent', fireEvent)
exports('cancelEvent', function(name) schedules[name] = nil end)

-- ── POOLS (v0.25): zones with a fixed population. Kills are counted here; the client only reports. ──
local Pools = {}
local function savePools() SaveResourceFile(GetCurrentResourceName(), 'pools.json', json.encode(Pools), -1) end
local function publishPools() GlobalState.obPool = Pools end
do
  local ok, saved = pcall(json.decode, LoadResourceFile(GetCurrentResourceName(), 'pools.json') or '')
  for _, z in ipairs(OutbreakCfg.HotZones or {}) do
    if z.pool then
      local s = ok and type(saved) == 'table' and saved[z.id] or nil
      Pools[z.id] = { left = s and s.left or z.pool, total = z.pool, label = z.label or z.id }
    end
  end
  publishPools()
end
local lastPoolKill = {}
RegisterNetEvent('outbreak:pool:kill', function(id)
  local src = source; local p = Pools[id]; if not p or p.left <= 0 then return end
  local now = GetGameTimer(); if lastPoolKill[src] and now - lastPoolKill[src] < 250 then return end
  lastPoolKill[src] = now
  p.left = p.left - 1
  if p.left % 10 == 0 or p.left <= 5 then publishPools() end
  if p.left == 0 then
    publishPools(); savePools()
    print(('^5[OB-POOL]^7 %s is CLEAR'):format(p.label))
    pcall(function() exports.outbreak_radio:transmit(0, 'OVERHEARD', ('...%s... it is quiet in there... somebody cleared it...'):format(p.label)) end)
    pcall(function() exports.outbreak_log:log('pool.cleared', src, { id = id }) end)
  elseif p.left % 10 == 0 then savePools() end
end)
RegisterCommand('ob_pool', function(src, a)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.debug') and not IsPlayerAceAllowed(src, 'outbreak.dm') then return end
  local id, n = a[1], tonumber(a[2])
  if not id or not Pools[id] then print('pools: ' .. json.encode(Pools)) return end
  Pools[id].left = math.max(0, math.floor(n or Pools[id].total)); publishPools(); savePools()
  print(('^5[OB-POOL]^7 %s -> %d left'):format(id, Pools[id].left))
end, true)
exports('poolLeft', function(id) local p = Pools[id]; return p and p.left or nil end)

-- Debug convar -> GlobalState
GlobalState.obDebug = GetConvarInt('ob_debug', 0) == 1

-- Hordes are the first world event
if OutbreakCfg.Hordes.enabled then
  scheduleEvent('horde', OutbreakCfg.Hordes.minInterval, OutbreakCfg.Hordes.maxInterval, function(players)
    local lucky = players[math.random(#players)]
    local size = OutbreakCfg.Hordes.size; pcall(function() size = math.floor(tonumber(GlobalState.obTune['horde.size']) or size) end)
    fireEvent('horde', lucky, { size = size })
    if OutbreakCfg.Hordes.announceOnRadio then
      pcall(function() exports.outbreak_radio:transmit(0, 'STATIC', '*static* ...movement... large group... *static*') end)
    end
  end)
end
