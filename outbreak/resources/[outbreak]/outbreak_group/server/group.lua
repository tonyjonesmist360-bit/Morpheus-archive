-- outbreak_group/server/group.lua — the crew registry. Session-only: a crew dies with the server.
local groups, memberOf, invites, nextId = {}, {}, {}, 1   -- invites[target] = { gid, from, at }

local function view(g)
  local members = {}
  for s in pairs(g.members) do members[#members + 1] = { id = s, name = GetPlayerName(s) or ('#' .. s), leader = s == g.leader } end
  table.sort(members, function(a, b) return a.id < b.id end)
  return { id = g.id, name = g.name, leader = g.leader, members = members, pins = g.pins }
end
local function push(g)
  local v = view(g)
  for s in pairs(g.members) do TriggerClientEvent('outbreak:group:state', s, v) end
end
local function notify(src, t, d, ty) TriggerClientEvent('ox_lib:notify', src, { title = t, description = d, type = ty or 'inform' }) end
local function leave(src, silent)
  local gid = memberOf[src]; if not gid then return end
  local g = groups[gid]; if not g then memberOf[src] = nil return end
  g.members[src] = nil; memberOf[src] = nil
  Player(src).state:set('crew', nil, true)
  TriggerClientEvent('outbreak:group:state', src, nil)
  if next(g.members) == nil then groups[gid] = nil return end
  if g.leader == src then g.leader = next(g.members) end
  push(g)
  if not silent then for s in pairs(g.members) do notify(s, (GetPlayerName(src) or 'Someone') .. ' left the crew.') end end
end

RegisterNetEvent('outbreak:group:create', function(name)
  local src = source
  if memberOf[src] then notify(src, 'You are already in a crew.', nil, 'error') return end
  name = type(name) == 'string' and name:sub(1, 24) or ''
  if name == '' then name = (GetPlayerName(src) or 'Nameless') .. "'s crew" end
  local g = { id = nextId, name = name, leader = src, members = { [src] = true }, pins = {} }
  groups[nextId] = g; memberOf[src] = nextId; nextId = nextId + 1
  Player(src).state:set('crew', g.id, true)
  push(g); notify(src, 'Crew formed: ' .. name, 'Invite people from the wheel. They will see your pins and your vitals.', 'success')
  pcall(function() exports.outbreak_log:log('crew.create', src, { name = name }) end)
end)
RegisterNetEvent('outbreak:group:invite', function(target)
  local src = source; target = tonumber(target)
  local gid = memberOf[src]; local g = gid and groups[gid]
  if not g then notify(src, 'Form a crew first.', nil, 'error') return end
  if not target or not GetPlayerPed(target) or GetPlayerPed(target) == 0 then return end
  if memberOf[target] then notify(src, 'They are already in a crew.', nil, 'error') return end
  local n = 0; for _ in pairs(g.members) do n = n + 1 end
  if n >= GroupCfg.MaxMembers then notify(src, 'Crew is full.', nil, 'error') return end
  if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) > GroupCfg.InviteRange + 2.0 then return end
  invites[target] = { gid = gid, from = src, at = os.time() }
  TriggerClientEvent('outbreak:group:invited', target, g.name, GetPlayerName(src) or '?')
  notify(src, 'Invited ' .. (GetPlayerName(target) or '?') .. '.', 'They have ' .. GroupCfg.InviteSeconds .. ' seconds.')
end)
RegisterNetEvent('outbreak:group:accept', function(yes)
  local src = source; local inv = invites[src]; invites[src] = nil
  if not inv or not yes then return end
  if os.time() - inv.at > GroupCfg.InviteSeconds then notify(src, 'That invite lapsed.', nil, 'error') return end
  local g = groups[inv.gid]; if not g then return end
  if memberOf[src] then leave(src, true) end
  g.members[src] = true; memberOf[src] = g.id
  Player(src).state:set('crew', g.id, true)
  push(g)
  for s in pairs(g.members) do notify(s, (GetPlayerName(src) or 'Someone') .. ' joined the crew.', nil, 'success') end
end)
RegisterNetEvent('outbreak:group:leave', function() leave(source) end)
RegisterNetEvent('outbreak:group:kick', function(target)
  local src = source; local g = memberOf[src] and groups[memberOf[src]]
  target = tonumber(target)
  if not g or g.leader ~= src or not target or not g.members[target] or target == src then return end
  notify(target, 'You were cut loose from ' .. g.name .. '.', nil, 'error')
  leave(target)
end)
-- pins: shared markers. Server owns the list; every member gets the same view.
RegisterNetEvent('outbreak:group:pin', function(label, x, y, z)
  local src = source; local g = memberOf[src] and groups[memberOf[src]]; if not g then return end
  if type(x) ~= 'number' or type(y) ~= 'number' or type(z) ~= 'number' then return end
  if #g.pins >= GroupCfg.MaxPins then table.remove(g.pins, 1) end
  local id = (g.lastPin or 0) + 1; g.lastPin = id
  g.pins[#g.pins + 1] = { id = id, label = (type(label) == 'string' and label:sub(1, 24) or 'pin'), x = x, y = y, z = z, by = GetPlayerName(src) or '?' }
  push(g)
end)
RegisterNetEvent('outbreak:group:unpin', function(id)
  local src = source; local g = memberOf[src] and groups[memberOf[src]]; if not g then return end
  if id == 'all' then g.pins = {} else for i, p in ipairs(g.pins) do if p.id == id then table.remove(g.pins, i) break end end end
  push(g)
end)
AddEventHandler('playerDropped', function() leave(source, true); invites[source] = nil end)
lib.callback.register('outbreak:group:mine', function(src) local g = memberOf[src] and groups[memberOf[src]]; return g and view(g) or nil end)
exports('groupOf', function(src) return memberOf[src] end)
exports('members', function(gid) local g = groups[gid]; if not g then return {} end local out = {}; for s in pairs(g.members) do out[#out + 1] = s end return out end)
