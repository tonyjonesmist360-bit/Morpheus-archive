-- outbreak_worlditems/client/place.lua — ghost preview placement + targets on placed objects
local placing = false
local wiOf = function(ent) return Entity(ent).state.worldItem end

local function placeFromSlot(slot, item)
  if placing or LocalPlayer.state.downState then return end
  placing = true
  local model = joaat(WorldItemsCfg.Models[item] or WorldItemsCfg.Fallback)
  RequestModel(model); local t = GetGameTimer(); while not HasModelLoaded(model) and GetGameTimer() - t < 3000 do Wait(10) end
  if not HasModelLoaded(model) then placing = false return end
  local ghost = CreateObject(model, 0.0, 0.0, 0.0, false, false, false)
  SetEntityAlpha(ghost, 160, false); SetEntityCollision(ghost, false, false); FreezeEntityPosition(ghost, true)
  local heading = 0.0
  lib.showTextUI('[E] place · [Q]/[R] rotate · [X] cancel', { icon = 'hand' })
  local pos
  while placing do
    Wait(0)
    local ped = PlayerPedId()
    local cam = GetGameplayCamCoord(); local rot = GetGameplayCamRot(2)
    local dir = vector3(-math.sin(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.cos(math.rad(rot.z)) * math.cos(math.rad(rot.x)), math.sin(math.rad(rot.x)))
    local target = cam + dir * (WorldItemsCfg.MaxDistance + 1.5)
    local ray = StartShapeTestRay(cam.x, cam.y, cam.z, target.x, target.y, target.z, 1 + 16, ped, 0)
    local _, hit, hitPos = GetShapeTestResult(ray)
    pos = hit == 1 and hitPos or (GetEntityCoords(ped) + GetEntityForwardVector(ped) * 1.5)
    if #(pos - GetEntityCoords(ped)) > WorldItemsCfg.MaxDistance then pos = GetEntityCoords(ped) + (pos - GetEntityCoords(ped)) / #(pos - GetEntityCoords(ped)) * WorldItemsCfg.MaxDistance end
    SetEntityCoords(ghost, pos.x, pos.y, pos.z); SetEntityHeading(ghost, heading); PlaceObjectOnGroundProperly(ghost)
    if IsControlPressed(0, 44) then heading = (heading + WorldItemsCfg.RotateStep * 0.2) % 360 end   -- Q
    if IsControlPressed(0, 45) then heading = (heading - WorldItemsCfg.RotateStep * 0.2) % 360 end   -- R
    DisableControlAction(0, 24, true); DisableControlAction(0, 25, true)
    if IsControlJustPressed(0, 38) then
      local final = GetEntityCoords(ghost); local frot = GetEntityRotation(ghost, 2)
      if exports.outbreak_emotes:action('search', 1500, 'Placing...') then TriggerServerEvent('outbreak:wi:place', slot, vector3(final.x, final.y, final.z), vector3(frot.x, frot.y, frot.z)) end
      placing = false
    elseif IsControlJustPressed(0, 73) then placing = false end -- X
  end
  lib.hideTextUI(); DeleteEntity(ghost)
end

-- entry: wheel → "Place an item" → pick from pockets
RegisterCommand('placeitem', function()
  local ok, items = pcall(function() return exports.ox_inventory:GetPlayerItems() end)
  if not ok or not items then return end
  local opts = {}
  for _, it in pairs(items) do
    if it and it.name and not it.name:find('^WEAPON_') then
      opts[#opts + 1] = { title = (it.label or it.name) .. ' ×' .. it.count, description = WorldItemsCfg.Storage[it.name] and 'Storage — becomes a container' or nil,
        onSelect = function() placeFromSlot(it.slot, it.name) end }
    end
  end
  if #opts == 0 then lib.notify({ title = 'Empty pockets.', type = 'inform' }) return end
  lib.registerContext({ id = 'ob_place', title = 'Set something down', options = opts }); lib.showContext('ob_place')
end, false)
-- writing a note: text lives in metadata; placing it makes it readable
RegisterCommand('writenote', function()
  local input = lib.inputDialog('Write a note', { { type = 'textarea', label = 'What does it say?', required = true, max = 220 } })
  if input then TriggerServerEvent('outbreak:wi:writeNote', input[1]) end
end, false)

-- targets on every placed object: read via statebag
CreateThread(function()
  local models = {}
  for _, m in pairs(WorldItemsCfg.Models) do models[#models + 1] = joaat(m) end
  models[#models + 1] = joaat(WorldItemsCfg.Fallback)
  exports.ox_target:addModel(models, {
    { label = 'Take', icon = 'fa-solid fa-hand', canInteract = function(e) local w = wiOf(e); return w and w.item ~= '__prop' and not (w.storage and w.locked) end,
      onSelect = function(d) if exports.outbreak_emotes:action('search', 1500, 'Picking up...') then TriggerServerEvent('outbreak:wi:take', wiOf(d.entity).id) end end },
    { label = 'Open', icon = 'fa-solid fa-box-open', canInteract = function(e) local w = wiOf(e); return w and w.storage and not w.locked end,
      onSelect = function(d) TriggerServerEvent('outbreak:wi:open', wiOf(d.entity).id) end },
    { label = 'Padlock / unlock', icon = 'fa-solid fa-lock', canInteract = function(e) local w = wiOf(e); return w and w.storage end,
      onSelect = function(d) TriggerServerEvent('outbreak:wi:lock', wiOf(d.entity).id) end },
    { label = 'Force the padlock', icon = 'fa-solid fa-user-secret', canInteract = function(e) local w = wiOf(e); return w and w.storage and w.locked end,
      onSelect = function(d)
        local w = wiOf(d.entity); local pins = (WorldItemsCfg.Storage[w.item] or {}).pins or 3
        TriggerEvent('outbreak:noise:spike', 30)
        local ok, token = exports.outbreak_minigames:play('pinsweep', { pins = pins, speed = 1.0 }, 'wi:force:' .. tostring(w.id))
        if ok then TriggerServerEvent('outbreak:wi:forced', w.id, token) else TriggerEvent('outbreak:noise:spike', 70) end
      end },
    { label = 'Read', icon = 'fa-solid fa-book-open', canInteract = function(e) local w = wiOf(e); return w and (w.note or w.intel) end,
      onSelect = function(d)
        local w = wiOf(d.entity)
        if exports.outbreak_emotes:action('read', 2500, 'Reading...') then
          if w.note then lib.notify({ title = 'A note, left by ' .. (w.by or 'someone'), description = w.note, type = 'inform', duration = 12000 }) end
          TriggerServerEvent('outbreak:wi:read', w.id)
        end
      end },
    { label = 'Look closer', icon = 'fa-solid fa-eye', canInteract = function(e) return wiOf(e) ~= nil end,
      onSelect = function(d) local w = wiOf(d.entity); lib.notify({ title = (w.item or '?'):gsub('_', ' ') .. (w.count and w.count > 1 and (' ×' .. w.count) or ''), description = 'Left here by ' .. (w.by or 'someone'), type = 'inform' }) end },
  })
end)
