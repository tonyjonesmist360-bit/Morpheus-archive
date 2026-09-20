-- outbreak_items/server/loot.lua : rolls loot, persistent container cooldowns
local searched = {}

CreateThread(function()
  local rows = MySQL.query.await('SELECT container_id, searched_at FROM outbreak_loot') or {}
  for _, r in ipairs(rows) do searched[r.container_id] = r.searched_at end
end)

local function roll(src, tbl, list)
  local lvl = tonumber(Player(src).state.scavLevel) or 0
  local found = false
  local mult = 1.0; pcall(function() mult = tonumber(GlobalState.obTune and GlobalState.obTune['loot.multiplier']) or 1.0 end)
  for _, e in ipairs(tbl) do
    if math.random() < (e[4] + lvl * 0.03) * mult then
      local amount = math.random(e[2], e[3])
      if exports.ox_inventory:CanCarryItem(src, e[1], amount) then exports.ox_inventory:AddItem(src, e[1], amount); found = true; if list then list[#list + 1] = { e[1], amount } end end
    end
  end
  -- progression hook: occasionally a document (intelId chosen by outbreak_intel from the catalog's document-sourced records)
  pcall(function()
    if math.random() < 0.06 and exports.outbreak_intel:giveRandomDocument(src) then found = true end
  end)
  return found
end

local function respawnMinutes()
  local t = GlobalState.obTune; local v = t and tonumber(t['loot.respawnMinutes'])
  return v or LootCfg.RespawnMinutes
end
local function doSearch(src, containerId, tableName, where, token)
  local tbl = LootCfg.Tables[tableName]; if not tbl or type(containerId) ~= 'string' then return end
  -- a site id must match a configured site, and the table must be the site's own (no client-chosen tables)
  if containerId:find('^site_') then
    local site
    for _, s in ipairs(LootCfg.Sites or {}) do if 'site_' .. s.id == containerId and s.table == tableName then site = s; where = where or s.label end end
    if not site then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - site.pos) > (site.radius or 2.5) + 3.0 then return end
    if site.requires then local kind, id = site.requires:match('^(%w+):(.+)$'); if kind == 'pool' then local left = nil; pcall(function() left = exports.outbreak_core:poolLeft(id) end); if left == nil or left > 0 then return end end end
    if site.minigame then local ok = exports.outbreak_minigames:consume(src, token, 'site:' .. site.id); if not ok then return end end  -- Q1
  end
  local last = searched[containerId]
  if last and os.time() - last < respawnMinutes() * 60 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Already picked clean.', type = 'error' }) return end
  searched[containerId] = os.time()
  MySQL.prepare('INSERT INTO outbreak_loot (container_id, searched_at) VALUES (?, ?) ON DUPLICATE KEY UPDATE searched_at = VALUES(searched_at)', { containerId, os.time() })
  pcall(function() exports.outbreak_skills:grantXP(src, 'search') end)
  local list = {}
  local found = roll(src, tbl, list)
  if where then TriggerClientEvent('outbreak:client:lootFound', src, where, list)
  elseif not found then TriggerClientEvent('ox_lib:notify', src, { title = 'Nothing useful.', type = 'inform' }) end
  pcall(function() exports.outbreak_log:log('loot.search', src, { where = where or containerId, table = tableName, found = #list }) end)
end
RegisterNetEvent('outbreak:server:search', function(containerId, tableName, where, token) doSearch(source, containerId, tableName, type(where) == 'string' and where:sub(1, 48) or nil, token) end)
exports('search', doSearch)
-- `loot reset`: every container and site is fresh again (memory + table). Admin suite, v0.23.
exports('resetLoot', function()
  local n = 0; for _ in pairs(searched) do n = n + 1 end
  searched = {}
  MySQL.update('DELETE FROM outbreak_loot')
  return n
end)

exports('roll', roll)
exports('isSearched', function(id) local l = searched[id]; return l and os.time() - l < respawnMinutes() * 60 end)
