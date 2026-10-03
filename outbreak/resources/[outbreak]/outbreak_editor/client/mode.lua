-- outbreak_editor/client/mode.lua — Sims-style editor: free camera, a ground-snapped cursor with grid snap and
-- rotation, undo/redo. One per-frame thread, alive only while editing (CORE-MECHANICS: conditional, restores).
Editor = { on = false, cam = nil, pos = nil, rot = nil, cursor = nil, snap = EditorCfg.Grid.default, heading = 0.0, tool = 'select',
           typing = false, pointer = { x = 0.5, y = 0.5 }, undo = {}, redo = {}, selected = nil, preview = nil, hit = nil }
local reqId, pending = 0, {}

-- ── server ops with a result callback (one event, one verb) ──
function Editor.op(op, d, cb) reqId = reqId + 1; pending[reqId] = cb; TriggerServerEvent('outbreak:editor:op', op, d, reqId) end
RegisterNetEvent('outbreak:editor:opResult', function(id, op, rec, err)
  local cb = pending[id]; pending[id] = nil
  if err then lib.notify({ title = 'Editor', description = ('%s: %s'):format(op, tostring(err)), type = 'error' }) end
  if cb then cb(rec, err) end
end)
-- ── undo / redo: each entry is { undo = fn, redo = fn, label } ──
function Editor.push(entry) Editor.undo[#Editor.undo + 1] = entry; Editor.redo = {}; if #Editor.undo > 60 then table.remove(Editor.undo, 1) end; Editor.hint() end
function Editor.doUndo() local e = table.remove(Editor.undo); if not e then return end; e.undo(); Editor.redo[#Editor.redo + 1] = e; lib.notify({ title = 'Undo', description = e.label, type = 'inform', duration = 2500 }); Editor.hint() end
function Editor.doRedo() local e = table.remove(Editor.redo); if not e then return end; e.redo(); Editor.undo[#Editor.undo + 1] = e; lib.notify({ title = 'Redo', description = e.label, type = 'inform', duration = 2500 }); Editor.hint() end

-- ── camera maths: screen point -> world ray ──
local function rotToDir(rot)
  local rz, rx = math.rad(rot.z), math.rad(rot.x)
  return vector3(-math.sin(rz) * math.abs(math.cos(rx)), math.cos(rz) * math.abs(math.cos(rx)), math.sin(rx))
end
local function screenRay(px, py)   -- px,py in 0..1
  local fov = GetCamFov(Editor.cam); local ar = GetAspectRatio(true)
  local rot = Editor.rot
  local fwd = rotToDir(rot)
  local right = rotToDir(vector3(0, 0, rot.z - 90.0)); right = vector3(right.x, right.y, 0.0)
  local up = vector3(0, 0, 1.0)
  -- orthonormal basis around fwd
  local r = vector3(fwd.y, -fwd.x, 0.0); local rl = #r; if rl > 0 then r = r / rl end
  local u = vector3(-fwd.z * r.y, fwd.z * r.x, fwd.x * r.y - fwd.y * r.x)
  local tanv = math.tan(math.rad(fov) / 2.0)
  local dx, dy = (px - 0.5) * 2.0 * tanv * ar, (0.5 - py) * 2.0 * tanv
  local dir = fwd + r * dx + u * dy
  return dir / #dir
end
function Editor.groundAt(px, py)
  local dir = screenRay(px, py)
  local from = Editor.pos; local to = from + dir * 400.0
  local ray = StartShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, 1 + 16 + 256, PlayerPedId(), 7)
  local _, hit, coords, _, ent = GetShapeTestResult(ray)
  if hit == 1 then return coords, ent end
  return nil
end
local function snapV(v)
  local s = Editor.snap
  if s <= 0 then return v end
  return vector3(math.floor(v.x / s + 0.5) * s, math.floor(v.y / s + 0.5) * s, v.z)
end

-- ── enter / leave ──
local function enter()
  local ped = PlayerPedId(); local p = GetEntityCoords(ped)
  Editor.pos = vector3(p.x, p.y, p.z + 12.0); Editor.rot = vector3(-45.0, 0.0, GetEntityHeading(ped))
  Editor.cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', Editor.pos.x, Editor.pos.y, Editor.pos.z, Editor.rot.x, Editor.rot.y, Editor.rot.z, 55.0, false, 2)
  SetCamActive(Editor.cam, true); RenderScriptCams(true, true, 600, true, true)
  FreezeEntityPosition(ped, true); SetEntityCollision(ped, false, false)
  Editor.on = true
  EditorUI.open()
  CreateThread(function()
    while Editor.on do
      Wait(0)
      local fast = IsControlPressed(0, 21); local slow = IsControlPressed(0, 36)
      local spd = fast and EditorCfg.Cam.fast or slow and EditorCfg.Cam.slow or EditorCfg.Cam.speed
      if not Editor.typing then
        local fwd = rotToDir(vector3(0.0, 0.0, Editor.rot.z)); local right = vector3(fwd.y, -fwd.x, 0.0)
        local mv = vector3(0, 0, 0)
        if IsControlPressed(0, 32) then mv = mv + fwd end
        if IsControlPressed(0, 33) then mv = mv - fwd end
        if IsControlPressed(0, 34) then mv = mv - right end
        if IsControlPressed(0, 35) then mv = mv + right end
        if IsControlPressed(0, 22) then mv = mv + vector3(0, 0, 1.0) end     -- Space up
        if IsControlPressed(0, 44) then mv = mv - vector3(0, 0, 1.0) end     -- Q down
        if #mv > 0 then Editor.pos = Editor.pos + (mv / #mv) * spd end
        -- right-drag look is fed by the NUI (mouse deltas); keyboard arrows also turn
        if IsControlPressed(0, 174) then Editor.rot = vector3(Editor.rot.x, 0.0, Editor.rot.z + 1.5) end
        if IsControlPressed(0, 175) then Editor.rot = vector3(Editor.rot.x, 0.0, Editor.rot.z - 1.5) end
      end
      SetCamCoord(Editor.cam, Editor.pos.x, Editor.pos.y, Editor.pos.z); SetCamRot(Editor.cam, Editor.rot.x, 0.0, Editor.rot.z, 2)
      -- keep the ped near the camera so the world streams around it (ghost: nobody sees it)
      local ped2 = PlayerPedId()
      local g, gz = GetGroundZFor_3dCoord(Editor.pos.x, Editor.pos.y, Editor.pos.z, false)
      SetEntityCoordsNoOffset(ped2, Editor.pos.x, Editor.pos.y, g and gz or Editor.pos.z - 5.0, false, false, false)
      -- cursor: ground under the pointer
      local c, ent = Editor.groundAt(Editor.pointer.x, Editor.pointer.y)
      if c then
        Editor.cursor = snapV(c); Editor.hit = (ent and ent ~= 0 and DoesEntityExist(ent)) and ent or nil
        local cc = Editor.cursor
        DrawMarker(28, cc.x, cc.y, cc.z + 0.03, 0, 0, 0, 0, 0, 0, 0.25, 0.25, 0.25, 216, 210, 192, 110, false, false, 2, false, nil, nil, false)
        local hx, hy = cc.x + math.sin(-math.rad(Editor.heading)) * 1.0, cc.y + math.cos(-math.rad(Editor.heading)) * 1.0
        DrawLine(cc.x, cc.y, cc.z + 0.05, hx, hy, cc.z + 0.05, 180, 85, 45, 220)
        if Editor.snap > 0 then
          for i = -2, 2 do
            DrawLine(cc.x + i * Editor.snap, cc.y - 2 * Editor.snap, cc.z + 0.02, cc.x + i * Editor.snap, cc.y + 2 * Editor.snap, cc.z + 0.02, 216, 210, 192, 40)
            DrawLine(cc.x - 2 * Editor.snap, cc.y + i * Editor.snap, cc.z + 0.02, cc.x + 2 * Editor.snap, cc.y + i * Editor.snap, cc.z + 0.02, 216, 210, 192, 40)
          end
        end
        if Editor.preview and DoesEntityExist(Editor.preview) then SetEntityCoordsNoOffset(Editor.preview, cc.x, cc.y, cc.z, false, false, false); SetEntityHeading(Editor.preview, Editor.heading) end
      end
      EditorWorld.drawZones()
      EditorWorld.drawLabels()
      DisableControlAction(0, 24, true); DisableControlAction(0, 25, true); DisableControlAction(0, 257, true); DisableControlAction(0, 140, true); DisableControlAction(0, 141, true); DisableControlAction(0, 142, true)
      DisableControlAction(0, 37, true); DisableControlAction(0, 199, true); DisableControlAction(0, 200, true)
    end
  end)
end
local function leave()
  Editor.on = false
  EditorUI.close()
  if Editor.preview and DoesEntityExist(Editor.preview) then DeleteEntity(Editor.preview) end; Editor.preview = nil
  RenderScriptCams(false, true, 600, true, true); if Editor.cam then DestroyCam(Editor.cam, false) end; Editor.cam = nil
  local ped = PlayerPedId()
  -- you step out where the cursor was (Sims: the camera is where you are)
  local land = Editor.cursor or Editor.pos
  local g, gz = GetGroundZFor_3dCoord(land.x, land.y, land.z + 5.0, false)
  SetEntityCoords(ped, land.x, land.y, (g and gz or land.z) + 0.5, false, false, false, false)
  FreezeEntityPosition(ped, false); SetEntityCollision(ped, true, true)
end
RegisterNetEvent('outbreak:editor:mode', function(on)
  if on and not Editor.on then enter(); lib.notify({ title = 'EDITOR', description = 'WASD fly · right-drag look · Space/Q up/down · Shift fast · G grid · R rotate · Z/Y undo/redo · Esc leave', type = 'inform', duration = 9000 })
  elseif not on and Editor.on then leave(); lib.notify({ title = 'Back in the world.', type = 'inform' }) end
end)
AddEventHandler('onResourceStop', function(r) if r == GetCurrentResourceName() and Editor.on then leave() end end)
AddEventHandler('outbreak:editor:toggle', function() TriggerServerEvent('outbreak:editor:toggle') end)
function Editor.hint() EditorUI.send('hint', { undo = #Editor.undo, redo = #Editor.redo, snap = Editor.snap, heading = math.floor(Editor.heading), tool = Editor.tool }) end
function Editor.cycleSnap() local steps = EditorCfg.Grid.steps; local i = 1; for k, v in ipairs(steps) do if v == Editor.snap then i = k end end; Editor.snap = steps[(i % #steps) + 1]; Editor.hint() end
function Editor.rotate(d) Editor.heading = (Editor.heading + d) % 360.0; Editor.hint() end
function Editor.setPreview(model)
  if Editor.preview and DoesEntityExist(Editor.preview) then DeleteEntity(Editor.preview) end; Editor.preview = nil
  if not model or model == '' then return end
  local h = joaat(model); if not IsModelInCdimage(h) or not IsModelValid(h) then lib.notify({ title = 'Unknown model', description = model, type = 'error' }) return end
  lib.requestModel(h, 5000)
  local c = Editor.cursor or Editor.pos
  local p = CreatePed(4, h, c.x, c.y, c.z, Editor.heading, false, false)
  SetEntityAlpha(p, 150, false); FreezeEntityPosition(p, true); SetEntityCollision(p, false, false); SetEntityInvincible(p, true); SetBlockingOfNonTemporaryEvents(p, true)
  Editor.preview = p
  SetModelAsNoLongerNeeded(h)
end
exports('isEditing', function() return Editor.on end)
exports('cursor', function() return Editor.cursor end)
