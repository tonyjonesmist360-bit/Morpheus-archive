-- outbreak_mechanics/server/mechanics.lua — jobs are server-owned: the car, the judge, the standing.
local Jobs = {}   -- src -> { pickup, plate, netId, startedAt, driven, chased, moved }
local F = function() return exports.outbreak_faction end
local V = function() return exports.outbreak_vehicles end
local function notify(src, t, d, ty) TriggerClientEvent('ox_lib:notify', src, { title = t, description = d, type = ty or 'inform', duration = 8000 }) end
local function standing(src) local v = F():getRep(src, MechCfg.Faction); local w = 'neutral'; pcall(function() w = F():standingWord(v) end); return v, w end
local rank = { hostile = 0, wary = 1, neutral = 2, trusted = 3, kin = 4 }
local function allows(word, need) return (rank[word] or 0) >= (rank[need] or 0) end

-- take a job: spawn the car at a pickup, hand keys, tell the driver
RegisterNetEvent('outbreak:mech:take', function()
  local src = source
  if Jobs[src] then notify(src, 'Foreman', MechCfg.Lines.busy, 'error') return end
  local yard = MechCfg.Yard.pos
  if #(GetEntityCoords(GetPlayerPed(src)) - yard) > MechCfg.Yard.radius + 10.0 then return end
  local p = MechCfg.Pickups[math.random(#MechCfg.Pickups)]
  local plate = ('YD%04d'):format(math.random(0, 9999))
  local ent, netId = V():spawnManaged(p.model, vector3(p.pos.x, p.pos.y, p.pos.z), p.pos.w, plate, MechCfg.Job.startState)
  if not ent then notify(src, 'Foreman', 'No car came up. Try again in a minute.', 'error') return end
  pcall(function() V():giveKeys(src, netId, plate) end)
  Jobs[src] = { pickup = p, plate = plate, netId = netId, startedAt = os.time(), driven = false, chased = false, start = vector3(p.pos.x, p.pos.y, p.pos.z) }
  notify(src, 'Foreman', MechCfg.Lines.hire:format(p.label), 'inform')
  TriggerClientEvent('outbreak:mech:job', src, { label = p.label, pos = vector3(p.pos.x, p.pos.y, p.pos.z), plate = plate, netId = netId, yard = yard, minutes = MechCfg.Job.minutes })
  pcall(function() exports.outbreak_log:log('mech.job', src, { pickup = p.id, plate = plate }) end)
end)
local function finish(src, how, engine)
  local j = Jobs[src]; if not j then return end
  Jobs[src] = nil
  local R = MechCfg.Job.reward
  local delta = how == 'delivered' and (R.delivered + ((engine or 0) >= MechCfg.Job.intactEngine and R.intact or 0)) or how == 'failed' and R.failed or R.abandoned
  F():addRep(src, MechCfg.Faction, delta, 'delivery ' .. how)
  if how == 'delivered' then
    notify(src, 'Foreman', (engine or 0) >= MechCfg.Job.intactEngine and MechCfg.Lines.intact or MechCfg.Lines.delivered, 'success')
    TriggerClientEvent('outbreak:radio:learn', src, MechCfg.Channel, 'The Yard. They talk on nine.')
    -- the delivered car belongs to the Yard now
    pcall(function() local ent = NetworkGetEntityFromNetworkId(j.netId); if ent and ent ~= 0 then DeleteEntity(ent) end end)
    pcall(function() V():set(j.plate, { keyed = false, claimed = false }, 'delivered to the Yard') end)
  elseif how == 'failed' then notify(src, 'Foreman', MechCfg.Lines.failed, 'error')
  else notify(src, 'Foreman', 'Job dropped.', 'inform') end
  TriggerClientEvent('outbreak:mech:job', src, nil)
  pcall(function() exports.outbreak_log:log('mech.' .. how, src, { plate = j.plate, engine = engine }) end)
end
RegisterNetEvent('outbreak:mech:abandon', function() finish(source, 'abandoned') end)
-- the judge: every 5 s look at the job car
CreateThread(function()
  while true do
    Wait(5000)
    for src, j in pairs(Jobs) do
      local ent = NetworkGetEntityFromNetworkId(j.netId)
      if not ent or ent == 0 or not DoesEntityExist(ent) then finish(src, 'failed', 0)
      else
        local pos = GetEntityCoords(ent)
        local engine = GetVehicleEngineHealth(ent)
        local driver = GetPedInVehicleSeat(ent, -1)
        local driving = driver and driver ~= 0 and driver == GetPlayerPed(src)
        if driving then j.driven = true end
        if engine <= 0 then finish(src, 'failed', engine)
        elseif os.time() - j.startedAt > MechCfg.Job.minutes * 60 then finish(src, 'abandoned')
        else
          if not j.chased and j.driven and #(pos - j.start) > MechCfg.Chase.afterMetres then
            j.chased = true
            if math.random() < MechCfg.Chase.chance then TriggerClientEvent('outbreak:mech:chase', src, j.netId) end
          end
          local vel = GetEntityVelocity(ent); local speed = math.sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z) * 3.6
          if j.driven and #(pos - MechCfg.Yard.pos) <= MechCfg.Job.deliverRadius and speed < MechCfg.Job.stopSpeed and not driving then finish(src, 'delivered', engine) end
        end
      end
    end
  end
end)
AddEventHandler('playerDropped', function() local j = Jobs[source]; if j then pcall(function() local ent = NetworkGetEntityFromNetworkId(j.netId); if ent and ent ~= 0 then DeleteEntity(ent) end end); Jobs[source] = nil end end)

-- standing and what it buys, for the menu
lib.callback.register('outbreak:mech:standing', function(src)
  local v, w = standing(src)
  return { value = v, word = w, repair = allows(w, MechCfg.Unlocks.repair), respray = allows(w, MechCfg.Unlocks.respray), performance = allows(w, MechCfg.Unlocks.performance), armour = allows(w, MechCfg.Unlocks.armour), job = Jobs[src] ~= nil }
end)
-- a mod request: the server checks standing and place; the client applies natives (client-only) and reports the set back to vehicles
RegisterNetEvent('outbreak:mech:request', function(netId, what, arg)
  local src = source
  if #(GetEntityCoords(GetPlayerPed(src)) - MechCfg.Yard.pos) > MechCfg.Yard.radius + 6.0 then return end
  local _, w = standing(src)
  local need = (what == 'repair') and MechCfg.Unlocks.repair or (what == 'respray') and MechCfg.Unlocks.respray or (what == 'armour') and MechCfg.Unlocks.armour or MechCfg.Unlocks.performance
  if not allows(w, need) then notify(src, 'Foreman', MechCfg.Lines.noStanding, 'error') return end
  TriggerClientEvent('outbreak:mech:apply', src, netId, what, arg)
  pcall(function() exports.outbreak_log:log('mech.mod', src, { what = what, arg = arg, standing = w }) end)
end)
