-- outbreak_minigames/server/tokens.lua — SERVER AUTHORITY for skill checks (Q1, closes KNOWN_LIMITATIONS #1).
-- The client asks for a token BEFORE a minigame (game, opts, target). The server records who, what,
-- for which target, and a min/max window derived from the game's own timing. The client hands the
-- token back with the result; the owning server handler calls consume(src, token, target): no token,
-- wrong player, wrong target, already used, too fast (bot) or too slow (stale) -> nothing happens.
local Tokens = {}   -- token -> { src, game, target, at, min, max }
local Windows = {
  -- ms: [min] a human cannot finish faster; [max] after this the attempt is stale
  pinsweep = function(o) local pins = tonumber(o.pins) or 3; return pins * 450, pins * 9000 + 20000 end,
  pry      = function(o) local pulls = tonumber(o.pulls) or 3; return pulls * 350, pulls * 8000 + 20000 end,
  splice   = function(o) local len = tonumber(o.length) or 5; return (tonumber(o.showMs) or 1800) + len * 250, 90000 end,
}
local function newToken()
  local t = {}
  for _ = 1, 16 do t[#t + 1] = ('%x'):format(math.random(0, 15)) end
  return table.concat(t)
end
lib.callback.register('outbreak:minigame:request', function(src, game, opts, target)
  local w = Windows[game]; if not w then return nil end
  if type(target) ~= 'string' or #target > 96 then return nil end
  opts = type(opts) == 'table' and opts or {}
  -- one live token per player per target: asking again replaces (a cancelled game must not leave a spare)
  for tok, t in pairs(Tokens) do if t.src == src and t.target == target then Tokens[tok] = nil end end
  local min, max = w(opts)
  local tok = newToken()
  Tokens[tok] = { src = src, game = game, target = target, at = GetGameTimer(), min = min, max = max }
  return tok
end)
local function consume(src, token, target)
  local t = type(token) == 'string' and Tokens[token] or nil
  if not t then return false, 'no token' end
  if t.src ~= src then return false, 'not yours' end
  if t.target ~= target then return false, 'wrong target' end
  Tokens[token] = nil
  local el = GetGameTimer() - t.at
  if el < t.min then
    pcall(function() exports.outbreak_log:log('minigame.reject', src, { target = target, game = t.game, elapsedMs = el, minMs = t.min, why = 'too fast' }) end)
    return false, 'too fast'
  end
  if el > t.max then return false, 'stale' end
  return true, t.game
end
exports('consume', consume)
exports('peek', function(token) return Tokens[token] end)
CreateThread(function()
  while true do
    Wait(60000)
    local now = GetGameTimer()
    for tok, t in pairs(Tokens) do if now - t.at > t.max + 5000 then Tokens[tok] = nil end end
  end
end)
AddEventHandler('playerDropped', function() local src = source; for tok, t in pairs(Tokens) do if t.src == src then Tokens[tok] = nil end end end)
