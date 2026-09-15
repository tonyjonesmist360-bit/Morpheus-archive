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

-- Crew panel: outbreak_group pushes rows; we only relay.
AddEventHandler('outbreak:hud:crew', function(c) SendNUIMessage({ action = 'crew', data = c }) end)

-- Compass markers, rebuilt once a second from the tick: crew pins, my waypoint, home.
local marks, lastMarks = {}, 0
AddEventHandler('outbreak:tick', function(t)
  if GetGameTimer() - lastMarks < 1000 then return end
  lastMarks = GetGameTimer()
  local out = {}
  local function bearingTo(x, y) return (math.deg(math.atan(x - t.pos.x, y - t.pos.y)) + 360) % 360 end
  local ok, pins = pcall(function() return exports.outbreak_group:getPins() end)
  if ok and pins then for _, p in ipairs(pins) do out[#out + 1] = { b = bearingTo(p.x, p.y), l = p.label, k = 'pin' } end end
  local wp = GetFirstBlipInfoId(8)
  if DoesBlipExist(wp) then local c = GetBlipInfoIdCoord(wp); out[#out + 1] = { b = bearingTo(c.x, c.y), l = 'waypoint', k = 'wp' } end
  local ok2, home = pcall(function() return exports.outbreak_supply:getHome() end)
  if ok2 and home and home.door then out[#out + 1] = { b = bearingTo(home.door.x, home.door.y), l = 'home', k = 'home' } end
  marks = out
end)

-- Hide default GTA hud pieces we replace. This is the pack's one permitted per-frame HUD loop;
-- the compass heading rides on it at 10 Hz instead of adding another.
CreateThread(function()
  local lastC = 0
  while true do
    HideHudComponentThisFrame(1) -- wanted stars
    HideHudComponentThisFrame(3) -- cash
    HideHudComponentThisFrame(4) -- mp cash
    local now = GetGameTimer()
    if now - lastC >= 100 then
      lastC = now
      local rot = GetGameplayCamRot(2)
      SendNUIMessage({ action = 'compass', heading = (360.0 - rot.z) % 360.0, marks = marks })
    end
    Wait(0)
  end
end)
