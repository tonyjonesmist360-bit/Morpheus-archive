-- outbreak_ambience/client/ambience.lua
local C = AmbienceCfg
local function nui(t) SendNUIMessage(t) end
local function isNight() local h = GlobalState.obTime; if not h then return false end; h = math.floor(h / 60); return h >= C.NightHours.from or h < C.NightHours.to end

-- wind bed + groans, from the tick (every 500 ms), throttled to 2 s
local lastAt, nextGroan = 0, 0
AddEventHandler('outbreak:tick', function(t)
  local now = GetGameTimer()
  if now - lastAt < 2000 then return end
  lastAt = now
  local indoors = GetInteriorFromEntity(t.ped) ~= 0
  local vol = C.Wind.volume + (isNight() and C.Wind.nightBoost or 0)
  if indoors then vol = vol * C.Wind.indoorsFactor end
  if t.veh and t.veh ~= 0 then vol = vol * 0.5 end
  nui({ action = 'wind', volume = vol })
  local n = t.zombiesNear or 0
  if n > 0 and now >= nextGroan then
    local k = math.min(1.0, n / C.Groans.maxZombies)
    local v = C.Groans.volumeAt1 + (C.Groans.volumeAt8 - C.Groans.volumeAt1) * k
    if indoors then v = v * 0.5 end
    nui({ action = 'groan', volume = v, which = math.random(2) })
    nextGroan = now + math.random(C.Groans.minGap, C.Groans.maxGap) * 1000 * (1.0 - 0.5 * k)
  end
end)

-- darker nights (on top of outbreak_world's blackout)
CreateThread(function()
  local applied = false
  while true do
    Wait(5000)
    local night = isNight()
    if night and not applied then
      applied = true
      if C.NightTimecycle then SetTimecycleModifier(C.NightTimecycle) end
      if (C.NightExposure or 0) ~= 0 then SetExtraTimecycleModifier('cinema'); SetExtraTimecycleModifierStrength(0.0) end
    elseif not night and applied then
      applied = false
      ClearTimecycleModifier(); ClearExtraTimecycleModifier()
    end
  end
end)

-- Discord rich presence
CreateThread(function()
  Wait(3000)
  local D = C.Discord
  if D.appId and D.appId ~= '' then
    SetDiscordAppId(D.appId)
    if D.asset and D.asset ~= '' then SetDiscordRichPresenceAsset(D.asset); SetDiscordRichPresenceAssetText(D.assetText or '') end
    if D.button then SetDiscordRichPresenceAction(0, D.button.label, D.button.url) end
  end
  while true do
    local n = #GetActivePlayers()
    SetRichPresence(('%s · %d survivor%s'):format(D.text or 'Surviving', n, n == 1 and '' or 's'))
    Wait(60000)
  end
end)
