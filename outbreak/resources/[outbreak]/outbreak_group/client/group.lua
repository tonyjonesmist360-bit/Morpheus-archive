-- outbreak_group/client/group.lua — crew presentation: blips for members and pins, vitals to the HUD,
-- the wheel submenu. Positions/vitals travel as a per-player statebag (obCrew), refreshed from the
-- core tick every GroupCfg.PublishSeconds and only while you are in a crew.
local crew = nil            -- server view or nil
local memberBlips, pinBlips = {}, {}
local pending = nil         -- { name, from, until }

local function snd(k) local s = GroupCfg.Sound[k]; if s then PlaySoundFrontend(-1, s[1], s[2], true) end end
local function nameBlip(b, name) BeginTextCommandSetBlipName('STRING'); AddTextComponentString(name); EndTextCommandSetBlipName(b) end
local function clearBlips(t) for _, b in pairs(t) do if DoesBlipExist(b) then RemoveBlip(b) end end end

local function redrawPins()
  clearBlips(pinBlips); pinBlips = {}
  if not crew then return end
  for _, p in ipairs(crew.pins or {}) do
    local b = AddBlipForCoord(p.x, p.y, p.z)
    SetBlipSprite(b, GroupCfg.PinBlip.sprite); SetBlipColour(b, GroupCfg.PinBlip.colour); SetBlipScale(b, GroupCfg.PinBlip.scale); SetBlipAsShortRange(b, false)
    nameBlip(b, ('PIN: %s (%s)'):format(p.label, p.by)); pinBlips[p.id] = b
  end
end
-- member blips follow the obCrew statebag; created lazily, moved every refresh, removed when gone
local function refreshMembers()
  local seen = {}
  if crew then
    for _, m in ipairs(crew.members) do
      if m.id ~= GetPlayerServerId(PlayerId()) then
        local st = Player(m.id).state.obCrew
        if st and st.x then
          seen[m.id] = true
          if not memberBlips[m.id] or not DoesBlipExist(memberBlips[m.id]) then
            local b = AddBlipForCoord(st.x, st.y, st.z)
            SetBlipSprite(b, GroupCfg.MemberBlip.sprite); SetBlipColour(b, GroupCfg.MemberBlip.colour); SetBlipScale(b, GroupCfg.MemberBlip.scale); SetBlipAsShortRange(b, false)
            nameBlip(b, 'CREW: ' .. m.name); memberBlips[m.id] = b
          else SetBlipCoords(memberBlips[m.id], st.x, st.y, st.z) end
          SetBlipColour(memberBlips[m.id], st.down and 1 or GroupCfg.MemberBlip.colour)
        end
      end
    end
  end
  for id, b in pairs(memberBlips) do if not seen[id] then if DoesBlipExist(b) then RemoveBlip(b) end memberBlips[id] = nil end end
end

RegisterNetEvent('outbreak:group:state', function(v)
  local had = crew ~= nil
  crew = v
  redrawPins(); refreshMembers()
  if v and not had then snd('join') end
  if not v then clearBlips(memberBlips); memberBlips = {}; LocalPlayer.state:set('obCrew', nil, true); TriggerEvent('outbreak:hud:crew', nil) end
end)
RegisterNetEvent('outbreak:group:invited', function(name, from)
  pending = { name = name, from = from, until_ = GetGameTimer() + GroupCfg.InviteSeconds * 1000 }
  snd('pin')
  local r = lib.alertDialog({ header = 'Crew invite', content = ('%s wants you in **%s**. Join?'):format(from, name), centered = true, cancel = true })
  pending = nil
  TriggerServerEvent('outbreak:group:accept', r == 'confirm')
end)

