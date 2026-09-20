-- outbreak_mapkey/client/places.lua — every place worth walking to is on the map with a name (v0.25).
-- Our blips replace the vanilla ones (mapkey.lua hides those): stores, clothing, barbers, customs, the prison,
-- plus the derived sets: gun stores and vaults (loot sites), medical stations, workbenches.
local blips = {}
local function nameBlip(b, name) BeginTextCommandSetBlipName('STRING'); AddTextComponentString(name); EndTextCommandSetBlipName(b) end
local function add(pos, def, name)
  local b = AddBlipForCoord(pos.x, pos.y, pos.z)
  SetBlipSprite(b, def.sprite); SetBlipColour(b, def.colour or 0); SetBlipScale(b, def.scale or 0.6); SetBlipAsShortRange(b, true)
  nameBlip(b, name); blips[#blips + 1] = b
end
CreateThread(function()
  Wait(2000)
  for cat, def in pairs(MapKeyCfg.Places or {}) do
    for _, p in ipairs(def.list or {}) do add(p[2], def, p[1]) end
  end
  local D = MapKeyCfg.Derived or {}
  for _, s in ipairs(LootCfg and LootCfg.Sites or {}) do
    if s.table == 'gunstore' and D.gunstore then add(s.pos, D.gunstore, s.label:gsub(' — rack', '')) end
    if s.table == 'vault' and D.vault then add(s.pos, D.vault, s.label) end
  end
  for _, st in ipairs(DownCfg and DownCfg.Critical and DownCfg.Critical.Stations or {}) do if D.station then add(st.pos, D.station, st.label) end end
  for _, b in ipairs(CraftCfg and CraftCfg.BenchSites or {}) do if D.bench then add(b.pos, D.bench, 'Workbench: ' .. b.label) end end
  -- targets: clothing (free change), barber (old money)
  for _, p in ipairs((MapKeyCfg.Places.clothing or {}).list or {}) do
    exports.ox_target:addSphereZone({ coords = p[2], radius = 2.5, options = {
      { label = 'Change clothes (free)', icon = 'fa-solid fa-shirt', onSelect = function() ExecuteCommand('wardrobe') end },
      { label = 'Loot the racks', icon = 'fa-solid fa-mask', onSelect = function()
          TriggerEvent('outbreak:noise:spike', 18)
          if exports.outbreak_emotes:action('search', 4000, 'Going through the racks...') then TriggerServerEvent('outbreak:server:search', ('cloth_%d_%d'):format(math.floor(p[2].x), math.floor(p[2].y)), 'clothing', p[1]) end end },
    } })
  end
  for _, p in ipairs((MapKeyCfg.Places.barber or {}).list or {}) do
    exports.ox_target:addSphereZone({ coords = p[2], radius = 2.5, options = { {
      label = ('Haircut · %d Old Money'):format((MapKeyCfg.Barber or {}).price or 5), icon = 'fa-solid fa-scissors',
      onSelect = function() TriggerServerEvent('outbreak:server:barber') end } } })
  end
end)
RegisterNetEvent('outbreak:client:barberChair', function() lib.notify({ title = 'The barber counts it twice.', description = 'Same price as before. Some things do not change.', type = 'inform' }); ExecuteCommand('wardrobe') end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then for _, b in ipairs(blips) do if DoesBlipExist(b) then RemoveBlip(b) end end end end)
