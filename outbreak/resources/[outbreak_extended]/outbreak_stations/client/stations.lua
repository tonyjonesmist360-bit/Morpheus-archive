-- outbreak_stations/client/stations.lua
CreateThread(function()
  for _, s in ipairs(StationCfg.Stations) do
    local blip = AddBlipForCoord(s.pos.x, s.pos.y, s.pos.z)
    SetBlipSprite(blip, 361); SetBlipScale(blip, 0.6); SetBlipColour(blip, 40)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(s.label); EndTextCommandSetBlipName(blip)
    exports.ox_target:addSphereZone({ coords = s.pos, radius = 12.0, options = {
      { label = 'Try the pump', icon = 'fa-solid fa-gas-pump', onSelect = function()
          local st = (GlobalState.obStations or {})[s.id]
          if st and st.kind == 'deadpump' then
            lib.notify({ title = 'The pump is dead. It wants power.', description = 'A car battery might do it.', type = 'inform' })
            return
          end
          if lib.progressCircle({ duration = StationCfg.PumpSeconds * 1000, label = 'Working the pump...', canCancel = true }) then
            TriggerServerEvent('outbreak:server:pump', s.id)
          end
        end },
      { label = 'Wire a battery to the pump', icon = 'fa-solid fa-car-battery', item = StationCfg.DeadPumpItem,
        canInteract = function() local st = (GlobalState.obStations or {})[s.id]; return st and st.kind == 'deadpump' end,
        onSelect = function()
          if exports.outbreak_minigames:play('splice', { length = 6, showMs = 1600 }) then
            TriggerServerEvent('outbreak:server:powerPump', s.id)
          else
            TriggerEvent('outbreak:noise:spike', 60)
            lib.notify({ title = 'Sparks. The pump stays dead.', type = 'error' })
          end
        end },
      { label = 'Search the shop', icon = 'fa-solid fa-store', onSelect = function()
          if lib.progressCircle({ duration = 7000, label = 'Rifling shelves...', canCancel = true }) then
            TriggerServerEvent('outbreak:server:stationLoot', s.id)
          end
        end },
    }})
  end
end)
