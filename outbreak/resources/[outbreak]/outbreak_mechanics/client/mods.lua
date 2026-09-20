-- outbreak_mechanics/client/mods.lua — repairs and mods, free, gated by standing. Natives are client-only; the
-- server checks standing and place first (outbreak:mech:request -> outbreak:mech:apply) and the result is
-- reported to outbreak_vehicles so a keyed car keeps its mods across restarts.
local function myVehicle()
  local ped = PlayerPedId(); local v = GetVehiclePedIsIn(ped, false)
  if v == 0 then local p = GetEntityCoords(ped); v = GetClosestVehicle(p.x, p.y, p.z, 6.0, 0, 71) end
  return v
end
local function readMods(veh)
  local M = MechCfg.Mods
  local p, s = GetVehicleColours(veh)
  return { engine = GetVehicleMod(veh, M.engine.idx), brakes = GetVehicleMod(veh, M.brakes.idx), transmission = GetVehicleMod(veh, M.transmission.idx), armour = GetVehicleMod(veh, M.armour.idx), turbo = IsToggleModOn(veh, M.turbo.idx), colours = { p, s } }
end
local function applyMods(veh, m)
  if not veh or veh == 0 or type(m) ~= 'table' then return end
  local M = MechCfg.Mods
  SetVehicleModKit(veh, 0)
  if m.engine then SetVehicleMod(veh, M.engine.idx, m.engine, false) end
  if m.brakes then SetVehicleMod(veh, M.brakes.idx, m.brakes, false) end
  if m.transmission then SetVehicleMod(veh, M.transmission.idx, m.transmission, false) end
  if m.armour then SetVehicleMod(veh, M.armour.idx, m.armour, false) end
  if m.turbo ~= nil then ToggleVehicleMod(veh, M.turbo.idx, m.turbo and true or false) end
  if m.colours then SetVehicleColours(veh, m.colours[1], m.colours[2]) end
end
exports('applyMods', applyMods)
local function report(veh) if NetworkGetEntityIsNetworked(veh) then TriggerServerEvent('outbreak:veh:mods', NetworkGetNetworkIdFromEntity(veh), readMods(veh)) end end

RegisterNetEvent('outbreak:mech:apply', function(netId, what, arg)
  local veh = NetworkGetEntityFromNetworkId(netId); if not veh or veh == 0 then return end
  local M = MechCfg.Mods
  if not exports.outbreak_emotes:action('repair', what == 'repair' and 6000 or 4000, what == 'repair' and 'The Yard works on it...' or 'Fitting...') then return end
  SetVehicleModKit(veh, 0)
  if what == 'repair' then SetVehicleFixed(veh); SetVehicleDeformationFixed(veh); SetVehicleEngineHealth(veh, 1000.0); SetVehicleBodyHealth(veh, 1000.0); SetVehicleDirtLevel(veh, 0.0)
  elseif what == 'respray' then local c = MechCfg.Colours[tonumber(arg) or 1]; if c then SetVehicleColours(veh, c[2], c[3]) end
  elseif what == 'engine' or what == 'brakes' or what == 'transmission' or what == 'armour' then
    local d = M[what]; local cur = GetVehicleMod(veh, d.idx); local nxt = cur + 1; if nxt > d.max then nxt = -1 end   -- cycles: stock -> 1 -> ... -> max -> stock
    SetVehicleMod(veh, d.idx, nxt, false)
  elseif what == 'turbo' then ToggleVehicleMod(veh, M.turbo.idx, not IsToggleModOn(veh, M.turbo.idx)) end
  PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
  report(veh)
  lib.notify({ title = 'Done.', description = what == 'repair' and 'Runs like it did.' or ('%s: %s'):format(what, what == 'turbo' and (IsToggleModOn(veh, M.turbo.idx) and 'on' or 'off') or what == 'respray' and 'new coat' or tostring(GetVehicleMod(veh, M[what].idx) + 1)), type = 'success' })
end)

AddEventHandler('outbreak:mech:openMods', function()
  local veh = myVehicle()
  if veh == 0 then lib.notify({ title = 'Bring the car into the bay.', description = 'Sit in it or park it beside the Foreman.', type = 'error' }) return end
  if #(GetEntityCoords(veh) - MechCfg.Yard.pos) > MechCfg.Yard.radius then lib.notify({ title = 'Closer.', description = 'Park it in the Yard.', type = 'error' }) return end
  local s = lib.callback.await('outbreak:mech:standing', false) or {}
  local netId = NetworkGetNetworkIdFromEntity(veh)
  local M = MechCfg.Mods
  local function lvl(k) local v = GetVehicleMod(veh, M[k].idx); return v < 0 and 'stock' or ('level ' .. (v + 1)) end
  local opts = {
    { title = ('The Yard · standing: %s (%s)'):format(tostring(s.word), tostring(s.value)), description = 'Free. Deliveries raise it: wary = repairs, neutral = paint, trusted = engine/brakes/box, kin = armour + turbo', readOnly = true, icon = 'wrench' },
    { title = 'Repair everything', icon = 'screwdriver-wrench', disabled = not s.repair, description = s.repair and 'body, engine, dirt' or 'needs: wary', onSelect = function() TriggerServerEvent('outbreak:mech:request', netId, 'repair') end },
  }
  local colours = {}
  for i, c in ipairs(MechCfg.Colours) do colours[#colours + 1] = { title = c[1], onSelect = function() TriggerServerEvent('outbreak:mech:request', netId, 'respray', i) end } end
  lib.registerContext({ id = 'ob_mech_paint', title = 'Respray', menu = 'ob_mech', options = colours })
  opts[#opts + 1] = { title = 'Respray', icon = 'paint-roller', disabled = not s.respray, description = s.respray and 'six coats' or 'needs: neutral', menu = 'ob_mech_paint' }
  for _, k in ipairs({ 'engine', 'brakes', 'transmission' }) do
    opts[#opts + 1] = { title = k:sub(1, 1):upper() .. k:sub(2) .. ' · ' .. lvl(k), icon = 'gauge-high', disabled = not s.performance, description = s.performance and 'click to step up (wraps to stock)' or 'needs: trusted', onSelect = function() TriggerServerEvent('outbreak:mech:request', netId, k) end }
  end
  opts[#opts + 1] = { title = 'Armour · ' .. lvl('armour'), icon = 'shield-halved', disabled = not s.armour, description = s.armour and 'plates and cage' or 'needs: kin', onSelect = function() TriggerServerEvent('outbreak:mech:request', netId, 'armour') end }
  opts[#opts + 1] = { title = 'Turbo · ' .. (IsToggleModOn(veh, M.turbo.idx) and 'on' or 'off'), icon = 'wind', disabled = not s.armour, description = s.armour and 'toggle' or 'needs: kin', onSelect = function() TriggerServerEvent('outbreak:mech:request', netId, 'turbo') end }
  lib.registerContext({ id = 'ob_mech', title = 'Repairs & mods', options = opts })
  lib.showContext('ob_mech')
end)
