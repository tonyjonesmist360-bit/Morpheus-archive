-- outbreak_core/server/director.lua
-- WORLD EVENTS SERVICE. Anything that "happens to the world" is scheduled here.
--   exports.outbreak_core:scheduleEvent(name, minMinutes, maxMinutes, handler)  -- handler(players) runs server-side
--   exports.outbreak_core:fireEvent(name, targetSrc, payload)                    -- TriggerClientEvent('outbreak:event:'..name)
local schedules = {}

local function fireEvent(name, target, payload)
  TriggerClientEvent('outbreak:event:' .. name, target or -1, payload)
  if GlobalState.obDebug then print(('^5[OB-EVENT]^7 %s -> %s'):format(name, tostring(target or 'all'))) end
end

local function scheduleEvent(name, minM, maxM, handler)
  schedules[name] = true
  CreateThread(function()
    while schedules[name] do
      Wait(math.random(minM, maxM) * 60000)
      local players = GetPlayers()
      if #players > 0 and schedules[name] then handler(players) end
    end
  end)
end

exports('scheduleEvent', scheduleEvent)
exports('fireEvent', fireEvent)
exports('cancelEvent', function(name) schedules[name] = nil end)

-- Debug convar -> GlobalState
GlobalState.obDebug = GetConvarInt('ob_debug', 0) == 1

-- Hordes are the first world event
if OutbreakCfg.Hordes.enabled then
  scheduleEvent('horde', OutbreakCfg.Hordes.minInterval, OutbreakCfg.Hordes.maxInterval, function(players)
    local lucky = players[math.random(#players)]
    fireEvent('horde', lucky, { size = OutbreakCfg.Hordes.size })
    if OutbreakCfg.Hordes.announceOnRadio then
      pcall(function() exports.outbreak_radio:transmit(0, 'STATIC', '*static* ...movement... large group... *static*') end)
    end
  end)
end
