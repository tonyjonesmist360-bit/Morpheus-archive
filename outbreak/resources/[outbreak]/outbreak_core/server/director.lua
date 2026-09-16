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
