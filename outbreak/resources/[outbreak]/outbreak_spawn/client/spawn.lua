-- outbreak_spawn/client/spawn.lua
-- MOTD: every load, six seconds in, once.
local motdShown = false
local function motd()
  if motdShown or not SpawnCfg.Motd then return end
  motdShown = true
  local m = SpawnCfg.Motd
  for i, l in ipairs(m.lines) do
    TriggerEvent('chat:addMessage', { template = '<div style="padding:4px 8px;margin:1px 0;background:rgba(24,26,19,.55);border-left:3px solid #b4552d;color:#d8d2c0">{0}</div>', args = { (i == 1 and ('<b style="letter-spacing:1.6px">' .. m.title .. '</b> &nbsp; ') or '') .. l } })
  end
  lib.notify({ title = m.title, description = m.lines[1], type = 'inform', duration = 12000, position = 'top' })
end
AddEventHandler('QBCore:Client:OnPlayerLoaded', function() SetTimeout(6000, motd) end)

RegisterNetEvent('outbreak:client:freshSpawn', function(id)
  local p = SpawnCfg.Scenarios[id]; if not p then return end
  local ped = PlayerPedId()
  DoScreenFadeOut(0)
  SetEntityCoords(ped, p.pos.x, p.pos.y, p.pos.z); SetEntityHeading(ped, p.pos.w)
  Wait(1000); DoScreenFadeIn(4000); Wait(1500)
  lib.notify({ title = p.label, description = p.story, duration = 10000, type = 'inform' })
  Wait(5000)
  lib.notify({ title = 'Check your pockets.', description = 'Find water. Find a radio. Stay quiet. Press G.', duration = 8000, type = 'warning' })
end)
