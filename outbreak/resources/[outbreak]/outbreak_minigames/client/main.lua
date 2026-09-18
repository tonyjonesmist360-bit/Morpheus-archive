-- outbreak_minigames/client/main.lua
-- Usage from any resource:
--   local ok = exports.outbreak_minigames:play('pinsweep', { pins = 3, speed = 1.0 })
--   local ok = exports.outbreak_minigames:play('pry',      { pulls = 3, width = 18 })
--   local ok = exports.outbreak_minigames:play('splice',   { length = 5, showMs = 1800 })
-- Blocks until the game ends; returns ok, token.
-- v0.24 (Q1): pass a TARGET string as the third argument ('house:force:sandy_bungalow', 'veh:pry:<netId>')
-- and the server issues a token first; hand `token` back with the result event. Without a target the
-- game still plays but no token exists, and a token-checking server handler will refuse the result.
local active = nil

exports('play', function(game, opts, target)
  if active then return false, nil end
  local token = nil
  if target then
    token = lib.callback.await('outbreak:minigame:request', false, game, opts or {}, target)
    if not token then lib.notify({ title = 'Not now.', description = 'The server refused the attempt.', type = 'error' }) return false, nil end
  end
  local p = promise.new()
  active = p
  SetNuiFocus(true, false) -- keyboard, no cursor
  SendNUIMessage({ action = 'start', game = game, opts = opts or {} })
  local ok = Citizen.Await(p)
  return ok, token
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
