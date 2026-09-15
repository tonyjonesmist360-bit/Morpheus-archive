-- outbreak_items/server/items.lua — the ONLY place useables are registered
local QBCore = exports['qb-core']:GetCoreObject()
local N = function() return exports.outbreak_needs end

local Useables = {
  canned_beans = { requires = 'can_opener', effects = { hunger = 35 }, anim = 'eat' },
  rotten_meat  = { effects = { hunger = 15, thirst = -10 }, sick = true, anim = 'eat' },
  water_clean  = { effects = { thirst = 45 }, anim = 'drink' },
  water_dirty  = { effects = { thirst = 25 }, sick = true, anim = 'drink' },
  mre          = { effects = { hunger = 60, thirst = 10 }, anim = 'eat' },
  antibiotics  = { effects = { antibiotics = true }, anim = 'eat' },
  -- shelf goods: small, fast, everywhere until the shelves are bare
  chocolate_bar = { effects = { hunger = 10, fatigue = 4 }, anim = 'eat' },
  chips         = { effects = { hunger = 12, thirst = -4 }, anim = 'eat', noise = 25 },
  bread         = { effects = { hunger = 20 }, anim = 'eat', sick = true },        -- stale roll
  noodle_bowl   = { effects = { hunger = 28, thirst = 6 }, anim = 'eat' },
  soda          = { effects = { thirst = 18, fatigue = 6 }, anim = 'drink' },
  beer          = { effects = { thirst = 10, fatigue = -6 }, anim = 'drink' },
  -- cooked at a settlement (outbreak_supply recipes): better than the raw input, never sick, fatigue back
  hot_stew      = { effects = { hunger = 55, thirst = 10, fatigue = 8 }, anim = 'eat' },
  cooked_meat   = { effects = { hunger = 30, fatigue = 4 }, anim = 'eat' },
  hot_noodles   = { effects = { hunger = 40, thirst = 10, fatigue = 4 }, anim = 'eat' },
}

for item, def in pairs(Useables) do
  QBCore.Functions.CreateUseableItem(item, function(src)
    if def.requires and exports.ox_inventory:GetItemCount(src, def.requires) < 1 then
      TriggerClientEvent('ox_lib:notify', src, { title = 'You need a ' .. def.requires:gsub('_', ' '), type = 'error' }) return
    end
    if exports.ox_inventory:RemoveItem(src, item, 1) then
      TriggerClientEvent('outbreak:anim:play', src, def.anim, 3000)
      if def.noise then TriggerClientEvent('outbreak:client:noiseSpike', src, def.noise) end
      local fx = {}
      for k, v in pairs(def.effects) do fx[k] = v end
      if def.sick then
        local mult = 0.4
        pcall(function() if exports.outbreak_skills:hasTrait(src, 'weak_stomach') then mult = 0.8 end end)
        if math.random() < mult then fx.thirst = (fx.thirst or 0) - 15; TriggerClientEvent('ox_lib:notify', src, { title = 'That tasted... wrong.', type = 'error' }) end
      end
      N():consume(src, fx)
    end
  end)
end

-- DEAD MONEY: counting it does nothing but remind you.
QBCore.Functions.CreateUseableItem('old_cash', function(src)
  local n = exports.ox_inventory:GetItemCount(src, 'old_cash')
  TriggerClientEvent('ox_lib:notify', src, { title = ('$%d, more or less.'):format(n * 20), description = 'In a world that stopped counting. Someone might take it off you for a can.', type = 'inform', duration = 6000 })
end)

-- Distraction: the wheel asks, the server takes the can, the client throws it (outbreak_noise).
local Throwable = { soda = true, beer = true }
RegisterNetEvent('outbreak:server:throwDistraction', function(item)
  local src = source
  if not Throwable[item] then return end
  if exports.ox_inventory:RemoveItem(src, item, 1) then TriggerClientEvent('outbreak:client:throwDistraction', src, item) end
end)

QBCore.Functions.CreateUseableItem('purify_tabs', function(src)
  if exports.ox_inventory:GetItemCount(src, 'water_dirty') < 1 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Nothing to purify.', type = 'error' }) return end
  exports.ox_inventory:RemoveItem(src, 'purify_tabs', 1); exports.ox_inventory:RemoveItem(src, 'water_dirty', 1)
  exports.ox_inventory:AddItem(src, 'water_clean', 1)
  TriggerClientEvent('ox_lib:notify', src, { title = 'Water purified.', type = 'success' })
end)

-- LOCATIONAL TREATMENT (v0.22): each item treats ONLY its wound type. Using one from the
-- inventory picks the worst matching wound on you; the wheel and the F1 body scan pick a part.
local TargetedMeds = {
  bandage = { scratch = 2, bite = 3, laceration = 3, gunshot = 5 },
  ripped_sheet = { scratch = 2 },
  splint = { fracture = 4 },
  painkillers = { bruise = 1 },
}
for item, kinds in pairs(TargetedMeds) do
  QBCore.Functions.CreateUseableItem(item, function(src)
    local wounds = {}; pcall(function() wounds = N():getWounds(src) or {} end)
    local best, bestSev
    for part, w in pairs(wounds) do
      local sev = (not w.treated) and kinds[w.kind] or nil
      if sev and (not best or sev > bestSev) then best, bestSev = part, sev end
    end
    if not best then
      if item == 'painkillers' then -- nothing to treat: a little relief anyway
        if exports.ox_inventory:RemoveItem(src, item, 1) then TriggerClientEvent('outbreak:anim:play', src, 'eat', 3000); N():consume(src, { fatigue = 10 }) end
      else TriggerClientEvent('ox_lib:notify', src, { title = 'Nothing on you needs that.', description = 'Bandage: bleeds. Splint: breaks. Painkillers: bruises.', type = 'inform' }) end
      return
    end
    TriggerClientEvent('outbreak:client:treatSelf', src, best, item)
  end)
end

-- Treatment: bandages/sheets/splints are NOT generic useables. They target a body part via the wheel.
-- Client: TriggerServerEvent('outbreak:server:treat', part, item)  (self)  or ('outbreak:server:treatOther', targetSrc, part, item)
local function treat(src, target, part, item)
  if not ({ bandage = true, ripped_sheet = true, splint = true, painkillers = true })[item] then return end
  if exports.ox_inventory:GetItemCount(src, item) < 1 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'You don\'t have one.', type = 'error' }) return end
  if item == 'ripped_sheet' and math.random() < 0.3 then
    exports.ox_inventory:RemoveItem(src, item, 1)
    TriggerClientEvent('ox_lib:notify', src, { title = 'It falls apart.', type = 'error' }) return
  end
  if N():treatWound(target, part, item) then
    exports.ox_inventory:RemoveItem(src, item, 1)
    pcall(function() exports.outbreak_skills:grantXP(src, item == 'splint' and 'splint' or 'bandage') end)
    TriggerClientEvent('ox_lib:notify', src, { title = ('Treated: %s'):format(part:gsub('_', ' ')), type = 'success' })
    if target ~= src then TriggerClientEvent('ox_lib:notify', target, { title = 'Someone patches you up.', type = 'success' }) end
  else
    TriggerClientEvent('ox_lib:notify', src, { title = 'That won\'t help there.', type = 'error' })
  end
end
RegisterNetEvent('outbreak:server:treat', function(part, item) treat(source, source, part, item) end)
RegisterNetEvent('outbreak:server:treatOther', function(target, part, item)
  local tp = GetPlayerPed(target); if tp == 0 then return end
  if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(tp)) > 3.0 then return end
  treat(source, target, part, item)
end)
