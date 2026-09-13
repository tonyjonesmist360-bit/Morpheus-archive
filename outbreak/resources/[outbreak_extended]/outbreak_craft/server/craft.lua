-- outbreak_craft/server/craft.lua
RegisterNetEvent('outbreak:server:craft', function(id)
  local src = source
  local recipe
  for _, r in ipairs(CraftCfg.Recipes) do if r.id == id then recipe = r break end end
  if not recipe then return end
  for _, n in ipairs(recipe.needs) do
    local have = exports.ox_inventory:GetItemCount(src, n[1])
    if have < math.max(n[2], 1) then
      TriggerClientEvent('ox_lib:notify', src, { title = 'Missing: ' .. n[1]:gsub('_', ' '), type = 'error' })
      return
    end
  end
  for _, n in ipairs(recipe.needs) do
    if n[2] > 0 then exports.ox_inventory:RemoveItem(src, n[1], n[2]) end
  end
  exports.ox_inventory:AddItem(src, recipe.gives[1], recipe.gives[2])
  TriggerClientEvent('ox_lib:notify', src, { title = 'Made: ' .. recipe.label, type = 'success' })
end)
