-- outbreak_debug/server/shakedown.lua — ONE log for the whole run: <resource>/shakedown.log (JSON lines),
-- plus shakedown-results.md, a readable table rebuilt on every mark. Paste either to Claude.
local path = GetResourcePath(GetCurrentResourceName()) .. '/shakedown.log'
local mdName = 'shakedown-results.md'
local latest = {}     -- id -> { sec, label, status, note, at, by }
local order = {}
local function line(t)
  t.at = os.date('%Y-%m-%d %H:%M:%S')
  local f = io.open(path, 'a'); if f then f:write(json.encode(t) .. '\n'); f:close() end
end
local function ctx(src)
  local res = {}
  for i = 0, GetNumResources() - 1 do local n = GetResourceByFindIndex(i); if n and n:find('^outbreak_') then res[#res + 1] = n .. ':' .. GetResourceState(n) end end
  return { player = src and GetPlayerName(src) or 'server', players = #GetPlayers(), debug = GlobalState.obDebug, time = GlobalState.obTime, weather = GlobalState.obWeather, resources = table.concat(res, ' ') }
end
local function writeMd()
  local pass, fail, out, lastSec = 0, 0, {}, nil
  out[#out + 1] = ('# Shakedown results — %s\n'):format(os.date('%Y-%m-%d %H:%M'))
  for _, id in ipairs(order) do
    local r = latest[id]
    if r.status == 'pass' then pass = pass + 1 elseif r.status == 'fail' then fail = fail + 1 end
  end
  out[#out + 1] = ('**%d pass · %d fail · %d marked**\n'):format(pass, fail, #order)
  out[#out + 1] = '| Step | Result | Note | When | By |\n|---|---|---|---|---|'
  for _, id in ipairs(order) do
    local r = latest[id]
    if r.sec ~= lastSec then out[#out + 1] = ('| **%s** | | | | |'):format(r.sec or ''); lastSec = r.sec end
    out[#out + 1] = ('| %s %s | %s | %s | %s | %s |'):format(id, (r.label or ''):gsub('|', '/'), (r.status or ''):upper(), (r.note or ''):gsub('|', '/'):gsub('\n', ' '), r.at or '', r.by or '')
  end
  SaveResourceFile(GetCurrentResourceName(), mdName, table.concat(out, '\n') .. '\n', -1)
end
AddEventHandler('onResourceStart', function(res) if res:find('^outbreak_') then line({ kind = 'start', resource = res, state = GetResourceState(res) }) end end)
AddEventHandler('onResourceStop', function(res) if res:find('^outbreak_') then line({ kind = 'stop', resource = res }) end end)
RegisterNetEvent('outbreak:shakedown:mark', function(id, label, status, note, sec)
  local src = source; if not GlobalState.obDebug then return end
  line({ kind = 'mark', step = id, sec = sec, label = label, status = status, note = note, ctx = ctx(src) })
  if not latest[id] then order[#order + 1] = id end
  latest[id] = { sec = sec, label = label, status = status ~= 'note' and status or (latest[id] and latest[id].status), note = note ~= '' and note or (latest[id] and latest[id].note), at = os.date('%H:%M'), by = GetPlayerName(src) }
  writeMd()
  print(('^3[SHAKEDOWN]^7 %s %s — %s %s'):format(id, tostring(status):upper(), label, note ~= '' and ('(' .. note .. ')') or ''))
end)
RegisterNetEvent('outbreak:shakedown:event', function(kind, data) line({ kind = kind, data = data, player = GetPlayerName(source) }) end)
RegisterNetEvent('outbreak:shakedown:export', function()
  local src = source; if not GlobalState.obDebug then return end
  writeMd()
  local pass, fail, notes = 0, 0, {}
  for _, id in ipairs(order) do local r = latest[id]; if r.status == 'pass' then pass = pass + 1 elseif r.status == 'fail' then fail = fail + 1; notes[#notes + 1] = id .. ': ' .. (r.note or r.label or '') end end
  print(('^3[SHAKEDOWN] SUMMARY^7 pass=%d fail=%d\n  %s\n  results: %s/%s\n  full log: %s'):format(pass, fail, table.concat(notes, '\n  '), GetResourcePath(GetCurrentResourceName()), mdName, path))
  TriggerClientEvent('ox_lib:notify', src, { title = ('Results: %d pass, %d fail'):format(pass, fail), description = 'shakedown-results.md written in outbreak_debug. Paste it to Claude.', type = 'inform', duration = 9000 })
end)
-- console: `shakedown_summary` prints the summary without a player
RegisterCommand('shakedown_summary', function(src) if src == 0 then TriggerEvent('outbreak:shakedown:export') end end, true)
line({ kind = 'boot', ctx = ctx(nil) })
