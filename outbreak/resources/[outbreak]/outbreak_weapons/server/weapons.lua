-- outbreak_weapons/server/weapons.lua — repair items, legendary attention, flare beacon
local QBCore = exports['qb-core']:GetCoreObject()

local function heldWeapon(src)
  -- ox: the equipped weapon is tracked server-side; fall back to the first weapon slot
  local ok, w = pcall(function() return exports.ox_inventory:GetCurrentWeapon(src) end)
  if ok and w then return w end
  for slot, it in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
    if it and it.name and WeaponCfg.Weapons[it.name] then return it end
  end
end

for item, amount in pairs(WeaponCfg.Repair) do
  QBCore.Functions.CreateUseableItem(item, function(src)
    local w = heldWeapon(src)
    if not w then TriggerClientEvent('ox_lib:notify', src, { title = 'Hold the weapon you want to work on.', type = 'error' }) return end
    local dur = (w.metadata and w.metadata.durability) or 100
    if dur >= 100 then TriggerClientEvent('ox_lib:notify', src, { title = 'It\'s already clean.', type = 'inform' }) return end
    if exports.ox_inventory:RemoveItem(src, item, 1) then
      exports.ox_inventory:SetDurability(src, w.slot, math.min(100, dur + amount))
      TriggerClientEvent('outbreak:anim:play', src, 'repair', 4000)
      pcall(function() exports.outbreak_skills:grantXP(src, 'repair') end)
      TriggerClientEvent('ox_lib:notify', src, { title = ('%s: %d%% → %d%%'):format(WeaponCfg.Weapons[w.name] and WeaponCfg.Weapons[w.name].label or w.name, dur, math.min(100, dur + amount)), type = 'success' })
    end
  end)
end

-- legendary attention: extended raiders multiply ambush chance; military checkpoints already fire on any drawn weapon
exports('legendaryCount', function(src)
  local n = 0
  for _, it in pairs(exports.ox_inventory:GetInventoryItems(src) or {}) do
    local d = it and it.name and WeaponCfg.Weapons[it.name]
    if d and d.tier == 'legendary' then n = n + 1 end
  end
  return n
end)
exports('isConcealable', function(name) local d = WeaponCfg.Weapons[name]; return not d or d.conceal ~= false end)

-- flare: a beacon everyone sees; a radio line; a horde for the shooter
local lastFlare = {}
RegisterNetEvent('outbreak:weapons:flare', function()
  local src = source
  if lastFlare[src] and os.time() - lastFlare[src] < 20 then return end
  lastFlare[src] = os.time()
  local pos = GetEntityCoords(GetPlayerPed(src))
  pcall(function() exports.outbreak_radio:transmit(0, 'FLARE', ('Red flare over %s. Somebody wants to be found.'):format(('%.0f, %.0f'):format(pos.x, pos.y)), nil, pos, 2500.0) end)
  pcall(function() exports.outbreak_core:fireEvent('horde', src, { size = 8 }) end)
end)
