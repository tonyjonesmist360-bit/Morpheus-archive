-- outbreak_items/client/loot.lua : ox_target search on world props
CreateThread(function()
  local models = {}
  for model in pairs(LootCfg.Containers) do models[#models + 1] = model end
  -- one target per loot table so a till says "Force the register", not "Search" (stores are looting)
  local byTable = {}
  for model, tbl in pairs(LootCfg.Containers) do byTable[tbl] = byTable[tbl] or {}; table.insert(byTable[tbl], model) end
  for tbl, list in pairs(byTable) do
    local label = (LootCfg.Labels or {})[tbl] or 'Search'
    local noise = (LootCfg.Noise or {})[tbl]
    exports.ox_target:addModel(list, {
      {
        label = label,
        icon = noise and 'fa-solid fa-hand-fist' or 'fa-solid fa-magnifying-glass',
        onSelect = function(data)
          local entity = data.entity
          local model = GetEntityModel(entity)
          local pos = GetEntityCoords(entity)
          local containerId = ('%d_%d_%d'):format(math.floor(pos.x), math.floor(pos.y), model)
          if noise then TriggerEvent('outbreak:noise:spike', noise) end
          if exports.outbreak_emotes:action(noise and 'pry' or 'search', LootCfg.SearchSeconds * 1000, noise and (label .. '...') or 'Searching...') then
            TriggerServerEvent('outbreak:server:search', containerId, LootCfg.Containers[model])
          end
        end,
      },
    })
  end
end)

-- NAMED LOOT SITES: sphere zones (gun store racks and safes, bank vaults). No prop names to get wrong.
CreateThread(function()
  for _, s in ipairs(LootCfg.Sites or {}) do
    local label = (LootCfg.Labels or {})[s.table] or ('Search ' .. s.label)
    local noise = (LootCfg.Noise or {})[s.table]
    exports.ox_target:addSphereZone({ coords = s.pos, radius = s.radius or 2.0, options = { {
      label = label, icon = s.minigame and 'fa-solid fa-lock' or 'fa-solid fa-hand-holding',
      onSelect = function()
        if noise then TriggerEvent('outbreak:noise:spike', noise) end
        if s.minigame then
          local ok = false
          pcall(function() ok = exports.outbreak_minigames:play(s.minigame, { pins = s.pins or 3, speed = 1.0 }) end)
          if not ok then TriggerEvent('outbreak:noise:spike', 70); lib.notify({ title = 'It holds.', description = 'Louder than you wanted.', type = 'error' }) return end
        end
        if exports.outbreak_emotes:action(s.minigame and 'pry' or 'search', LootCfg.SearchSeconds * 1000, label .. '...') then
          TriggerServerEvent('outbreak:server:search', 'site_' .. s.id, s.table, s.label)
        end
      end } } })
  end
end)
-- /ob_site_here <id> <table> <label...>: prints a Sites line for where you stand (debug helper for fixing coords)
RegisterCommand('ob_site_here', function(_, a)
  if not GlobalState.obDebug then return end
  local p = GetEntityCoords(PlayerPedId())
  local id, tbl = a[1] or 'site', a[2] or 'house'
  local label = #a > 2 and table.concat(a, ' ', 3) or id
  local l = ("    { id = '%s', label = '%s', table = '%s', pos = vec3(%.1f, %.1f, %.1f), radius = 2.5 },"):format(id, label, tbl, p.x, p.y, p.z)
  print('^5[OB-SITE]^7 ' .. l); lib.notify({ title = 'Site line printed to F8', description = l, type = 'inform', duration = 8000 })
end, false)

-- what a search found, with where: shown, and kept for the journal (last 20)
local finds = {}
RegisterNetEvent('outbreak:client:lootFound', function(where, list)
  local parts = {}
  for _, f in ipairs(list or {}) do parts[#parts + 1] = ('%s ×%d'):format(tostring(f[1]):gsub('_', ' '), f[2]) end
  local text = #parts > 0 and table.concat(parts, ', ') or 'nothing useful'
  lib.notify({ title = where or 'Found', description = text, type = #parts > 0 and 'success' or 'inform', duration = 6000 })
  table.insert(finds, 1, { where = where or '?', text = text, at = GlobalState.obTime })
  if #finds > 20 then finds[21] = nil end
end)
exports('lootLog', function() return finds end)

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
