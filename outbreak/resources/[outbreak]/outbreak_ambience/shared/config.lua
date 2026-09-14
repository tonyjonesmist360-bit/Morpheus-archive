AmbienceCfg = {
  Wind = { volume = 0.35, nightBoost = 0.15, indoorsFactor = 0.25 },   -- loop, always on outdoors, louder at night
  Groans = { minGap = 18, maxGap = 55, volumeAt1 = 0.25, volumeAt8 = 0.6, maxZombies = 8 }, -- seconds between; scaled by zombies within 60 m
  NightHours = { from = 21, to = 5 },
  -- Darker nights: a timecycle modifier applied between NightHours on top of the blackout.
  -- Name from memory - UNVERIFIED. Set to nil to disable. If the night looks wrong, that is this line.
  NightTimecycle = nil,
  NightExposure = -0.6,                -- SetTimecycleModifierStrength-free alternative: lower screen exposure a touch at night (0 = off)
  Discord = { appId = '', asset = '', assetText = 'Dead State', text = 'Surviving Sandy Shores', button = nil }, -- appId from discord.com/developers; empty = text-only presence
}
