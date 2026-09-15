-- outbreak_items/client/loot.lua : ox_target search on world props
CreateThread(function()
  local models = {}
  for model in pairs(LootCfg.Containers) do models[#models + 1] = model end
  exports.ox_target:addModel(models, {
    {
      label = 'Search',
      icon = 'fa-solid fa-magnifying-glass',
      onSelect = function(data)
        local entity = data.entity
        local model = GetEntityModel(entity)
        local pos = GetEntityCoords(entity)
        local containerId = ('%d_%d_%d'):format(math.floor(pos.x), math.floor(pos.y), model)
        if exports.outbreak_emotes:action('search', LootCfg.SearchSeconds * 1000, 'Searching...') then
          TriggerServerEvent('outbreak:server:search', containerId, LootCfg.Containers[model])
        end
      end,
    },
  })
end)

RegisterNetEvent('outbreak:client:noiseSpike', function(v) TriggerEvent('outbreak:noise:spike', v) end)

-- used a med from the inventory: the server picked the part, we play the hands and confirm
RegisterNetEvent('outbreak:client:treatSelf', function(part, item)
  local mult = 1.0
  pcall(function() mult = exports.outbreak_skills:effects('medicine').bandageTime; if exports.outbreak_skills:hasTrait('hemophobic') then mult = mult * 2 end end)
  local ms = item == 'splint' and 12000 or item == 'painkillers' and 3000 or 6000
  if exports.outbreak_emotes:action(item == 'painkillers' and 'eat' or 'treat', math.floor(ms * mult), 'Treating ' .. tostring(part):gsub('_', ' ')) then
    TriggerServerEvent('outbreak:server:treat', part, item)
  end
end)
