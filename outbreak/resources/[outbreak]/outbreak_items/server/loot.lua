-- outbreak_items/server/loot.lua : rolls loot, persistent container cooldowns
local searched = {}

CreateThread(function()
  local rows = MySQL.query.await('SELECT container_id, searched_at FROM outbreak_loot') or {}
  for _, r in ipairs(rows) do searched[r.container_id] = r.searched_at end
end)

local function roll(src, tbl)
  local lvl = tonumber(Player(src).state.scavLevel) or 0
  local found = false
  for _, e in ipairs(tbl) do
    if math.random() < e[4] + lvl * 0.03 then
      local amount = math.random(e[2], e[3])
      if exports.ox_inventory:CanCarryItem(src, e[1], amount) then exports.ox_inventory:AddItem(src, e[1], amount); found = true end
    end
  end
  -- progression hook: occasionally a document (intelId chosen by outbreak_intel from the catalog's document-sourced records)
  pcall(function()
    if math.random() < 0.06 and exports.outbreak_intel:giveRandomDocument(src) then found = true end
  end)
  return found
end

local function doSearch(src, containerId, tableName)
  local tbl = LootCfg.Tables[tableName]; if not tbl or type(containerId) ~= 'string' then return end
  local last = searched[containerId]
  if last and os.time() - last < LootCfg.RespawnMinutes * 60 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Already picked clean.', type = 'error' }) return end
  searched[containerId] = os.time()
  MySQL.prepare('INSERT INTO outbreak_loot (container_id, searched_at) VALUES (?, ?) ON DUPLICATE KEY UPDATE searched_at = VALUES(searched_at)', { containerId, os.time() })
  pcall(function() exports.outbreak_skills:grantXP(src, 'search') end)
  if not roll(src, tbl) then TriggerClientEvent('ox_lib:notify', src, { title = 'Nothing useful.', type = 'inform' }) end
end
RegisterNetEvent('outbreak:server:search', function(containerId, tableName) doSearch(source, containerId, tableName) end)
exports('search', doSearch)

exports('roll', roll)
exports('isSearched', function(id) local l = searched[id]; return l and os.time() - l < LootCfg.RespawnMinutes * 60 end)
