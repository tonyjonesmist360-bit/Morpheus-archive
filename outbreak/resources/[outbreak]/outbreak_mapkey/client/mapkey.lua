-- outbreak_mapkey/client/mapkey.lua — the map answers for itself.
-- 1) vanilla blips that break the fiction are removed (banks, clothing, ammunation, LS Customs...)
-- 2) /mapkey (wheel -> Map key, F1 footer) opens the legend: every blip the pack draws, named.
local function sweep()
  for _, sprite in ipairs(MapKeyCfg.HideSprites) do
    local b = GetFirstBlipInfoId(sprite)
    local guard = 0
    while DoesBlipExist(b) and guard < 200 do
      RemoveBlip(b); guard = guard + 1
      b = GetFirstBlipInfoId(sprite)
    end
  end
end
-- from the core tick, every 10 s: the game re-adds POI blips as areas stream in
local last = 0
AddEventHandler('outbreak:tick', function()
  if GetGameTimer() - last < 10000 then return end
  last = GetGameTimer(); sweep()
end)
CreateThread(function() Wait(5000); sweep() end)

RegisterCommand('mapkey', function()
  local opts = {}
  for _, e in ipairs(MapKeyCfg.Legend) do
    if not e.res or GetResourceState(e.res) == 'started' then
      opts[#opts + 1] = { title = e.label, description = e.what, icon = e.icon, iconColor = e.colour, readOnly = true }
    end
  end
  opts[#opts + 1] = { title = 'Everything else is gone', description = 'Banks, shops, clothing, ammunation: the map does not show them because they are not open. What you find, you loot.', icon = 'ban', readOnly = true }
  lib.registerContext({ id = 'ob_mapkey', title = 'Map key', options = opts })
  lib.showContext('ob_mapkey')
end, false)
