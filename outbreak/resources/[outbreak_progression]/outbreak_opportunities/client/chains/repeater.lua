-- client half of CHAIN 4: delivery target at the tower, boot defense (wave + damage sensor), tower light
local ID = 'repeater'
local tower = vec3(501.0, 5604.0, 797.9)
local booting, bootEnd = false, 0

CreateThread(function()
  exports.ox_target:addSphereZone({ coords = tower, radius = 4.0, options = {
    { label = 'Fit a part into the repeater', icon = 'fa-solid fa-tower-cell', canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and o.state == 'active' and o.stage == 2 end,
      onSelect = function()
        local input = lib.inputDialog('Repeater', { { type = 'select', label = 'Part', required = true, options = { { value = 'car_battery', label = 'Car battery' }, { value = 'radio_coil', label = 'Radio coil' } } } })
        if input and exports.outbreak_emotes:action('repair', 8000, 'Fitting...') then TriggerServerEvent('outbreak:opp:deliver', ID, input[1]) end
      end },
    { label = 'Sign on to restore the repeater', icon = 'fa-solid fa-tower-cell', canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and (o.state == 'available' or (o.state == 'active' and not o.joined)) end,
      onSelect = function() TriggerServerEvent('outbreak:opp:join', ID) end },
  } })
end)

RegisterNetEvent('outbreak:opp:repeater:boot', function(pos, size, endsAt)
  booting, bootEnd = true, endsAt
  lib.notify({ title = 'RELAY BOOTING', description = ('Hold the tower. %d coming. Three minutes.'):format(size), type = 'error', duration = 10000 })
  -- the horde itself is spawned through core's event for the chooser; others near the tower spawn a share too
  if #(GetEntityCoords(PlayerPedId()) - pos) < 150.0 then
    CreateThread(function() for i = 1, math.floor(size / 2) do Wait(900); exports.outbreak_core:spawnZombieAt(pos + vector3(math.random(-40, 40), math.random(-40, 40), -5.0)) end end)
  end
end)
RegisterNetEvent('outbreak:opp:repeater:end', function(outcome)
  booting = false
  lib.notify({ title = outcome == 'restored' and 'RELAY ONLINE' or 'BOOT FAILED — coil burnt', type = outcome == 'restored' and 'success' or 'error', duration = 10000 })
end)

-- damage sensor via the core tick: a zombie hugging the tower for accumulated seconds is reported in 5 s chunks (server caps)
local acc, lastSend = 0, 0
AddEventHandler('outbreak:tick', function(t)
  if not booting then return end
  if #(t.pos - tower) > 60.0 then return end
  local z, d = exports.outbreak_core:nearestZombie(6.0)
  local near = 0
  if z then near = 1 end
  -- use the registry: count zombies within 5 m of the tower itself, not of the player
  for _, ped in ipairs(exports.outbreak_core:getZombies()) do if not IsEntityDead(ped) and #(GetEntityCoords(ped) - tower) < 5.0 then acc = acc + 0.5 break end end
  if acc >= 5 and GetGameTimer() - lastSend > 4900 then TriggerServerEvent('outbreak:opp:report', ID, 'towerDamage', { seconds = 5 }); acc = acc - 5; lastSend = GetGameTimer() end
end)
