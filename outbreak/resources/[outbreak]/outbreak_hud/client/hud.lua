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
  }})
end)

AddEventHandler('outbreak:hud:noise', function(v)
  SendNUIMessage({ action = 'noise', value = v })
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
