-- outbreak_tuning/server/tuning.lua — loads defaults + tuning.json into GlobalState.obTune. One table, live.
local FILE = 'tuning.json'
local current = {}

local function readFile()
  local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
  if not raw or raw == '' then return {} end
  local ok, t = pcall(json.decode, raw)
  if not ok or type(t) ~= 'table' then print('^1[OB-TUNE] tuning.json is not valid JSON - ignored^7'); return {} end
  return t
end
local function writeFile(t) SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(t, { indent = true }), -1) end
local function load(reason)
  local over = readFile()
  current = {}
  for k, d in pairs(TuneDefaults) do current[k] = d.v end
  local n = 0
  for k, v in pairs(over) do if TuneDefaults[k] then current[k] = v; n = n + 1 else print(('^3[OB-TUNE] unknown key in tuning.json ignored: %s^7'):format(k)) end end
  GlobalState.obTune = current
  print(('^5[OB-TUNE]^7 %d keys live (%d overridden from %s) - %s'):format((function() local c = 0 for _ in pairs(current) do c = c + 1 end return c end)(), n, FILE, reason or 'boot'))
  -- schedules re-read their minutes on the next loop; nudge the ones that exist
  pcall(function() exports.outbreak_core:rescheduleEvent('director', current['director.everyMin'], current['director.everyMax']) end)
  pcall(function() exports.outbreak_core:rescheduleEvent('tide', current['tide.everyMin'], current['tide.everyMax']) end)
  pcall(function() exports.outbreak_core:rescheduleEvent('horde', current['horde.minInterval'], current['horde.maxInterval']) end)
  pcall(function() exports.outbreak_core:rescheduleEvent('supplyTick', current['supply.tickMinutes'], current['supply.tickMinutes']) end)
end
exports('get', function(k) local v = current[k]; if v == nil then local d = TuneDefaults[k]; v = d and d.v end return v end)
exports('reload', function() load('reload') end)
exports('set', function(k, v)
  if not TuneDefaults[k] then return false, 'unknown key' end
  local over = readFile(); over[k] = v; writeFile(over); load('set ' .. k); return true
end)

RegisterCommand('ob_tune', function(src, a)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.admin') then return end
  local say = function(t) if src == 0 then print(t) else TriggerClientEvent('chat:addMessage', src, { args = { 'TUNE', (t:gsub('%^%d', '')) } }) end end
  local op = a[1]
  if op == 'set' then
    local k, raw = a[2], a[3]
    if not k or raw == nil then say('usage: ob_tune set <key> <value>') return end
    local v = tonumber(raw); if v == nil then v = (raw == 'true') and true or (raw == 'false') and false or raw end
    local ok, err = exports.outbreak_tuning:set(k, v)
    say(ok and ('^2set^7 ' .. k .. ' = ' .. tostring(v) .. ' (live)') or ('^1' .. tostring(err) .. '^7: ' .. k))
    pcall(function() exports.outbreak_log:log('tune.set', src, { key = k, value = v }) end)
  elseif op == 'reload' then load('reload'); say('reloaded tuning.json')
  elseif op == 'reset' then writeFile({}); load('reset'); say('tuning.json cleared; defaults live')
  elseif op == 'get' and a[2] then say(a[2] .. ' = ' .. tostring(current[a[2]]) .. '  (' .. ((TuneDefaults[a[2]] or {}).what or 'unknown') .. ')')
  else
    local keys = {}; for k in pairs(TuneDefaults) do keys[#keys + 1] = k end; table.sort(keys)
    local over = readFile()
    for _, k in ipairs(keys) do say(('%s%s = %s   %s'):format(over[k] ~= nil and '^3*^7 ' or '  ', k, tostring(current[k]), TuneDefaults[k].what)) end
    say('* = overridden in tuning.json. ob_tune set <key> <value> | reload | reset | get <key>')
  end
end, true)
load('boot')
