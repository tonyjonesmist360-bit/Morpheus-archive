-- outbreak_world/client/world.lua
CreateThread(function()
  while true do
    Wait(2000)
    local t = GlobalState.obTime or 420
    NetworkOverrideClockTime(math.floor(t / 60), math.floor(t % 60), 0)
    local w = GlobalState.obWeather or 'CLOUDS'
    SetWeatherTypeOvertimePersist(w, 30.0)
    if GlobalState.obBlackout then
      SetArtificialLightsState(true)  -- grid down
      SetArtificialLightsStateAffectsVehicles(not WorldCfg.BlackoutVehicleLights and true or false)
    end
  end
end)
