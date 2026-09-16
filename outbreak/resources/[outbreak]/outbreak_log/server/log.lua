-- outbreak_log/server/log.lua — ONE event log for the whole pack.
--   exports.outbreak_log:log(kind, src, details)   kind = 'faction.join', 'death.permadeath', 'house.claim', 'dm.action'...
-- Files: <resource>/logs/YYYY-MM-DD.log, one line each:  2026-09-16 04:12:03 | 12:ABC123 | faction.join | {"which":"military"}
-- Query: /logs [kind:faction] [kind:faction.join] [player:12] [date:2026-09-16] [text:zancudo] [n:50]
local dir = GetResourcePath(GetCurrentResourceName()) .. '/logs'
local ring, RING = {}, 600
os.execute = nil  -- never shell out from here
local function ident(src)
  if not src or src == 0 then return 'server' end
  local cid = '?'
  pcall(function() local p = exports['qb-core']:GetCoreObject().Functions.GetPlayer(src); cid = p and p.PlayerData.citizenid or '?' end)
  return ('%s:%s:%s'):format(src, (GetPlayerName(src) or '?'):gsub('|', '/'), cid)
end
local function path(date) return ('%s/%s.log'):format(dir, date or os.date('%Y-%m-%d')) end
local function ensureDir()
  -- io cannot mkdir; SaveResourceFile creates intermediate folders for us on first write
  if not LoadResourceFile(GetCurrentResourceName(), 'logs/.keep') then SaveResourceFile(GetCurrentResourceName(), 'logs/.keep', '', -1) end
end
local function log(kind, src, details)
  ensureDir()
  local line = ('%s | %s | %s | %s'):format(os.date('%Y-%m-%d %H:%M:%S'), ident(src), tostring(kind), type(details) == 'table' and json.encode(details) or tostring(details or ''))
  local f = io.open(path(), 'a'); if f then f:write(line .. '\n'); f:close() end
  ring[#ring + 1] = line; if #ring > RING then table.remove(ring, 1) end
  if GlobalState.obDebug then print('^5[OB-LOG]^7 ' .. line) end
  return line
end
exports('log', log)
exports('recent', function(n) local out = {}; for i = math.max(1, #ring - (n or 30) + 1), #ring do out[#out + 1] = ring[i] end; return out end)

local function query(filters)
  local date = filters.date or os.date('%Y-%m-%d')
  local f = io.open(path(date), 'r'); if not f then return {}, date end
  local out, n = {}, tonumber(filters.n) or 40
  for l in f:lines() do
    local ok = true
    if filters.kind and not l:find(' | ' .. filters.kind, 1, true) then ok = false end
    if ok and filters.player and not l:find(' | ' .. filters.player .. ':', 1, true) then ok = false end
    if ok and filters.text and not l:lower():find(filters.text:lower(), 1, true) then ok = false end
    if ok then out[#out + 1] = l end
  end
  f:close()
  while #out > n do table.remove(out, 1) end
  return out, date
end
exports('query', query)
RegisterCommand('logs', function(src, a)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.admin') then return end
  local filters = {}
  for _, t in ipairs(a) do local k, v = t:match('^(%w+):(.+)$'); if k then filters[k] = v end end
  local rows, date = query(filters)
  local say = function(t) if src == 0 then print(t) else TriggerClientEvent('chat:addMessage', src, { args = { 'LOG', t } }) end end
  say(('%d line(s) from %s'):format(#rows, date))
  for _, l in ipairs(rows) do say(l) end
  if #rows == 0 then say('filters: kind:<prefix> player:<id> date:YYYY-MM-DD text:<word> n:<count>') end
end, true)
-- `event log` alias (admin suite): the last 30 lines from memory
RegisterCommand('event', function(src, a)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.admin') then return end
  if a[1] ~= 'log' then return end
  local say = function(t) if src == 0 then print(t) else TriggerClientEvent('chat:addMessage', src, { args = { 'LOG', t } }) end end
  for _, l in ipairs(exports.outbreak_log:recent(tonumber(a[2]) or 30)) do say(l) end
end, true)
-- lifecycle
AddEventHandler('onResourceStart', function(r) if r == GetCurrentResourceName() then log('server.boot', 0, { players = #GetPlayers() }) elseif r:find('^outbreak_') then log('resource.start', 0, { resource = r }) end end)
AddEventHandler('onResourceStop', function(r) if r:find('^outbreak_') and r ~= GetCurrentResourceName() then log('resource.stop', 0, { resource = r }) end end)
AddEventHandler('playerJoining', function() log('player.join', source, {}) end)
AddEventHandler('playerDropped', function(reason) log('player.drop', source, { reason = reason }) end)
