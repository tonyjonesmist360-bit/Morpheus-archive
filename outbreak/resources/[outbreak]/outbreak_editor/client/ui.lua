-- outbreak_editor/client/ui.lua — the NUI bridge. Palette left, inspector right. The NUI owns the mouse; the game keeps
-- the keyboard (SetNuiFocusKeepInput). Right-drag look and wheel height come in as deltas from the page.
EditorUI = {}
function EditorUI.send(action, data) SendNUIMessage({ action = action, data = data }) end
local function state() return lib.callback.await('outbreak:editor:state', false) end
function EditorUI.open()
  SetNuiFocus(true, true); SetNuiFocusKeepInput(true)
  local S = state() or {}
  EditorUI.send('open', { state = S, cfg = { models = EditorCfg.Models, behaviours = EditorCfg.Behaviours, stances = EditorCfg.Stances, scenarios = EditorCfg.Scenarios, zones = EditorCfg.ZoneKinds, actions = EditorCfg.Actions, conditions = EditorCfg.Conditions, anims = EditorCfg.Anims, grid = EditorCfg.Grid.steps }, lootTables = (function() local t = {} for k, v in pairs(LootCfg.Tables) do t[k] = v end return t end)() })
  Editor.hint()
end
function EditorUI.close() SetNuiFocus(false, false); SetNuiFocusKeepInput(false); EditorUI.send('close') end
function EditorUI.refresh() EditorUI.send('state', { state = state() or {} }) end

RegisterNUICallback('close', function(_, cb) cb('ok'); TriggerServerEvent('outbreak:editor:toggle', false) end)
RegisterNUICallback('typing', function(d, cb) cb('ok'); Editor.typing = d and d.on == true end)
RegisterNUICallback('pointer', function(d, cb) cb('ok'); if d then Editor.pointer = { x = tonumber(d.x) or 0.5, y = tonumber(d.y) or 0.5 } end end)
RegisterNUICallback('look', function(d, cb) cb('ok'); if not Editor.on or not d then return end
  local s = EditorCfg.Cam.sens * 0.05
  Editor.rot = vector3(math.max(-89.0, math.min(89.0, Editor.rot.x - (tonumber(d.dy) or 0) * s)), 0.0, Editor.rot.z - (tonumber(d.dx) or 0) * s) end)
RegisterNUICallback('wheel', function(d, cb) cb('ok'); if not Editor.on or not d then return end
  if d.ctrl then Editor.rotate((tonumber(d.d) or 0) > 0 and -15 or 15) else Editor.pos = Editor.pos + vector3(0, 0, (tonumber(d.d) or 0) > 0 and -2.0 or 2.0) end end)
RegisterNUICallback('key', function(d, cb) cb('ok'); if not Editor.on or not d then return end
  local k = d.key
  if k == 'g' then Editor.cycleSnap() elseif k == 'r' then Editor.rotate(d.shift and -15 or 15) elseif k == 'z' then Editor.doUndo() elseif k == 'y' then Editor.doRedo()
  elseif k == 'Escape' then TriggerServerEvent('outbreak:editor:toggle', false)
  elseif k == 'Delete' then EditorUI.deleteSelected() end end)
RegisterNUICallback('tool', function(d, cb) cb('ok'); Editor.tool = d and d.tool or 'select'; Editor.setPreview(d and d.preview or nil); Editor.hint() end)
RegisterNUICallback('preview', function(d, cb) cb('ok'); Editor.setPreview(d and d.model or nil) end)
RegisterNUICallback('cursor', function(_, cb) local c = Editor.cursor or Editor.pos; cb({ x = c.x, y = c.y, z = c.z, h = Editor.heading, entity = Editor.hit and { model = GetEntityModel(Editor.hit), x = c.x, y = c.y, z = c.z } or nil }) end)
RegisterNUICallback('teleport', function(d, cb) cb('ok'); if d and d.x then Editor.pos = vector3(tonumber(d.x), tonumber(d.y), (tonumber(d.z) or 0) + 12.0) end end)

