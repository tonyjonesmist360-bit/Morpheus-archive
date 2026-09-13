-- outbreak_debug/client/shakedown.lua — the in-game shakedown panel. Marks write to the server log; the log is what Claude reads.
local open, sel = false, 1
local Steps = {
  { sec = '0 Boot',        id = 'B1', label = 'Server ONLINE, no red outbreak_* lines',          cmd = 'watch console',          expect = 'clean ensure' },
  { sec = '0 Boot',        id = 'B2', label = 'Client joined, F8 clean',                          cmd = 'connect localhost',      expect = 'no red lines' },
  { sec = '1 Instrument',  id = 'A1', label = 'Anim dictionaries',                                cmd = '/ob_animcheck',          expect = '0 missing' },
  { sec = '1 Instrument',  id = 'A2', label = 'Prop models',                                      cmd = '/ob_models …',           expect = 'all ok' },
  { sec = '1 Instrument',  id = 'A3', label = 'Shelf names read',                                 cmd = '/ob_walk in a 24/7',     expect = 'names in F8' },
  { sec = '2 Survivor',    id = 'C1', label = 'Creator opens on first join',                      cmd = 'join',                   expect = 'illenium creator' },
  { sec = '2 Survivor',    id = 'C2', label = 'WHO WERE YOU accepted',                            cmd = 'fill it',                expect = 'traits in /skills' },
  { sec = '2 Survivor',    id = 'C3', label = 'Relog: no creator',                                cmd = 'relog',                  expect = 'straight in' },
  { sec = '3 Spawn/HUD',   id = 'S1', label = 'Scenario spawn + kit',                             cmd = 'look',                   expect = 'story, TAB has kit' },
  { sec = '3 Spawn/HUD',   id = 'S2', label = 'HUD bars + noise dot',                             cmd = 'look',                   expect = 'bottom-left' },
  { sec = '3 Spawn/HUD',   id = 'R1', label = 'Radio tunes, scenario transmission arrives',       cmd = 'use radio → 4',          expect = '≈20 s' },
  { sec = '3 Spawn/HUD',   id = 'R2', label = 'Channel filter',                                   cmd = '/ob_radio 9 test',       expect = 'NOT received' },
  { sec = '4 Noise',       id = 'Z1', label = 'Crouch unnoticed / sprint chased',                 cmd = 'Ctrl then sprint',       expect = 'ripple grows' },
  { sec = '4 Noise',       id = 'Z2', label = 'Spawn + gunshot convergence',                      cmd = '/ob_zombie 3, shoot',    expect = 'red ripple' },
  { sec = '4 Noise',       id = 'Z3', label = 'Listen',                                           cmd = 'G → Listen',             expect = 'count+direction' },
  { sec = '4 Noise',       id = 'Z4', label = 'Night blackout + runners; thunder surge',          cmd = '/ob_time 23; /ob_weather THUNDER', expect = 'dark, fast ones' },
  { sec = '5 Wounds',      id = 'W1', label = 'Scratch → moodles',                                cmd = 'get hit',                expect = 'Bleeding + wound' },
  { sec = '5 Wounds',      id = 'W2', label = 'Treat via wheel',                                  cmd = 'G → Treat',              expect = 'anim, wound gone' },
  { sec = '5 Wounds',      id = 'W3', label = 'Fracture slows, splint clears',                    cmd = '/ob_wound right_leg fracture', expect = 'slow → ok' },
  { sec = '5 Wounds',      id = 'W4', label = 'Infection from bites',                             cmd = 'get bitten',             expect = 'Anxious moodle' },
  { sec = '6 Property',    id = 'H1', label = 'Door: occupant or story',                          cmd = '/ob_tp sandy_bungalow',  expect = 'one of the two' },
  { sec = '6 Property',    id = 'H2', label = 'Search spots + picked-clean',                      cmd = 'search twice',           expect = 'loot then refusal' },
  { sec = '6 Property',    id = 'H3', label = 'Cooldown survives resource restart',               cmd = 'restart outbreak_items', expect = 'still clean' },
  { sec = '6 Property',    id = 'H4', label = 'Claim → key; storage needs key',                   cmd = 'claim, drop key',        expect = 'refused w/o key' },
  { sec = '6 Property',    id = 'H5', label = 'Shelter inside interior + Leave',                  cmd = '/ob_tp grove_house',     expect = 'interior loads' },
  { sec = '6 Property',    id = 'H6', label = 'Barricade renders',                                cmd = '2 planks+nails+hammer',  expect = 'planks at door' },
  { sec = '7 World',       id = 'M1', label = 'Place item ghost → prop; Take back',               cmd = 'G → Set something down', expect = 'bottle on ground' },
  { sec = '7 World',       id = 'M2', label = 'Crate storage + padlock + force',                  cmd = 'place crate',            expect = 'stash; pin sweep' },
  { sec = '7 World',       id = 'M3', label = 'Note written, placed, read',                       cmd = '/writenote',             expect = 'text + name' },
  { sec = '7 World',       id = 'M4', label = 'Shelf grab',                                       cmd = 'Grab in 24/7',           expect = 'ADDED ×1, prop gone' },
  { sec = '8 Vehicles',    id = 'V1', label = 'Car state rolled (locked/dead/fuel)',              cmd = 'approach a car',         expect = 'statebag veh' },
  { sec = '8 Vehicles',    id = 'V2', label = 'Pry → reasons cycle → splice',                     cmd = 'crowbar, sit, E',        expect = 'hotwired' },
  { sec = '8 Vehicles',    id = 'V3', label = 'Fuel burns; siphon; pour',                         cmd = 'drive, hose, can',       expect = 'numbers move' },
  { sec = '8 Vehicles',    id = 'V4', label = 'Claim with key blank; survives restart',           cmd = 'cut key, restart',       expect = 'still there' },
  { sec = '9 Downed',      id = 'D1', label = 'Unconscious wakes at 2 min',                       cmd = '/ob_down',               expect = 'veil, wake' },
  { sec = '9 Downed',      id = 'D2', label = 'Incapacitated; self-splint',                       cmd = 'get shot; E',            expect = 'red veil' },
  { sec = '9 Downed',      id = 'D3', label = 'Critical → carry → load → station → treat',       cmd = 'two people',             expect = 'recovering' },
  { sec = '9 Downed',      id = 'D4', label = 'Adrenaline while incapacitated',                   cmd = '/ob_give adrenaline_shot 1', expect = 'up at 10%' },
  { sec = '9 Downed',      id = 'D5', label = 'Permadeath: epitaph, /fallen, corpse, no reload',  cmd = 'let critical expire',    expect = 'all four' },
  { sec = '10 Restart',    id = 'P1', label = 'Everything persists through server restart',       cmd = '/ob_persist, restart, /ob_state', expect = 'match' },
  { sec = '11 Director',   id = 'X1', label = 'F10 menu; Helicopter crash scene',                 cmd = 'F10 → Scenes',           expect = 'wrecks, MAYDAY, horde' },
  { sec = '11 Director',   id = 'X2', label = 'Ghost mode',                                       cmd = 'World → Ghost',          expect = 'invisible' },
  { sec = '12 Progression',id = 'O1', label = 'Grapeseed rumor → radius blip → confirm',          cmd = 'tune 4, drive in',       expect = 'journal moves' },
  { sec = '12 Progression',id = 'O2', label = 'Warning → deliver → wave',                         cmd = '/ob_opp warn …; /ob_opp wave …', expect = 'defense runs' },
  { sec = '13 Pad',        id = 'G1', label = 'Controller: Up inv, Down wheel, Left radio, B cancel', cmd = 'pad',               expect = 'all four' },
}

