-- outbreak_log/server/perf.lua — how late is the server? One 1 s heartbeat measures its own lateness
-- (the same starvation every resource feels). Per-resource CPU is txAdmin's resource monitor / `resmon`;
-- from Lua we can see the loop, memory, players and our schedulers. `server stats` prints it.
local samples, worst, alerts = {}, 0, 0
local lastAlert = 0
CreateThread(function()
  local last = GetGameTimer()
  while true do
    Wait(1000)
    local now = GetGameTimer(); local late = now - last - 1000; last = now
    samples[#samples + 1] = late; if #samples > 300 then table.remove(samples, 1) end
    if late > worst then worst = late end
    local limit = tonumber((GlobalState.obTune or {})['ops.perfAlertMs']) or 500
    if late > limit and now - lastAlert > 60000 then
      lastAlert = now; alerts = alerts + 1
      print(('^1[OB-PERF]^7 server loop %d ms late (limit %d). players=%d mem=%.0f KB'):format(late, limit, #GetPlayers(), collectgarbage('count')))
      pcall(function() exports.outbreak_log:log('perf.alert', 0, { lateMs = late, players = #GetPlayers() }) end)
    end
  end
end)
local function stats()
  local sum, n = 0, #samples; for _, s in ipairs(samples) do sum = sum + s end
  local sch = {}; pcall(function() for k, s in pairs(exports.outbreak_core:schedules() or {}) do sch[#sch + 1] = ('%s %s-%s min'):format(k, tostring(s.min), tostring(s.max)) end end)
  local res = 0; for i = 0, GetNumResources() - 1 do local r = GetResourceByFindIndex(i); if r and r:find('^outbreak_') and GetResourceState(r) == 'started' then res = res + 1 end end
  return {
    players = #GetPlayers(), uptimeMin = math.floor(GetGameTimer() / 60000), memKB = math.floor(collectgarbage('count')),
    loopAvgLateMs = n > 0 and math.floor(sum / n) or 0, loopWorstLateMs = worst, alerts = alerts, outbreakResources = res, schedules = table.concat(sch, ', '),
    time = GlobalState.obTime, weather = GlobalState.obWeather, tide = GlobalState.obTide and GlobalState.obTide.zone or nil,
  }
end
exports('stats', stats)
RegisterCommand('server', function(src, a)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.admin') then return end
  if a[1] ~= 'stats' then return end
  local s = stats()
  local lines = {
    ('players %d · up %d min · lua mem %d KB · outbreak resources %d'):format(s.players, s.uptimeMin, s.memKB, s.outbreakResources),
    ('server loop late: avg %d ms, worst %d ms, alerts %d (target < 100, alert > %s)'):format(s.loopAvgLateMs, s.loopWorstLateMs, s.alerts, tostring((GlobalState.obTune or {})['ops.perfAlertMs'] or 500)),
    ('world: %s:00 %s%s'):format(tostring(s.time), tostring(s.weather), s.tide and (' · tide at ' .. tostring(s.tide)) or ''),
    'schedules: ' .. (s.schedules ~= '' and s.schedules or '-'),
    'per-resource CPU: txAdmin -> Resources, or `resmon 1` in the F8 console (client) - not readable from Lua',
  }
  for _, l in ipairs(lines) do if src == 0 then print(l) else TriggerClientEvent('chat:addMessage', src, { args = { 'STATS', l } }) end end
end, true)
-- weekly-ish report line: every 6 hours the worst/avg lateness is logged, so `/logs kind:perf` shows the pattern
CreateThread(function() while true do Wait(6 * 3600 * 1000); local s = stats(); pcall(function() exports.outbreak_log:log('perf.report', 0, s) end); worst = 0 end end)
