-- outbreak_raiders/server/loot.lua
-- Director: rolls ambushes on driving players. Robbery: takes items when you're down.
local onCooldown = {}  -- src -> os.time()
local inChase = {}

CreateThread(function()
  while true do
    Wait(RaiderCfg.CheckMinutes * 60000)
    for _, src in ipairs(GetPlayers()) do
      src = tonumber(src)
      local cd = onCooldown[src]
      if not inChase[src] and (not cd or os.time() - cd > RaiderCfg.CooldownMinutes * 60) then
        local ped = GetPlayerPed(src)
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 and (GetEntitySpeed(veh) * 3.6) >= RaiderCfg.MinSpeedKmh then
          local chance = RaiderCfg.ChanceWhileDriving
          pcall(function() if exports.outbreak_weapons:legendaryCount(src) > 0 then chance = chance * 2.0 end end) -- a big gun is a big target
          if math.random() < chance then
            inChase[src] = true
            TriggerClientEvent('outbreak:client:raiderAmbush', src)
          end
        end
      end
    end
  end
end)

RegisterNetEvent('outbreak:server:chaseEnded', function()
  local src = source
  inChase[src] = nil
  onCooldown[src] = os.time()
end)

RegisterNetEvent('outbreak:server:raiderRob', function()
  local src = source
  if not inChase[src] then return end  -- only mid-chase; blocks random triggering
  local never = {}
  for _, n in ipairs(RaiderCfg.NeverTake) do never[n] = true end
  local items = exports.ox_inventory:GetInventoryItems(src) or {}
  -- priority items first, then whatever's left
  local order, seen = {}, {}
  for _, want in ipairs(RaiderCfg.Priority) do
    for slot, it in pairs(items) do
      if it and it.name == want and not seen[slot] then order[#order + 1] = it; seen[slot] = true end
    end
  end
  for slot, it in pairs(items) do
    if it and not seen[slot] then order[#order + 1] = it; seen[slot] = true end
  end
  local taken = 0
  for _, it in ipairs(order) do
    if taken >= RaiderCfg.MaxSlotsTaken then break end
    if not never[it.name] then
      if exports.ox_inventory:RemoveItem(src, it.name, it.count, it.metadata, it.slot) then
        taken = taken + 1
      end
    end
  end
  TriggerClientEvent('ox_lib:notify', src,
    { title = taken > 0 and ('They took %d things and left you breathing.'):format(taken)
                        or 'Nothing worth taking. Almost insulting.', type = 'error' })
end)

AddEventHandler('playerDropped', function()
  local src = source
  inChase[src] = nil; onCooldown[src] = nil
end)