local function push(action) SendNUIMessage({ action = action, steps = Steps, sel = sel - 1 }) end
local function toggle()
  if not GlobalState.obDebug then return end
  open = not open
  if open then push('open'); SetNuiFocus(false, false) else SendNUIMessage({ action = 'close' }) end
end
local function mark(status, note)
  local s = Steps[sel]; if not s then return end
  s.status = status; if note and note ~= '' then s.note = note end
  push('update')
  TriggerServerEvent('outbreak:shakedown:mark', s.id, s.label, status, s.note or '')
  if sel < #Steps then sel = sel + 1; push('update') end
end
-- panel is passive (no NUI focus) so you keep playing; keys are polled while it's open
CreateThread(function()
  while true do
    Wait(0)
    if not open then Wait(300) goto continue end
    if IsControlJustPressed(0, 172) then sel = math.max(1, sel - 1); push('update') end        -- up arrow
    if IsControlJustPressed(0, 173) then sel = math.min(#Steps, sel + 1); push('update') end   -- down arrow
    if IsControlJustPressed(0, 199) then mark('pass') end                                      -- P
    if IsControlJustPressed(0, 49) then mark('fail') end                                       -- F
    if IsControlJustPressed(0, 249) then                                                       -- N
      local i = lib.inputDialog('Note for ' .. (Steps[sel] and Steps[sel].id or '?'), { { type = 'textarea', label = 'What happened / console line', required = true } })
      if i then local s = Steps[sel]; s.note = i[1]; push('update'); TriggerServerEvent('outbreak:shakedown:mark', s.id, s.label, s.status or 'note', i[1]) end
    end
    if IsControlJustPressed(0, 182) then TriggerServerEvent('outbreak:shakedown:export') end   -- L
    ::continue::
  end
end)
RegisterCommand('shakedown', toggle, false)
RegisterCommand('pass', function(_, a) if a[1] then for i, s in ipairs(Steps) do if s.id == a[1]:upper() then sel = i end end end; mark('pass', table.concat(a, ' ', 2)) end, false)
RegisterCommand('fail', function(_, a) if a[1] then for i, s in ipairs(Steps) do if s.id == a[1]:upper() then sel = i end end end; mark('fail', table.concat(a, ' ', 2)) end, false)
-- client errors: forward the ones we can see (resource script errors surface here on some builds)
AddEventHandler('onClientResourceStart', function(res) if res:find('^outbreak_') then TriggerServerEvent('outbreak:shakedown:event', 'client-start', res) end end)
