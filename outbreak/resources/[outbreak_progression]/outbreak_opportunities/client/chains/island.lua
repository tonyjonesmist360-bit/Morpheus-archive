-- client half of CHAIN 5: marina charts, departure, island loading, landing sensor, enclave, lighthouse, washups
local ID = 'island'
local marina = vec3(-3427.6, 967.3, 8.3); local chartsSpot = vec3(-3430.5, 980.2, 8.6)
local island = { beach = vec3(4900.0, -5180.0, 2.5), dock = vec3(5000.0, -5750.0, 3.0), enclave = vec3(4990.0, -5220.0, 3.5), lighthouse = vec3(4530.0, -4880.0, 5.0) }
local enabled, enclavePeds, landedReported = false, {}, false

local function enableIsland(on)
  if enabled == on then return end
  enabled = on
  SetIslandHopperEnabled('HeistIsland', on)   -- Cayo Perico streams in; the mainland stays
  if on then
    local b = AddBlipForCoord(island.lighthouse.x, island.lighthouse.y, island.lighthouse.z); SetBlipSprite(b, 780); SetBlipColour(b, 5); SetBlipScale(b, 0.9)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString('The light'); EndTextCommandSetBlipName(b)
  end
end
RegisterNetEvent('outbreak:opp:island:enable', function() enableIsland(true) end)
RegisterNetEvent('outbreak:opp:island:state', function(d) if d and d.landed then enableIsland(true) end end)

CreateThread(function()
  exports.ox_target:addSphereZone({ coords = chartsSpot, radius = 2.0, options = { {
    label = 'Search the harbourmaster\'s desk', icon = 'fa-solid fa-map',
    onSelect = function() if exports.outbreak_emotes:action('search', 6000, 'Searching the desk...') then TriggerServerEvent('outbreak:opp:island:charts') end end } } })
  exports.ox_target:addSphereZone({ coords = marina, radius = 6.0, options = { {
    label = 'Set out on the bearing', icon = 'fa-solid fa-ship',
    canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and o.state == 'active' and o.stage == 3 and IsPedInAnyBoat(PlayerPedId()) end,
    onSelect = function() TriggerServerEvent('outbreak:opp:report', ID, 'depart', {}) end } } })
  exports.ox_target:addSphereZone({ coords = island.enclave, radius = 10.0, options = { {
    label = 'Approach the enclave', icon = 'fa-solid fa-people-group',
    canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and o.state == 'active' and o.stage == 5 end,
    onSelect = function() lib.notify({ title = 'Six of them. Rifles low, not lowered.', description = '"You weren\'t invited. Say why we shouldn\'t send you back." — decide in your journal.', type = 'warning', duration = 12000 }) end } } })
  exports.ox_target:addSphereZone({ coords = island.lighthouse, radius = 6.0, options = { {
    label = 'Light the lighthouse (coil + battery)', icon = 'fa-solid fa-tower-observation',
    canInteract = function() local o = exports.outbreak_opportunities:getOpportunities()[ID]; return o and o.state == 'active' and o.stage == 6 end,
    onSelect = function() if exports.outbreak_emotes:action('repair', 12000, 'Wiring the lamp...') then TriggerServerEvent('outbreak:opp:report', ID, 'lighthouse', {}) end end } } })
end)

-- landing sensor (tick): once, when stage 4 and we're on island ground
AddEventHandler('outbreak:tick', function(t)
  if landedReported then return end
  local o = exports.outbreak_opportunities:getOpportunities()[ID]
  if not o or o.state ~= 'active' or o.stage ~= 4 then return end
  if #(t.pos - island.beach) < 150.0 or #(t.pos - island.dock) < 150.0 then
    if t.veh == 0 then landedReported = true; TriggerServerEvent('outbreak:opp:report', ID, 'landed', {}) end
  end
end)

-- the enclave: six survivors at the beach camp; friendly by default, hostile if you chose force
local function spawnEnclave(hostile)
  for _, p in ipairs(enclavePeds) do if DoesEntityExist(p) then DeleteEntity(p) end end
  enclavePeds = {}
  local models = { 'a_m_m_farmer_01', 'a_f_y_hiker_01', 'a_m_y_hiker_01', 'a_f_m_tourist_01' }
  for i = 1, 6 do
    local m = joaat(models[math.random(#models)]); RequestModel(m); while not HasModelLoaded(m) do Wait(10) end
    local ped = CreatePed(4, m, island.enclave.x + math.random(-6, 6), island.enclave.y + math.random(-6, 6), island.enclave.z, math.random(0, 359) + 0.0, false, true)
    SetEntityAsMissionEntity(ped, true, true); GiveWeaponToPed(ped, `WEAPON_PUMPSHOTGUN`, 40, false, true)
    SetPedRelationshipGroupHash(ped, `OUTBREAK_MIL`); SetPedCombatAttributes(ped, 46, true)
    if hostile then TaskCombatPed(ped, PlayerPedId(), 0, 16) else SetBlockingOfNonTemporaryEvents(ped, true); TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_GUARD_STAND', 0, true) end
    enclavePeds[#enclavePeds + 1] = ped
  end
end
AddEventHandler('outbreak:tick', function(t)
  if not enabled or #enclavePeds > 0 then return end
  if #(t.pos - island.enclave) < 200.0 then local o = exports.outbreak_opportunities:getOpportunities()[ID]; spawnEnclave(o and o.contrib and false) end
end)
RegisterNetEvent('outbreak:opp:island:hostile', function() spawnEnclave(true) end)
RegisterNetEvent('outbreak:opp:island:lighthouse', function(pos) lib.notify({ title = 'The lamp is dark.', description = 'A coil and a battery would light it — and give the island a voice.', type = 'inform', duration = 9000 }) end)
RegisterNetEvent('outbreak:opp:island:washup', function(pos, size)
  if not enabled or #(GetEntityCoords(PlayerPedId()) - pos) > 250.0 then return end
  for i = 1, size do Wait(600); exports.outbreak_core:spawnZombieAt(pos + vector3(math.random(-30, 30), math.random(-15, 15), 0)) end
  lib.notify({ title = 'Shapes in the surf. The sea gives them back.', type = 'warning' })
end)
