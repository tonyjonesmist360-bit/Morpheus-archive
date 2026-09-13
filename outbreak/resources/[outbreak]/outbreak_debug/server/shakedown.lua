-- outbreak_debug/server/shakedown.lua — ONE log file for the whole run: <resource>/shakedown.log (JSON lines) + a readable summary on /shakedown export
local path = GetResourcePath(GetCurrentResourceName()) .. '/shakedown.log'
local function line(t)
  t.at = os.date('%Y-%m-%d %H:%M:%S')
  local f = io.open(path, 'a'); if f then f:write(json.encode(t) .. '\n'); f:close() end
end
local function ctx(src)
  local res = {}
  for i = 0, GetNumResources() - 1 do local n = GetResourceByFindIndex(i); if n and n:find('^outbreak_') then res[#res + 1] = n .. ':' .. GetResourceState(n) end end
  return { player = src and GetPlayerName(src) or 'server', players = #GetPlayers(), debug = GlobalState.obDebug, time = GlobalState.obTime, weather = GlobalState.obWeather, resources = table.concat(res, ' ') }
end
AddEventHandler('onResourceStart', function(res) if res:find('^outbreak_') then line({ kind = 'start', resource = res, state = GetResourceState(res) }) end end)
AddEventHandler('onResourceStop', function(res) if res:find('^outbreak_') then line({ kind = 'stop', resource = res }) end end)
RegisterNetEvent('outbreak:shakedown:mark', function(id, label, status, note)
  local src = source; if not GlobalState.obDebug then return end
  line({ kind = 'mark', step = id, label = label, status = status, note = note, ctx = ctx(src) })
  print(('^3[SHAKEDOWN]^7 %s %s — %s %s'):format(id, status:upper(), label, note ~= '' and ('(' .. note .. ')') or ''))
end)
RegisterNetEvent('outbreak:shakedown:event', function(kind, data) line({ kind = kind, data = data, player = GetPlayerName(source) }) end)
RegisterNetEvent('outbreak:shakedown:export', function()
  local src = source; if not GlobalState.obDebug then return end
  local f = io.open(path, 'r'); if not f then TriggerClientEvent('ox_lib:notify', src, { title = 'No log yet.', type = 'inform' }) return end
  local passes, fails, notes = 0, 0, {}
  for l in f:lines() do local ok, t = pcall(json.decode, l); if ok and t and t.kind == 'mark' then if t.status == 'pass' then passes = passes + 1 elseif t.status == 'fail' then fails = fails + 1; notes[#notes + 1] = t.step .. ': ' .. (t.note ~= '' and t.note or t.label) end end end
  f:close()
  print(('^3[SHAKEDOWN] SUMMARY^7 pass=%d fail=%d\n  %s\n  full log: %s'):format(passes, fails, table.concat(notes, '\n  '), path))
  TriggerClientEvent('ox_lib:notify', src, { title = ('Log: %d pass, %d fail'):format(passes, fails), description = 'Full path printed in the server console. Paste the file to Claude.', type = 'inform', duration = 9000 })
end)
-- console: `shakedown` prints the summary without a player
RegisterCommand('shakedown_summary', function(src) if src == 0 then TriggerEvent('outbreak:shakedown:export') end end, true)
line({ kind = 'boot', ctx = ctx(nil) })
