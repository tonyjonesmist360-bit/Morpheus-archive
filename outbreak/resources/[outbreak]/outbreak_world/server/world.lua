-- outbreak_world/server/world.lua : one clock, one sky, for everyone
local minutes = WorldCfg.StartHour * 60
local weather = 'CLOUDS'

CreateThread(function()
  -- game minutes per real second so a day lasts DayLengthMinutes
  local perSecond = 1440.0 / (WorldCfg.DayLengthMinutes * 60)
  while true do
    Wait(1000)
    minutes = (minutes + perSecond) % 1440
    GlobalState.obTime = math.floor(minutes)
  end
end)

exports('setTime', function(hour) minutes = hour * 60; GlobalState.obTime = math.floor(minutes) end)
exports('setWeather', function(w) weather = w; GlobalState.obWeather = w end)

CreateThread(function()
  GlobalState.obWeather = weather
  GlobalState.obBlackout = WorldCfg.Blackout
  while true do
    Wait(math.random(WorldCfg.WeatherMinutes[1], WorldCfg.WeatherMinutes[2]) * 60000)
    weather = WorldCfg.Weathers[math.random(#WorldCfg.Weathers)]
    GlobalState.obWeather = weather
  end
end)