-- a click in the world: the active tool decides
RegisterNUICallback('click', function(d, cb)
  cb('ok'); if not Editor.on then return end
  local c = Editor.cursor; if not c then return end
  local tool = Editor.tool
  if tool == 'select' or d.button == 2 then
    local obj, kind = EditorWorld.pick(c, 2.5)
    Editor.selected = obj and { kind = kind, id = obj.id } or nil
    EditorUI.send('selected', { kind = kind, obj = obj })
  elseif tool == 'npc' then
    EditorUI.send('place', { kind = 'npc', x = c.x, y = c.y, z = c.z, h = Editor.heading })
  elseif tool == 'hide' then
    local ent = Editor.hit
    if ent and IsEntityAPed(ent) and not IsPedAPlayer(ent) and not Entity(ent).state.obNpc then
      local m = GetEntityModel(ent); local p = GetEntityCoords(ent)
      Editor.op('hidden.add', { model = m, x = p.x, y = p.y, z = p.z, note = d.note or '' }, function(rec)
        if rec then SetEntityAsMissionEntity(ent, true, true); DeleteEntity(ent); EditorUI.refresh()
          Editor.push({ label = 'suppress map ped', undo = function() Editor.op('hidden.delete', { id = rec.id }, EditorUI.refresh) end, redo = function() Editor.op('hidden.add', rec, EditorUI.refresh) end }) end
      end)
    else lib.notify({ title = 'Editor', description = 'Point at a map ped (not a player, not a placed NPC).', type = 'error' }) end
  elseif tool == 'interact' then
    local ent = Editor.hit
    local target = { kind = 'point', x = c.x, y = c.y, z = c.z }
    if ent and DoesEntityExist(ent) then
      if Entity(ent).state.obNpc then target = { kind = 'npc', id = Entity(ent).state.obNpc }
      else local ep = GetEntityCoords(ent); target = { kind = 'entity', model = GetEntityModel(ent), x = ep.x, y = ep.y, z = ep.z } end
    end
    EditorUI.send('place', { kind = 'interaction', target = target })
  elseif tool == 'zone' then
    EditorUI.send('place', { kind = 'zone', x = c.x, y = c.y, z = c.z })
  elseif tool == 'shelf' or tool == 'container' then
    local ent = Editor.hit
    if ent and DoesEntityExist(ent) and not IsEntityAPed(ent) then local ep = GetEntityCoords(ent); EditorUI.send('place', { kind = tool, target = { kind = 'entity', model = GetEntityModel(ent), x = ep.x, y = ep.y, z = ep.z } })
    else lib.notify({ title = 'Editor', description = 'Point at a prop.', type = 'error' }) end
  elseif tool == 'step' then
    EditorUI.send('place', { kind = 'step', x = c.x, y = c.y, z = c.z })
  elseif tool == 'move' and Editor.selected then
    local sel = Editor.selected
    local S = state() or {}
    if sel.kind == 'npc' then local n = S.npcs[sel.id] or S.npcs[tostring(sel.id)]; if n then local old = { x = n.x, y = n.y, z = n.z, h = n.h }
      n.x, n.y, n.z, n.h = c.x, c.y, c.z, Editor.heading
      Editor.op('npc.save', n, EditorUI.refresh)
      Editor.push({ label = 'move ' .. (n.name ~= '' and n.name or n.model), undo = function() n.x, n.y, n.z, n.h = old.x, old.y, old.z, old.h; Editor.op('npc.save', n, EditorUI.refresh) end, redo = function() n.x, n.y, n.z, n.h = c.x, c.y, c.z, Editor.heading; Editor.op('npc.save', n, EditorUI.refresh) end }) end
    elseif sel.kind == 'zone' then local z = S.zones[sel.id] or S.zones[tostring(sel.id)]; if z then local old = { x = z.x, y = z.y, z = z.z }
      z.x, z.y, z.z = c.x, c.y, c.z; Editor.op('zone.save', z, EditorUI.refresh)
      Editor.push({ label = 'move zone', undo = function() z.x, z.y, z.z = old.x, old.y, old.z; Editor.op('zone.save', z, EditorUI.refresh) end, redo = function() z.x, z.y, z.z = c.x, c.y, c.z; Editor.op('zone.save', z, EditorUI.refresh) end }) end
    elseif sel.kind == 'interaction' then local i = S.interactions[sel.id] or S.interactions[tostring(sel.id)]; if i and i.target.x then local old = { x = i.target.x, y = i.target.y, z = i.target.z }
      i.target.x, i.target.y, i.target.z = c.x, c.y, c.z; Editor.op('interaction.save', i, EditorUI.refresh)
      Editor.push({ label = 'move interaction', undo = function() i.target.x, i.target.y, i.target.z = old.x, old.y, old.z; Editor.op('interaction.save', i, EditorUI.refresh) end, redo = function() i.target.x, i.target.y, i.target.z = c.x, c.y, c.z; Editor.op('interaction.save', i, EditorUI.refresh) end }) end
    end
  end
end)

