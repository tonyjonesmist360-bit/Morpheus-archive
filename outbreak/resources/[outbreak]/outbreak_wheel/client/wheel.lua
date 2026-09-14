-- outbreak_wheel/client/wheel.lua
-- Builds the radial from STATE at open time: your wounds, the nearest downed player,
-- what's in your pockets, what you're standing next to. Nothing here owns state.
local function has(item) local ok, n = pcall(function() return exports.ox_inventory:Search('count', item) end) return ok and (n or 0) > 0 end

local function nearestDowned()
  local mpos = GetEntityCoords(PlayerPedId()); local best, bd = nil, 2.5
  for _, pid in ipairs(GetActivePlayers()) do
    if pid ~= PlayerId() then
      local sid = GetPlayerServerId(pid)
      if Player(sid).state.downState then
        local d = #(GetEntityCoords(GetPlayerPed(pid)) - mpos); if d < bd then best, bd = sid, d end
      end
    end
  end
  return best
end

local function nearestPlayer()
  local mpos = GetEntityCoords(PlayerPedId()); local best, bd = nil, 3.0
  for _, pid in ipairs(GetActivePlayers()) do
    if pid ~= PlayerId() then local d = #(GetEntityCoords(GetPlayerPed(pid)) - mpos); if d < bd then best, bd = GetPlayerServerId(pid), d end end
  end
  return best
end

