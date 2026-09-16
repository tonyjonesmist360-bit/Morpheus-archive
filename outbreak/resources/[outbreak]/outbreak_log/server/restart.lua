-- outbreak_log/server/restart.lua — the daily restart is txAdmin's job (Settings -> FXServer -> Restart
-- schedule, e.g. 04:00). This side warns players at 60 / 15 / 5 / 1 minutes before ops.restartHour (tuning),
-- flushes what we can, and logs it. `restart warn <minutes>` fires a warning by hand for a manual restart.
local warned = {}
local function warn(minutes)
  local text = minutes >= 60 and 'Server restart in 1 hour. Wrap up. Nothing is lost, but be somewhere safe.'
    or minutes >= 15 and 'Server restart in 15 minutes. Head home.'
    or minutes >= 5 and 'Server restart in 5 minutes. Park the car, close the door.'
    or 'Server restart in ONE minute.'
  ExecuteCommand(('announce %s'):format(text))
  pcall(function() exports.outbreak_radio:transmit(0, 'STATIC', '...restart... ' .. minutes .. ' minutes... *static*') end)
  pcall(function() exports.outbreak_log:log('ops.restartWarn', 0, { minutes = minutes }) end)
end
local function preRestart()
  pcall(function() exports.outbreak_log:log('ops.preRestart', 0, { players = #GetPlayers() }) end)
  -- the resources that persist do so on their own timers (needs 60 s, vehicles 120 s, supply on tick, world items on change);
  -- one last nudge where an export exists
  pcall(function() for _, p in ipairs(GetPlayers()) do TriggerEvent('outbreak:server:flush', tonumber(p)) end end)
  print('^3[OB-OPS]^7 pre-restart flush done. txAdmin takes it from here.')
end
exports('preRestart', preRestart)
CreateThread(function()
  while true do
    Wait(30000)
    local hour = tonumber((GlobalState.obTune or {})['ops.restartHour']) or 4
    local now = os.date('*t')
    local minsToRestart = ((hour * 60) - (now.hour * 60 + now.min)) % (24 * 60)
    for _, m in ipairs({ 60, 15, 5, 1 }) do
      if minsToRestart == m and warned[m] ~= os.date('%Y-%m-%d') then warned[m] = os.date('%Y-%m-%d'); warn(m) end
    end
    if minsToRestart == 0 and warned[0] ~= os.date('%Y-%m-%d') then warned[0] = os.date('%Y-%m-%d'); preRestart() end
  end
end)
RegisterCommand('restart_warn', function(src, a)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.admin') then return end
  warn(tonumber(a[1]) or 5)
end, true)