-- generic save/delete from the inspector, with undo entries
local Verb = { npc = 'npc', zone = 'zone', interaction = 'interaction', mission = 'mission' }
RegisterNUICallback('save', function(d, cb)
  cb('ok'); if not d or not Verb[d.kind] then return end
  local isNew = d.obj and d.obj.id == nil
  local kind = d.kind
  local payload = kind == 'mission' and { def = d.obj.def or d.obj, enabled = d.obj.enabled } or d.obj
  Editor.op(Verb[kind] .. '.save', payload, function(rec)
    if not rec then return end
    EditorUI.refresh()
    local id = rec.id
    if isNew then
      Editor.push({ label = 'place ' .. kind, undo = function() Editor.op(Verb[kind] .. '.delete', { id = id }, EditorUI.refresh) end, redo = function() local again = kind == 'mission' and { def = rec.def, enabled = rec.enabled } or rec; Editor.op(Verb[kind] .. '.save', again, function(r2) if r2 then id = r2.id end; EditorUI.refresh() end) end })
    end
    Editor.selected = { kind = kind, id = id }
    EditorUI.send('saved', { kind = kind, obj = rec })
  end)
end)
function EditorUI.deleteSelected()
  local sel = Editor.selected; if not sel then return end
  local S = state() or {}
  local coll = ({ npc = 'npcs', zone = 'zones', interaction = 'interactions', mission = 'missions' })[sel.kind]
  local rec = coll and (S[coll][sel.id] or S[coll][tostring(sel.id)])
  if not rec then return end
  Editor.op(Verb[sel.kind] .. '.delete', { id = sel.id }, function(old)
    if not old then return end
    Editor.selected = nil; EditorUI.refresh(); EditorUI.send('selected', {})
    Editor.push({ label = 'delete ' .. sel.kind, undo = function() local again = sel.kind == 'mission' and { def = old.def, enabled = old.enabled } or old; again.id = sel.kind == 'mission' and old.id or nil; Editor.op(Verb[sel.kind] .. '.save', again, EditorUI.refresh) end, redo = function() end })
  end)
end
RegisterNUICallback('delete', function(d, cb) cb('ok'); if d and d.kind and d.id then Editor.selected = { kind = d.kind, id = tonumber(d.id) or d.id } end; EditorUI.deleteSelected() end)
RegisterNUICallback('hiddenDelete', function(d, cb) cb('ok'); Editor.op('hidden.delete', { id = d.id }, EditorUI.refresh) end)
RegisterNUICallback('kv', function(d, cb) cb('ok'); if d and d.k then Editor.op('kv.set', { k = d.k, v = d.v or {} }, EditorUI.refresh) end end)
RegisterNUICallback('item', function(d, cb) cb('ok'); Editor.op('item.create', d or {}, function(rec) if rec then lib.notify({ title = 'Item drafted: ' .. rec.name, description = 'Lands after: setup/04-paste-ins.ps1 -Only items, then a restart.', type = 'success', duration = 9000 }); EditorUI.refresh() end end) end)
RegisterNUICallback('pack', function(d, cb)
  local r = lib.callback.await('outbreak:editor:pack', false, d and d.op or 'export', d and d.name or nil)
  cb(r or {})
  if r and r.file then lib.notify({ title = 'Pack written', description = r.file .. ' (' .. r.n .. ' objects)', type = 'success', duration = 8000 }) end
  if r and r.n and d.op == 'import' then lib.notify({ title = 'Pack imported', description = r.n .. ' objects', type = 'success' }); EditorUI.refresh() end
  if r and r.err then lib.notify({ title = 'Pack', description = r.err, type = 'error' }) end
end)
RegisterNUICallback('select', function(d, cb) cb('ok'); if d and d.kind then Editor.selected = { kind = d.kind, id = tonumber(d.id) or d.id }; if d.x then Editor.pos = vector3(tonumber(d.x), tonumber(d.y), (tonumber(d.z) or 0) + 12.0) end end end)
RegisterNUICallback('mission', function(d, cb) cb('ok'); if d and d.op == 'start' then TriggerServerEvent('outbreak:editor:missionStart', d.id) end end)