local function build()
  local items = {}
  local needs = exports.outbreak_needs:getNeeds()
  local t = exports.outbreak_core:getTick()

  -- MY BODY
  local wounds = {}
  for part, w in pairs(needs.wounds or {}) do if not w.treated then wounds[#wounds + 1] = { part = part, kind = w.kind } end end
  if #wounds > 0 then
    local sub = {}
    for _, w in ipairs(wounds) do
      local item = (w.kind == 'fracture') and 'splint' or (has('bandage') and 'bandage' or 'ripped_sheet')
      sub[#sub + 1] = { label = ('%s: %s'):format(w.part:gsub('_', ' '), w.kind), icon = 'bandage',
        onSelect = function()
          if not has(item) then lib.notify({ title = 'Need a ' .. item:gsub('_', ' '), type = 'error' }) return end
          local mult = 1.0
          pcall(function() mult = exports.outbreak_skills:effects('medicine').bandageTime; if exports.outbreak_skills:hasTrait('hemophobic') then mult = mult * 2 end end)
          if exports.outbreak_emotes:action('treat', math.floor((item == 'splint' and 12000 or 6000) * mult), 'Treating ' .. w.part:gsub('_', ' ')) then
            TriggerServerEvent('outbreak:server:treat', w.part, item)
          end
        end }
    end
    lib.registerRadial({ id = 'ob_wounds', items = sub })
    items[#items + 1] = { label = ('Treat (%d)'):format(#wounds), icon = 'kit-medical', menu = 'ob_wounds' }
  end

  -- SOMEONE DOWN NEXT TO ME
  local downed = nearestDowned()
  if downed then
    local st = Player(downed).state.downState
    items[#items + 1] = { label = st == 'unconscious' and 'Shake awake' or 'Stabilize', icon = 'hand-holding-medical', onSelect = function()
      if exports.outbreak_emotes:action('treat', st == 'unconscious' and 8000 or 12000, st == 'unconscious' and 'Shaking them...' or 'Stabilizing...') then
        TriggerServerEvent('outbreak:server:helpPlayer', downed, st) end end }
    items[#items + 1] = { label = 'Check pulse', icon = 'heart-pulse', onSelect = function()
      if exports.outbreak_emotes:action('pulse', 3000, 'Checking pulse...') then
        lib.notify({ title = st == 'unconscious' and 'Out cold. Breathing.' or 'Weak. Fading. Bleeding out.', type = 'inform' }) end end }
    items[#items + 1] = { label = 'Carry', icon = 'person-walking', onSelect = function() TriggerServerEvent('outbreak:server:carry', downed, 'carry') end }
    items[#items + 1] = { label = 'Drag', icon = 'arrows-left-right', onSelect = function() TriggerServerEvent('outbreak:server:carry', downed, 'drag') end }
    items[#items + 1] = { label = 'Search pockets', icon = 'hand', onSelect = function()
      if exports.outbreak_emotes:action('search', 5000, 'Rifling pockets...') then TriggerServerEvent('outbreak:server:searchDowned', downed) end end }
  elseif LocalPlayer.state.carrying then
    items[#items + 1] = { label = 'Put down', icon = 'hand', onSelect = function() TriggerServerEvent('outbreak:server:carry', nil, 'stop') end }
    local pos = GetEntityCoords(PlayerPedId())
    local veh = GetClosestVehicle(pos.x, pos.y, pos.z, 5.0, 0, 71)
    if veh ~= 0 then items[#items + 1] = { label = 'Load into vehicle', icon = 'truck-medical', onSelect = function() TriggerServerEvent('outbreak:server:loadPatient', NetworkGetNetworkIdFromEntity(veh)) end } end
  end
  -- a downed player inside a nearby vehicle: unload them
  do
    local mpos = GetEntityCoords(PlayerPedId())
    for _, pid in ipairs(GetActivePlayers()) do
      if pid ~= PlayerId() then
        local sid = GetPlayerServerId(pid); local pp = GetPlayerPed(pid)
        if Player(sid).state.downState and IsPedInAnyVehicle(pp, false) and #(GetEntityCoords(pp) - mpos) < 6.0 then
          items[#items + 1] = { label = 'Unload patient', icon = 'person-falling', onSelect = function() TriggerServerEvent('outbreak:server:unloadPatient', sid) end }
          break
        end
      end
    end
  end

  -- TREAT SOMEONE ELSE'S WOUNDS (conscious)
  local other = nearestPlayer()
  if other and not downed then
    items[#items + 1] = { label = 'Look', icon = 'eye', onSelect = function() ExecuteCommand('look') end }
    items[#items + 1] = { label = 'Treat their wound', icon = 'bandage', onSelect = function()
      local input = lib.inputDialog('Treat', { { type = 'select', label = 'Body part', required = true, options = {
        { value = 'head', label = 'Head' }, { value = 'torso', label = 'Torso' }, { value = 'left_arm', label = 'Left arm' }, { value = 'right_arm', label = 'Right arm' }, { value = 'left_leg', label = 'Left leg' }, { value = 'right_leg', label = 'Right leg' } } },
        { type = 'select', label = 'With', required = true, options = { { value = 'bandage', label = 'Bandage' }, { value = 'ripped_sheet', label = 'Ripped sheet' }, { value = 'splint', label = 'Splint' } } } })
      if input and exports.outbreak_emotes:action('treat', 6000, 'Treating...') then TriggerServerEvent('outbreak:server:treatOther', other, input[1], input[2]) end end }
  end

  -- ALWAYS
  items[#items + 1] = { label = 'Radio', icon = 'walkie-talkie', onSelect = function() TriggerEvent('outbreak:client:openRadio') end }
  items[#items + 1] = { label = 'Listen', icon = 'ear-listen', onSelect = function() ExecuteCommand('listen') end }
  items[#items + 1] = { label = 'Emotes', icon = 'masks-theater', onSelect = function() ExecuteCommand('semotes') end }
  items[#items + 1] = { label = 'Surrender', icon = 'hands', onSelect = function() exports.outbreak_emotes:loopAction('surrender') end }
  items[#items + 1] = { label = 'Vitals', icon = 'heart', onSelect = function()
    local n = needs
    local w = 0; for _, x in pairs(n.wounds or {}) do if not x.treated then w = w + 1 end end
    lib.notify({ title = ('Food %d  Water %d  Rest %d'):format(n.hunger, n.thirst, n.fatigue), description = ('%d open wound(s). %s'):format(w, n.infected and 'INFECTED.' or 'No fever.'), type = 'inform', duration = 6000 }) end }
  items[#items + 1] = { label = 'Set something down', icon = 'hand', onSelect = function() ExecuteCommand('placeitem') end }
  items[#items + 1] = { label = 'Skills', icon = 'graduation-cap', onSelect = function() ExecuteCommand('skills') end }
  if GetResourceState('outbreak_intel') == 'started' then items[#items + 1] = { label = 'Journal', icon = 'book', onSelect = function() ExecuteCommand('journal') end } end
  if GetResourceState('outbreak_craft') == 'started' then items[#items + 1] = { label = 'Craft', icon = 'hammer', onSelect = function() ExecuteCommand('craft') end } end
  if LocalPlayer.state.isDM then items[#items + 1] = { label = 'DIRECTOR', icon = 'clapperboard', onSelect = function() ExecuteCommand('dm') end } end
  if GlobalState.obDebug then items[#items + 1] = { label = 'DEBUG', icon = 'bug', onSelect = function() ExecuteCommand('ob_debugmenu') end } end
  return items
end

-- DOWNED WHEEL: the few things a body on the floor can still do.
local function buildDowned(st)
  local items = {}
  if st == 'incapacitated' then
    items[#items + 1] = { label = has('splint') and 'Splint yourself' or 'Splint yourself (no splint)', icon = 'crutch', onSelect = function()
      if not has('splint') then lib.notify({ title = 'You need a splint.', type = 'error' }) return end
      TriggerServerEvent('outbreak:server:trySelfStabilize') end }
    items[#items + 1] = { label = has('adrenaline_shot') and 'Adrenaline' or 'Adrenaline (none)', icon = 'syringe', onSelect = function()
      if not has('adrenaline_shot') then lib.notify({ title = 'No adrenaline shot.', type = 'error' }) return end
      TriggerServerEvent('outbreak:server:useAdrenaline') end }
  end
  items[#items + 1] = { label = 'Distress call', icon = 'tower-broadcast', onSelect = function() ExecuteCommand('ob_distress') end }
  items[#items + 1] = { label = 'Radio', icon = 'walkie-talkie', onSelect = function() TriggerEvent('outbreak:client:openRadio') end }
  items[#items + 1] = { label = 'Vitals', icon = 'heart', onSelect = function()
    local n = exports.outbreak_needs:getNeeds() or {}
    lib.notify({ title = ('%s'):format(st:upper()), description = ('Food %d  Water %d  Rest %d. %s'):format(n.hunger or 0, n.thirst or 0, n.fatigue or 0, n.infected and 'INFECTED.' or ''), type = 'inform', duration = 6000 }) end }
  items[#items + 1] = { label = 'OOC', icon = 'comment-dots', onSelect = function() lib.notify({ title = 'Press T, then /ooc your message', type = 'inform' }) end }
  if LocalPlayer.state.isDM then items[#items + 1] = { label = 'DIRECTOR', icon = 'clapperboard', onSelect = function() ExecuteCommand('dm') end } end
  return items
end

RegisterCommand('ob_wheel', function()
  local st = LocalPlayer.state.downState
  if st then
    lib.registerRadial({ id = 'ob_wheel_down', items = buildDowned(st) })
    lib.showRadial('ob_wheel_down')
    return
  end
  lib.registerRadial({ id = 'ob_wheel', items = build() })
  lib.showRadial('ob_wheel')
end, false)
