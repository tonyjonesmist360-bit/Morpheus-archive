-- outbreak_spawn/client/spawn.lua
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
