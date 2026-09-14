WorldCfg = {
  DayLengthMinutes = 60,     -- one full in-game day per real hour
  StartHour = 7,
  Blackout = true,           -- the grid is down: no streetlights, no building glow
  BlackoutVehicleLights = false, -- vehicles keep headlights even in blackout
  -- Moodier preset (2026-09-14): weighted toward overcast, fog and rain; clear skies are the exception.
  Weathers = { 'CLEAR', 'CLOUDS', 'CLOUDS', 'OVERCAST', 'OVERCAST', 'OVERCAST', 'FOGGY', 'FOGGY', 'RAIN', 'RAIN', 'THUNDER', 'CLEARING', 'SMOG' },
  WeatherMinutes = { 20, 50 }, -- real minutes between shifts
}
