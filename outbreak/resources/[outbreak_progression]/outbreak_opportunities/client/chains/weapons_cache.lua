-- client half of CHAIN 3: the site, the patrol, the dig
local ID = 'weapons_cache'
local site, patrolPeds, zone = nil, {}, nil

RegisterNetEvent('outbreak:opp:cache:site', function(pos, patrol)
  site = pos
  if zone then return end
  zone = exports.ox_target:addSphereZone({ coords = pos, radius = 2.5, options = {
    { label = 'Dig at the base of the pylon', icon = 'fa-solid fa-person-digging', canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and o.state == 'active' and o.stage == 2 end,
      onSelect = function()
        if exports.outbreak_emotes:action('search', 9000, 'Digging...') then TriggerEvent('outbreak:noise:spike', 45); TriggerServerEvent('outbreak:opp:report', ID, 'arrived', {}) end
      end },
    { label = 'Pry the footlocker', icon = 'fa-solid fa-box-open', canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and o.state == 'active' and o.stage == 3 and o.chosen == 'dig' end,
      onSelect = function()
        TriggerEvent('outbreak:noise:spike', 35)
        if exports.outbreak_minigames:play('pry', { pulls = 4, width = 14 }) then TriggerServerEvent('outbreak:opp:report', ID, 'opened', {})
        else TriggerEvent('outbreak:noise:spike', 75); lib.notify({ title = 'The lid screams. So does the patrol.', type = 'error' }) end
      end },
  } })
  -- patrol: two marines walking the road, hostile if provoked (military relationship group), investigate loud noise
  CreateThread(function()
    local m = joaat('s_m_y_marine_03'); RequestModel(m); while not HasModelLoaded(m) do Wait(10) end
    for i = 1, patrol.count do
      local p = CreatePed(4, m, pos.x + 30.0 + i * 3.0, pos.y + 20.0, pos.z, 200.0, false, true)
      SetEntityAsMissionEntity(p, true, true); SetPedRelationshipGroupHash(p, `OUTBREAK_MIL`)
      GiveWeaponToPed(p, `WEAPON_CARBINERIFLE`, 120, false, true); SetPedCombatAttributes(p, 46, true); SetPedHearingRange(p, patrol.radius)
      TaskWanderInArea(p, pos.x + 30.0, pos.y + 20.0, pos.z, 25.0, 4.0, 4.0)
      patrolPeds[#patrolPeds + 1] = p
    end
  end)
end)

-- noise at the site pulls the patrol (they hear you: the louder the meter, the closer they come)
AddEventHandler('outbreak:tick', function(t)
  if not site or #patrolPeds == 0 or #(t.pos - site) > 80.0 then return end
  local n = 0; pcall(function() n = exports.outbreak_noise:getNoise() end)
  if n > 55 then
    for _, p in ipairs(patrolPeds) do if DoesEntityExist(p) and not IsEntityDead(p) then TaskGoToCoordAnyMeans(p, t.pos.x, t.pos.y, t.pos.z, 2.0, 0, false, 786603, 0) end end
  end
end)

RegisterNetEvent('outbreak:opp:cache:end', function(outcome)
  for _, p in ipairs(patrolPeds) do if DoesEntityExist(p) then SetEntityAsNoLongerNeeded(p) end end
  patrolPeds = {}; site = nil
  lib.notify({ title = outcome == 'dug' and 'You have it. Now everyone wants it.' or 'The Remnant took it. You\'re owed.', type = 'inform', duration = 9000 })
end)
