-- outbreak_minigames/client/main.lua
-- Usage from any resource:
--   local ok = exports.outbreak_minigames:play('pinsweep', { pins = 3, speed = 1.0 })
--   local ok = exports.outbreak_minigames:play('pry',      { pulls = 3, width = 18 })
--   local ok = exports.outbreak_minigames:play('splice',   { length = 5, showMs = 1800 })
-- Blocks until the game ends; returns true/false.
local active = nil

exports('play', function(game, opts)
  if active then return false end
  local p = promise.new()
  active = p
  SetNuiFocus(true, false) -- keyboard, no cursor
  SendNUIMessage({ action = 'start', game = game, opts = opts or {} })
  return Citizen.Await(p)
end)

RegisterNUICallback('result', function(data, cb)
  cb('ok')
  SetNuiFocus(false, false)
  if active then
    local p = active
    active = nil
    p:resolve(data.success == true)
  end
end)

-- safety hatch if the NUI ever wedges
RegisterCommand('cancelminigame', function()
  if active then
    SetNuiFocus(false, false)
    local p = active; active = nil
    p:resolve(false)
    SendNUIMessage({ action = 'abort' })
  end
end, false)
