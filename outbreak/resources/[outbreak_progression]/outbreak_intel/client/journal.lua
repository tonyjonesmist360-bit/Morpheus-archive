-- outbreak_intel/client/journal.lua — Field Journal: NUI bridge + controller relay
local open = false
local latest = { intel = {}, opps = {} }

AddEventHandler('outbreak:intel:journalData', function(intel, opps)
  latest = { intel = intel, opps = opps }
  if open then SendNUIMessage({ action = 'data', intel = intel, opps = opps, catalog = IntelCatalog }) end
end)

-- v0.22: the journal is also the quest log. Factions (standing) and Objectives (home needs,
-- the first-ten-minutes guide, active chains) are gathered here from soft exports, never owned.
local function extras()
  local ex = { factions = {}, objectives = {} }
  pcall(function() ex.factions = exports.outbreak_faction:getStandings() or {} end)
  pcall(function()
    local steps = exports.outbreak_spawn:onboarding()
    for _, s in ipairs(steps or {}) do ex.objectives[#ex.objectives + 1] = { text = s.text, done = s.done, kind = 'guide' } end
  end)
  pcall(function()
    for _, f in ipairs(exports.outbreak_items:lootLog() or {}) do ex.objectives[#ex.objectives + 1] = { text = f.where .. ': ' .. f.text, kind = 'find', done = true } end
  end)
  pcall(function()
    local h = lib.callback.await('outbreak:supply:home', false)
    if h then for _, n in ipairs(h.needs or {}) do ex.objectives[#ex.objectives + 1] = { text = (h.label or 'Home') .. ': ' .. n.text, status = n.status, kind = 'home' } end end
  end)
  return ex
end
local function openJournal()
  if open or LocalPlayer.state.downState then return end
  open = true
  TriggerServerEvent('outbreak:intel:openJournal')   -- fresh payload arrives via journalData
  local ex = extras()
  SendNUIMessage({ action = 'open', intel = latest.intel, opps = latest.opps, catalog = IntelCatalog, factions = ex.factions, objectives = ex.objectives })
  SetNuiFocus(true, false)
  pcall(function() exports.outbreak_emotes:loopAction('read') end)
  -- controller relay: NUI can't read the pad, so we poll and forward
  CreateThread(function()
    while open do
      Wait(0)
      DisableAllControlActions(0)
      if IsDisabledControlJustPressed(0, 27)  then SendNUIMessage({ action = 'nav', key = 'up' }) end     -- DPAD_UP
      if IsDisabledControlJustPressed(0, 173) then SendNUIMessage({ action = 'nav', key = 'down' }) end   -- DPAD_DOWN
      if IsDisabledControlJustPressed(0, 174) then SendNUIMessage({ action = 'nav', key = 'left' }) end   -- DPAD_LEFT
      if IsDisabledControlJustPressed(0, 175) then SendNUIMessage({ action = 'nav', key = 'right' }) end  -- DPAD_RIGHT
      if IsDisabledControlJustPressed(0, 191) then SendNUIMessage({ action = 'nav', key = 'enter' }) end  -- A / Enter
      if IsDisabledControlJustPressed(0, 194) then SendNUIMessage({ action = 'nav', key = 'back' }) end   -- B / Backspace
      if IsDisabledControlJustPressed(0, 200) then SendNUIMessage({ action = 'nav', key = 'back' }) end   -- Esc
    end
  end)
end

local function closeJournal()
  if not open then return end
  open = false
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'close' })
  pcall(function() exports.outbreak_emotes:stopAction() end)
end

RegisterNUICallback('close', function(_, cb) cb('ok'); closeJournal() end)
RegisterNUICallback('choose', function(data, cb) cb('ok'); TriggerServerEvent('outbreak:opp:choose', data.opp, data.solution) end)
RegisterNUICallback('join', function(data, cb) cb('ok'); TriggerServerEvent('outbreak:opp:join', data.opp) end)

RegisterCommand('journal', function() if open then closeJournal() else openJournal() end end, false)
exports('openJournal', openJournal)
exports('closeJournal', closeJournal)