-- publish my position + vitals; feed the HUD crew panel
local lastPub, lastHud = 0, 0
AddEventHandler('outbreak:tick', function(t)
  if not crew then return end
  local now = GetGameTimer()
  if now - lastPub >= GroupCfg.PublishSeconds * 1000 then
    lastPub = now
    local n = nil; pcall(function() n = exports.outbreak_needs:getNeeds() end)
    LocalPlayer.state:set('obCrew', { x = t.pos.x, y = t.pos.y, z = t.pos.z, hp = math.max(0, GetEntityHealth(t.ped) - 100), down = t.down or false,
      bleed = n and n.bleeding or false, infected = n and n.infected or false, at = now }, true)
    refreshMembers()
  end
  if now - lastHud >= 2000 then
    lastHud = now
    local rows = {}
    for _, m in ipairs(crew.members) do
      local mine = m.id == GetPlayerServerId(PlayerId())
      local st = mine and { hp = math.max(0, GetEntityHealth(t.ped) - 100), down = t.down } or Player(m.id).state.obCrew or {}
      local d = (not mine and st.x) and #(t.pos - vector3(st.x, st.y, st.z)) or 0
      rows[#rows + 1] = { name = m.name, leader = m.leader, hp = st.hp or 0, down = st.down and true or false, bleed = st.bleed or false, infected = st.infected or false, dist = math.floor(d), me = mine }
    end
    TriggerEvent('outbreak:hud:crew', { name = crew.name, members = rows })
  end
end)

-- ── the menu (wheel submenu + /crew) ──
local function nearestPlayer()
  local mpos = GetEntityCoords(PlayerPedId()); local best, bd = nil, GroupCfg.InviteRange
  for _, pid in ipairs(GetActivePlayers()) do
    if pid ~= PlayerId() then local d = #(GetEntityCoords(GetPlayerPed(pid)) - mpos); if d < bd then best, bd = GetPlayerServerId(pid), d end end
  end
  return best
end
local function pinHere(label)
  local p = GetEntityCoords(PlayerPedId())
  TriggerServerEvent('outbreak:group:pin', label, p.x, p.y, p.z); snd('pin')
end
local function pinWaypoint(label)
  local b = GetFirstBlipInfoId(8)
  if not DoesBlipExist(b) then lib.notify({ title = 'No waypoint set.', description = 'Put one on the map first.', type = 'error' }) return end
  local c = GetBlipInfoIdCoord(b)
  TriggerServerEvent('outbreak:group:pin', label, c.x, c.y, c.z); snd('pin')
end
local function askLabel(cb)
  local i = lib.inputDialog('Pin label', { { type = 'input', label = 'What is here?', placeholder = 'water · loot · meet here', required = true, max = 24 } })
  if i and i[1] then cb(i[1]) end
end
local function items()
  local out = {}
  if not crew then
    out[#out + 1] = { label = 'Start a crew', icon = 'people-group', onSelect = function()
      local i = lib.inputDialog('Crew', { { type = 'input', label = 'Crew name', placeholder = 'the motel crew', max = 24 } })
      TriggerServerEvent('outbreak:group:create', i and i[1] or '') end }
    return out
  end
  out[#out + 1] = { label = 'Invite nearest', icon = 'user-plus', onSelect = function()
    local t = nearestPlayer(); if not t then lib.notify({ title = 'Nobody close enough.', type = 'error' }) return end
    TriggerServerEvent('outbreak:group:invite', t) end }
  out[#out + 1] = { label = 'Pin here', icon = 'location-dot', onSelect = function() askLabel(pinHere) end }
  out[#out + 1] = { label = 'Pin my waypoint', icon = 'map-pin', onSelect = function() askLabel(pinWaypoint) end }
  out[#out + 1] = { label = 'Clear pins', icon = 'eraser', onSelect = function() TriggerServerEvent('outbreak:group:unpin', 'all') end }
  out[#out + 1] = { label = 'Who is in', icon = 'users', onSelect = function()
    local lines = {}
    for _, m in ipairs(crew.members) do lines[#lines + 1] = (m.leader and '★ ' or '· ') .. m.name end
    lib.notify({ title = crew.name, description = table.concat(lines, '\n'), type = 'inform', duration = 8000 }) end }
  if crew.leader == GetPlayerServerId(PlayerId()) then
    out[#out + 1] = { label = 'Cut someone loose', icon = 'user-minus', onSelect = function()
      local o = {}
      for _, m in ipairs(crew.members) do if not m.leader then o[#o + 1] = { value = m.id, label = m.name } end end
      if #o == 0 then lib.notify({ title = 'Just you.', type = 'inform' }) return end
      local i = lib.inputDialog('Cut loose', { { type = 'select', label = 'Who', options = o, required = true } })
      if i then TriggerServerEvent('outbreak:group:kick', i[1]) end end }
  end
  out[#out + 1] = { label = 'Leave the crew', icon = 'person-walking-arrow-right', onSelect = function() TriggerServerEvent('outbreak:group:leave') end }
  return out
end
exports('radialItems', items)
exports('getPins', function() return crew and crew.pins or {} end)
exports('getCrew', function() return crew end)
RegisterCommand('crew', function()
  local opts = {}
  for _, it in ipairs(items()) do opts[#opts + 1] = { title = it.label, icon = it.icon, onSelect = it.onSelect } end
  lib.registerContext({ id = 'ob_crew_ctx', title = crew and ('Crew — ' .. crew.name) or 'Crew', options = opts }); lib.showContext('ob_crew_ctx')
end, false)
RegisterCommand('pin', function(_, a) if not crew then lib.notify({ title = 'No crew.', description = 'G → Crew → Start a crew.', type = 'error' }) return end; pinHere(#a > 0 and table.concat(a, ' ') or 'pin') end, false)
CreateThread(function() Wait(3000); local v = lib.callback.await('outbreak:group:mine', false); if v then crew = v; redrawPins(); refreshMembers() end end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() then clearBlips(memberBlips); clearBlips(pinBlips); TriggerEvent('outbreak:hud:crew', nil) end end)
