-- client half of CHAIN 1: delivery target at the gate, decoy point, wave spawning, kill reports, camp dressing
local ID = 'camp_defense_grapeseed'
local guards, floodlights, decoyBlip, decoyZone = {}, {}, nil, nil
local campDef = { gate = vec3(2196.0, 4975.0, 41.2), pos = vec3(2211.7, 4988.3, 41.6), decoy = vec3(2160.0, 4730.0, 39.5) }

-- gate: deliver (stage 2) — items validated server-side
CreateThread(function()
  exports.ox_target:addSphereZone({ coords = campDef.gate, radius = 3.0, options = {
    { label = 'Deliver supplies to Silo Farm', icon = 'fa-solid fa-box', canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and o.state == 'active' and o.stage == 2 end,
      onSelect = function()
        local input = lib.inputDialog('What are you handing over?', { { type = 'select', label = 'Item', required = true, options = {
          { value = 'plank', label = 'Plank (defenses)' }, { value = 'nails', label = 'Nails (defenses)' }, { value = 'gas_can_small', label = 'Fuel can (generator)' }, { value = 'bandage', label = 'Bandage (infirmary)' } } } })
        if input and exports.outbreak_emotes:action('barricade', 4000, 'Handing it over...') then TriggerServerEvent('outbreak:opp:deliver', ID, input[1]) end
      end },
    { label = 'Sign on to defend Silo Farm', icon = 'fa-solid fa-shield', canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and (o.state == 'available' or (o.state == 'active' and not o.joined)) end,
      onSelect = function() TriggerServerEvent('outbreak:opp:join', ID) end },
  } })
end)

-- camp dressing reacts to stats (power -> floodlights even in blackout; defenses -> barricades)
RegisterNetEvent('outbreak:opp:campdef:camp', function(c)
  for _, l in ipairs(floodlights) do if DoesEntityExist(l) then DeleteEntity(l) end end
  floodlights = {}
  if c.power > 0 then
    local m = `prop_worklight_03b`; RequestModel(m); local t = GetGameTimer(); while not HasModelLoaded(m) and GetGameTimer() - t < 2000 do Wait(10) end
    if HasModelLoaded(m) then
      for i = 1, 3 do local o = CreateObject(m, campDef.pos.x + i * 6.0 - 12.0, campDef.pos.y - 14.0, campDef.pos.z, false, false, false); PlaceObjectOnGroundProperly(o); FreezeEntityPosition(o, true); floodlights[#floodlights + 1] = o end
    end
  end
end)

-- decoy (lure solution): radius blip + report loop at 1 Hz while inside with noise
RegisterNetEvent('outbreak:opp:campdef:decoy', function(pos)
  if decoyBlip then RemoveBlip(decoyBlip) end
  decoyBlip = AddBlipForRadius(pos.x, pos.y, pos.z, 15.0); SetBlipColour(decoyBlip, 5); SetBlipAlpha(decoyBlip, 90)
  lib.notify({ title = 'Decoy point marked.', description = 'Get there and make noise for 30 seconds. Horn, whistle, gunfire. Then run.', type = 'warning', duration = 10000 })
  CreateThread(function()
    while decoyBlip do
      Wait(1000)
      local o = exports.outbreak_opportunities:getOpportunities()[ID]
      if not o or o.state ~= 'active' then RemoveBlip(decoyBlip); decoyBlip = nil; break end
      if #(GetEntityCoords(PlayerPedId()) - pos) < 15.0 then
        local n = 0; pcall(function() n = exports.outbreak_noise:getNoise() end)
        TriggerServerEvent('outbreak:opp:report', ID, 'decoy', { noise = n })
      end
    end
  end)
end)

-- waves: the nearest player to the camp spawns them (others see them via OneSync); kills reported by whoever sees them die
local tracking = {}
RegisterNetEvent('outbreak:opp:campdef:wave', function(wave, size, from, c)
  local me = GetEntityCoords(PlayerPedId())
  if #(me - campDef.pos) > 250.0 then return end
  -- am I the nearest? (cheap election: lowest server id within range spawns)
  local myId = GetPlayerServerId(PlayerId()); local lowest = myId
  for _, pid in ipairs(GetActivePlayers()) do local sid = GetPlayerServerId(pid); if sid < lowest and #(GetEntityCoords(GetPlayerPed(pid)) - campDef.pos) <= 250.0 then lowest = sid end end
  lib.notify({ title = ('WAVE %d'):format(wave), description = ('%d coming from the %s.'):format(size, wave == 2 and 'west' or 'south'), type = 'error', duration = 8000 })
  -- guards: spawn proportional to defenses (owner only)
  if lowest == myId then
    for _, g in ipairs(guards) do if DoesEntityExist(g) then DeleteEntity(g) end end
    guards = {}
    local nGuards = math.min(6, math.floor((c.defenses or 0) / 15))
    local gm = `a_m_m_farmer_01`; RequestModel(gm); while not HasModelLoaded(gm) do Wait(10) end
    for i = 1, nGuards do
      local g = CreatePed(4, gm, campDef.gate.x + i * 2.0 - nGuards, campDef.gate.y + 3.0, campDef.gate.z, 180.0, false, true)
      SetPedRelationshipGroupHash(g, `OUTBREAK_MIL`); GiveWeaponToPed(g, (c.power or 0) > 0 and `WEAPON_PUMPSHOTGUN` or `WEAPON_PISTOL`, 80, false, true)
      SetPedCombatAttributes(g, 46, true); SetPedAccuracy(g, 40); SetEntityAsMissionEntity(g, true, true); TaskGuardCurrentPosition(g, 8.0, 8.0, true)
      guards[#guards + 1] = g
    end
    CreateThread(function()
      for i = 1, size do
        Wait(700)
        local p = from + vector3(math.random(-10, 10), math.random(-10, 10), 0)
        local z = exports.outbreak_core:spawnZombieAt(p)
        if z then tracking[z] = true end
      end
    end)
  end
end)

-- kill reporting via the core tick (no loop of our own): count tracked zombies that died since last tick
local pending = 0
AddEventHandler('outbreak:tick', function()
  for z in pairs(tracking) do
    if not DoesEntityExist(z) then tracking[z] = nil
    elseif IsEntityDead(z) then tracking[z] = nil; pending = pending + 1 end
  end
  if pending > 0 then TriggerServerEvent('outbreak:opp:report', ID, 'kills', { n = pending }); pending = 0 end
end)

RegisterNetEvent('outbreak:opp:campdef:end', function(outcome)
  for _, g in ipairs(guards) do if DoesEntityExist(g) then SetEntityAsNoLongerNeeded(g) end end
  guards = {}; tracking = {}
  if decoyBlip then RemoveBlip(decoyBlip); decoyBlip = nil end
  lib.notify({ title = 'Silo Farm: ' .. outcome:upper(), type = outcome == 'clean' or outcome == 'lured' and 'success' or 'error', duration = 10000 })
end)
