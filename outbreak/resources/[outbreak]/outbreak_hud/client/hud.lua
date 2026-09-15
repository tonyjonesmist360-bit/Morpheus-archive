-- outbreak_hud/client/hud.lua : relays needs state to the NUI layer
AddEventHandler('outbreak:hud:update', function(state)
  local stage
  if state.infected and state.infectedAt then
    local hours = (GetCloudTimeAsInt() - state.infectedAt) / 3600
    for _, s in ipairs(NeedsCfg and NeedsCfg.Infection.stages or {}) do
      if hours >= s.after then stage = s.label end
    end
  end
  SendNUIMessage({ action = 'needs', data = {
    hunger = state.hunger, thirst = state.thirst, fatigue = state.fatigue,
    health = GetEntityHealth(PlayerPedId()) - 100, -- GTA peds: 100-200
    bleeding = state.bleeding, infection = stage, wounds = state.wounds or {},
    body = (function() local ok, b = pcall(function() return exports.outbreak_needs:bodyScan() end); return ok and b or nil end)(),
  }})
end)

AddEventHandler('outbreak:hud:sight', function(s) SendNUIMessage({ action = 'sight', data = s }) end)
AddEventHandler('outbreak:hud:noise', function(v)
  SendNUIMessage({ action = 'noise', value = v })
end)

-- World strip: time, weather, blackout, radio channel, mob area.
-- Subscribes to outbreak_core's existing tick rather than adding a loop - the same
-- pattern ARCHITECTURE prescribes for noise and encumbrance. Throttled to 2s because
-- none of this changes faster than that.
local lastStrip = 0
AddEventHandler('outbreak:tick', function()
  local now = GetGameTimer()
  if now - lastStrip < 2000 then return end
  lastStrip = now
  local ok, zone = pcall(function() return exports.outbreak_core:currentZone() end)
  local ok2, ch = pcall(function() return exports.outbreak_radio:getChannel() end)
  local ok3, hf = pcall(function() return exports.outbreak_supply:hudFlags() end)
  SendNUIMessage({ action = 'world', data = {
    hour     = GlobalState.obTime,
    weather  = GlobalState.obWeather,
    blackout = GlobalState.obBlackout and true or false,
    channel  = ok2 and ch or 0,
    zone     = ok and zone and zone.id or nil,
    heavy    = ok and zone and (zone.mult or 1) > 1.5 or false,
    tide     = ok and zone and zone.tide or false,
    home     = ok3 and hf or nil,   -- settlement flags: critical/low categories, starving
  }})
end)

-- Hide default GTA hud pieces we replace
CreateThread(function()
  while true do
    HideHudComponentThisFrame(1) -- wanted stars
    HideHudComponentThisFrame(3) -- cash
    HideHudComponentThisFrame(4) -- mp cash
    Wait(0)
  end
end)
