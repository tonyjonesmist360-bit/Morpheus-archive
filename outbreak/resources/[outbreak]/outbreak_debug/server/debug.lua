-- outbreak_debug/server/debug.lua — every command is ace-gated (add_ace group.admin outbreak.debug allow) AND needs ob_debug=1
local function allowed(src) return GlobalState.obDebug and (src == 0 or IsPlayerAceAllowed(src, 'outbreak.debug')) end
local function say(src, t) if src == 0 then print(t) else TriggerClientEvent('ox_lib:notify', src, { title = t, type = 'inform' }) end end

local cmds = {
  ob_kit = function(src) -- everything the slice needs to be finished in one sitting
    for _, it in ipairs({ { 'canned_beans', 2 }, { 'can_opener', 1 }, { 'water_clean', 2 }, { 'water_dirty', 1 }, { 'purify_tabs', 1 }, { 'bandage', 3 }, { 'ripped_sheet', 2 }, { 'splint', 1 }, { 'antibiotics', 1 }, { 'radio_handheld', 1 }, { 'radio_battery', 2 }, { 'plank', 4 }, { 'nails', 2 }, { 'hammer_tool', 1 } }) do
      exports.ox_inventory:AddItem(src, it[1], it[2]) end
    say(src, 'Kit given.') end,
  ob_give = function(src, a) exports.ox_inventory:AddItem(src, a[1], tonumber(a[2]) or 1); say(src, 'Gave ' .. tostring(a[1])) end,
  ob_key = function(src, a) local id = a[1] or 'sandy_bungalow'; exports.ox_inventory:AddItem(src, 'safehouse_key', 1, { house = id, description = 'DEBUG key: ' .. id }); say(src, 'Key: ' .. id) end,
  ob_needs = function(src, a) exports.outbreak_needs:consume(src, { hunger = (tonumber(a[1]) or 100) - 100, thirst = (tonumber(a[2]) or 100) - 100, fatigue = (tonumber(a[3]) or 100) - 100 }); say(src, 'Needs set.') end,
  ob_reset = function(src) exports.outbreak_needs:reset(src); say(src, 'Character state reset.') end,
  ob_state = function(src) print(json.encode(exports.outbreak_needs:getNeeds(src), { indent = true })); say(src, 'State printed to server console.') end,
  ob_time = function(src, a) exports.outbreak_world:setTime(tonumber(a[1]) or 22); say(src, 'Time set.') end,
  ob_weather = function(src, a) exports.outbreak_world:setWeather(a[1] or 'THUNDER'); say(src, 'Weather set.') end,
  ob_radio = function(src, a) exports.outbreak_radio:transmit(tonumber(a[1]) or 0, 'TEST', table.concat(a, ' ', 2) ~= '' and table.concat(a, ' ', 2) or 'Test transmission.', src) end,
  ob_horde = function(src, a) exports.outbreak_core:fireEvent('horde', src, { size = tonumber(a[1]) or 10 }) end,
  ob_rep = function(src, a) say(src, ('rep %s -> %d'):format(a[1] or 'military', exports.outbreak_faction:addRep(src, a[1] or 'military', tonumber(a[2]) or 10, 'debug'))) end,
  ob_persist = function(src) -- what survives a restart, right now
    local n = exports.outbreak_needs:getNeeds(src)
    print(('^2[OB-PERSIST]^7 needs=%s wounds=%d infected=%s'):format(n and 'ok' or 'MISSING', n and #(n.wounds or {}) or 0, tostring(n and n.infected)))
    say(src, 'Persistence snapshot printed. Now /restart the server and compare with /ob_state.') end,
}
for name, fn in pairs(cmds) do
  RegisterCommand(name, function(src, args) if allowed(src) then fn(src, args) else say(src, 'Debug off or no ace.') end end, false)
end

-- /bug: any player, rate-limited, appended to bugs.log in this resource. Read it tomorrow.
local lastBug = {}
RegisterNetEvent('outbreak:server:bug', function(b)
  local src = source
  if type(b) ~= 'table' or type(b.note) ~= 'string' then return end
  if os.time() - (lastBug[src] or 0) < 10 then return end
  lastBug[src] = os.time()
  local line = json.encode({ at = os.date('%Y-%m-%d %H:%M:%S'), by = GetPlayerName(src), id = src, x = b.x, y = b.y, z = b.z, h = b.h, street = b.street, down = b.down, hp = b.hp, note = b.note:sub(1, 240):gsub('[\r\n]', ' ') })
  local cur = LoadResourceFile(GetCurrentResourceName(), 'bugs.log') or ''
  SaveResourceFile(GetCurrentResourceName(), 'bugs.log', cur .. line .. '\n', -1)
  print(('^3[OB-BUG]^7 %s: %s'):format(GetPlayerName(src), b.note))
end)
