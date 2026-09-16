-- outbreak_log/server/moderation.lua — mute / kick / ban with an audit trail (kind mod.*).
-- txAdmin has its own kick/ban UI; these are the in-chat versions for DMs and they log to the same place.
-- Bans persist in bans.json (this resource); playerConnecting rejects a banned licence.
local FILE = 'bans.json'
local bans = {}
local function loadBans() local raw = LoadResourceFile(GetCurrentResourceName(), FILE); local ok, t = pcall(json.decode, raw or ''); bans = ok and type(t) == 'table' and t or {} end
local function saveBans() SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(bans, { indent = true }), -1) end
loadBans()
local function licenseOf(src)
  for _, id in ipairs(GetPlayerIdentifiers(src) or {}) do if id:find('^license:') then return id end end
  return GetPlayerIdentifiers(src) and GetPlayerIdentifiers(src)[1] or nil
end
local function say(src, t) if src == 0 then print(t) else TriggerClientEvent('chat:addMessage', src, { args = { 'MOD', t } }) end end
local function admin(src) return src == 0 or IsPlayerAceAllowed(src, 'outbreak.admin') end

-- MUTE: no chat, no radio (server-side transmit refuses), no voice (mumble mute). Minutes; 0 = until unmuted.
local muted = {}   -- src -> until (os.time) or math.huge
local function isMuted(src) local u = muted[src]; if not u then return false end; if u ~= math.huge and os.time() > u then muted[src] = nil; return false end; return true end
exports('isMuted', isMuted)
RegisterCommand('mute', function(src, a)
  if not admin(src) then return end
  local t = tonumber(a[1]); if not t or not GetPlayerName(t) then say(src, 'usage: /mute <id> [minutes] [reason]') return end
  local mins = tonumber(a[2]) or 0
  muted[t] = mins > 0 and (os.time() + mins * 60) or math.huge
  Player(t).state:set('obMuted', true, true)
  pcall(function() MumbleSetPlayerMuted(t, true) end)
  TriggerClientEvent('ox_lib:notify', t, { title = 'You have been muted.', description = mins > 0 and (mins .. ' minutes') or 'until an admin lifts it', type = 'error', duration = 10000 })
  say(src, ('muted %s (%s)'):format(GetPlayerName(t), mins > 0 and (mins .. ' min') or 'indefinite'))
  exports.outbreak_log:log('mod.mute', src, { target = t, name = GetPlayerName(t), minutes = mins, reason = table.concat(a, ' ', 3) })
end, true)
RegisterCommand('unmute', function(src, a)
  if not admin(src) then return end
  local t = tonumber(a[1]); if not t then return end
  muted[t] = nil; Player(t).state:set('obMuted', nil, true); pcall(function() MumbleSetPlayerMuted(t, false) end)
  say(src, 'unmuted ' .. tostring(GetPlayerName(t)))
  exports.outbreak_log:log('mod.unmute', src, { target = t })
end, true)
AddEventHandler('chatMessage', function(src) if src ~= 0 and isMuted(src) then CancelEvent(); TriggerClientEvent('ox_lib:notify', src, { title = 'Muted.', type = 'error' }) end end)
-- KICK / BAN
RegisterCommand('kick', function(src, a)
  if not admin(src) then return end
  local t = tonumber(a[1]); if not t or not GetPlayerName(t) then say(src, 'usage: /kick <id> [reason]') return end
  local reason = #a > 1 and table.concat(a, ' ', 2) or 'kicked by an admin'
  exports.outbreak_log:log('mod.kick', src, { target = t, name = GetPlayerName(t), reason = reason })
  DropPlayer(t, 'Kicked: ' .. reason)
  say(src, 'kicked ' .. tostring(t))
end, true)
RegisterCommand('ban', function(src, a)
  if not admin(src) then return end
  local t = tonumber(a[1]); if not t or not GetPlayerName(t) then say(src, 'usage: /ban <id> <minutes|perm> [reason]') return end
  local dur = a[2] == 'perm' and 0 or (tonumber(a[2]) or 60)
  local reason = #a > 2 and table.concat(a, ' ', 3) or 'banned by an admin'
  local lic = licenseOf(t); if not lic then say(src, 'no identifier for that player') return end
  bans[lic] = { name = GetPlayerName(t), until_ = dur > 0 and (os.time() + dur * 60) or 0, reason = reason, by = src == 0 and 'console' or GetPlayerName(src), at = os.date('%Y-%m-%d %H:%M') }
  saveBans()
  exports.outbreak_log:log('mod.ban', src, { target = t, name = GetPlayerName(t), license = lic, minutes = dur, reason = reason })
  DropPlayer(t, ('Banned%s: %s'):format(dur > 0 and (' for ' .. dur .. ' min') or '', reason))
  say(src, ('banned %s (%s)'):format(bans[lic].name, dur > 0 and (dur .. ' min') or 'permanent'))
end, true)
RegisterCommand('unban', function(src, a)
  if not admin(src) then return end
  local who = a[1]; if not who then say(src, 'usage: /unban <license:...|name>') return end
  local n = 0
  for lic, b in pairs(bans) do if lic == who or (b.name or ''):lower() == who:lower() then bans[lic] = nil; n = n + 1 end end
  saveBans(); say(src, ('lifted %d ban(s)'):format(n))
  exports.outbreak_log:log('mod.unban', src, { who = who, lifted = n })
end, true)
RegisterCommand('bans', function(src)
  if not admin(src) then return end
  local n = 0
  for lic, b in pairs(bans) do n = n + 1; say(src, ('%s  %s  %s  by %s  %s'):format(b.name or '?', b.until_ == 0 and 'PERM' or os.date('%m-%d %H:%M', b.until_), b.reason or '', b.by or '?', lic)) end
  if n == 0 then say(src, 'no bans') end
end, true)
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
  local src = source
  deferrals.defer(); Wait(0)
  local lic = licenseOf(src)
  local b = lic and bans[lic]
  if b then
    if b.until_ ~= 0 and os.time() > b.until_ then bans[lic] = nil; saveBans()
    else deferrals.done(('You are banned%s. Reason: %s'):format(b.until_ == 0 and '' or (' until ' .. os.date('%Y-%m-%d %H:%M', b.until_)), b.reason or '')); return end
  end
  deferrals.done()
end)
