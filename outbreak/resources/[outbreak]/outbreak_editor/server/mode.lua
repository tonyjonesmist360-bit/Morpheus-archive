-- outbreak_editor/server/mode.lua — editor mode is server-granted: obEditor + obGod + obGhost. The body is paused
-- (needs check obGod), noise is forced to zero (noise.lua checks obEditor), infection rolls skip, everyone ignores you.
local function allowed(src) return src ~= 0 and IsPlayerAceAllowed(src, EditorCfg.Ace) end
local function setMode(src, on)
  local st = Player(src).state
  if on then
    st:set('obEditorRestore', { god = st.obGod == true, ghost = st.obGhost == true }, false)
    st:set('obGod', true, true); st:set('obGhost', true, true); st:set('obEditor', true, true)
    TriggerClientEvent('outbreak:dm:god', src, true); TriggerClientEvent('outbreak:dm:ghost', src, true)
  else
    local r = st.obEditorRestore or {}
    st:set('obEditor', false, true)
    if not r.god then st:set('obGod', false, true); TriggerClientEvent('outbreak:dm:god', src, false) end
    if not r.ghost then st:set('obGhost', false, true); TriggerClientEvent('outbreak:dm:ghost', src, false) end
  end
  TriggerClientEvent('outbreak:editor:mode', src, on)
  pcall(function() exports.outbreak_log:log('editor.mode', src, { on = on }) end)
end
RegisterNetEvent('outbreak:editor:toggle', function(on)
  local src = source
  if not allowed(src) then TriggerClientEvent('ox_lib:notify', src, { title = 'Editor', description = 'You need the outbreak.dm ace.', type = 'error' }) return end
  if on == nil then on = not (Player(src).state.obEditor == true) end
  setMode(src, on and true or false)
end)
RegisterCommand('editor', function(src, a) if src == 0 then print('in-game only') return end; if not allowed(src) then return end; setMode(src, a[1] ~= 'off' and not (a[1] == nil and Player(src).state.obEditor == true)) end, false)
AddEventHandler('playerDropped', function() local src = source; if Player(src).state.obEditor then Player(src).state:set('obEditor', false, true) end end)
exports('isEditing', function(src) return Player(src).state.obEditor == true end)
