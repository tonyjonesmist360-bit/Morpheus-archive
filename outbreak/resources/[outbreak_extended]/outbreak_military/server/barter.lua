-- outbreak_military/server/barter.lua
RegisterNetEvent('outbreak:server:barter', function(idx)
  local src = source
  local tr = MilCfg.Trader and MilCfg.Trader.Trades[idx]
  if not tr then return end
  if exports.ox_inventory:GetItemCount(src, tr.give[1]) < tr.give[2] then
    TriggerClientEvent('ox_lib:notify', src, { title = 'The Quartermaster eyes your empty hands.', type = 'error' })
    return
  end
  exports.ox_inventory:RemoveItem(src, tr.give[1], tr.give[2])
  exports.ox_inventory:AddItem(src, tr.get[1], tr.get[2])
  TriggerClientEvent('ox_lib:notify', src, { title = 'Trade done. "Stay alive out there."', type = 'success' })
end)
