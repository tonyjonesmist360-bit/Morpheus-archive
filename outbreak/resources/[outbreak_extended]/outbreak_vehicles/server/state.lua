-- outbreak_vehicles/server/state.lua — THE vehicle state store. Entity statebags are the read model; this table is the truth.
local V = {}      -- plate -> { model, fuel, battery, hotwired, locked, part, claimed, owner, noise, burn, netId, seed }
local ByNet = {}  -- netId -> plate

local function seeded(plate, model, salt)
  local h = 0; local s = plate .. model .. salt
  for i = 1, #s do h = (h * 31 + s:byte(i)) % 2147483647 end
  return (h % 10000) / 10000.0
end

local function classProfile(class) return VehCfg.Classes[class] or VehCfg.Classes[1] end

-- era: which roll table first-seen cars use (see VehCfg.Eras)
local era = GetConvar('ob_veh_era', 'early')
if not VehCfg.Eras[era] then era = 'early' end
GlobalState.obVehEra = era
local function E(k) local t = VehCfg.Eras[era]; local v = t and t[k]; if v == nil then v = VehCfg[k] end; return v end
exports('era', function() return era end)
local function setEra(name, reason)
  if not VehCfg.Eras[name] then return false end
  era = name; GlobalState.obVehEra = era
  print(('^5[OB-VEH]^7 era -> %s (%s). Cars seen from now on roll the %s table; restart to re-roll everything.'):format(era, reason or '-', era))
  return true
end
exports('setEra', setEra)
RegisterCommand('ob_vehera', function(src, args)
  if src ~= 0 and not IsPlayerAceAllowed(src, 'outbreak.dm') then return end
  local name = args[1]
  if not name or not VehCfg.Eras[name] then print(('^5[OB-VEH]^7 era is %s. Usage: ob_vehera early|live'):format(era)) return end
  setEra(name, src == 0 and 'console' or GetPlayerName(src))
end, true)
-- qbx_vehiclekeys locks every car you hold none of ITS keys for and blocks the driver door. We own
-- locks and keys here; both running means nobody can get into anything. Say so at boot.
CreateThread(function()
  Wait(2000)
  if GetResourceState('qbx_vehiclekeys') == 'started' then
    print('^1[OB-VEH] qbx_vehiclekeys is running.^7 It locks every vehicle you have no qbx key for, on top of outbreak_vehicles. Recommended: comment its ensure line out of server.cfg. Until then every key we hand out is mirrored to it.')
  end
end)

local function publish(plate)
  local v = V[plate]; if not v or not v.netId then return end
  local ent = NetworkGetEntityFromNetworkId(v.netId)
  if not ent or ent == 0 or not DoesEntityExist(ent) then return end
  Entity(ent).state:set('veh', { plate = plate, fuel = math.floor(v.fuel), battery = v.battery, hotwired = v.hotwired, locked = v.locked, part = v.part, claimed = v.claimed, noise = v.noise, boat = v.boat }, true)
end

local function save(plate)
  local v = V[plate]
  if VehCfg.Persistence.claimedOnly and not v.claimed then return end
  local ent = v.netId and NetworkGetEntityFromNetworkId(v.netId)
  local pos = ent and ent ~= 0 and DoesEntityExist(ent) and GetEntityCoords(ent) or v.pos or vector3(0, 0, 0)
  local heading = ent and ent ~= 0 and DoesEntityExist(ent) and GetEntityHeading(ent) or v.heading or 0.0
  v.pos, v.heading = pos, heading
  v.data = v.data or {}; v.data.boat = v.boat or false
  MySQL.prepare([[INSERT INTO outbreak_vehicles (plate, model, fuel, battery, hotwired, locked, part, claimed, owner, x, y, z, heading, data)
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE fuel=VALUES(fuel), battery=VALUES(battery), hotwired=VALUES(hotwired), locked=VALUES(locked), part=VALUES(part),
    claimed=VALUES(claimed), owner=VALUES(owner), x=VALUES(x), y=VALUES(y), z=VALUES(z), heading=VALUES(heading), data=VALUES(data)]],
    { plate, v.model, v.fuel, v.battery, v.hotwired and 1 or 0, v.locked and 1 or 0, v.part, v.claimed and 1 or 0, v.owner, pos.x, pos.y, pos.z, heading, json.encode(v.data or {}) })
end

-- register: called when a client first sees a networked vehicle nearby. Server rolls once per plate.
RegisterNetEvent('outbreak:veh:register', function(netId)
  local ent = NetworkGetEntityFromNetworkId(netId)
  if not ent or ent == 0 or not DoesEntityExist(ent) or GetEntityType(ent) ~= 2 then return end
  local plate = GetVehicleNumberPlateText(ent); if not plate or plate == '' then return end
  plate = plate:gsub('%s+$', '')
  local model = GetEntityModel(ent)
  if not V[plate] then
    local prof = classProfile(0) -- server has no GetVehicleClass; client sends class on register (below) else default
    local keysIn = seeded(plate, model, 'ign') < (E('KeysInIgnitionChance') or 0)   -- keys still in it: unlocked, runs
    local fr = E('FuelRange')
    V[plate] = {
      model = model, netId = netId,
      locked = (not keysIn) and seeded(plate, model, 'lock') < E('LockedChance'),
      battery = seeded(plate, model, 'bat') < E('DeadBatteryChance') and 'dead' or 'ok',
      fuel = fr[1] + seeded(plate, model, 'fuel') * (fr[2] - fr[1]),
      hotwired = keysIn, part = seeded(plate, model, 'part') < E('MissingPartChance') and 'engine_parts' or nil,
      keyInside = seeded(plate, model, 'key') < E('KeyInGloveboxChance'),
      claimed = false, owner = nil, noise = prof.noise, burn = prof.burn, data = {},
    }
  else
    V[plate].netId = netId
  end
  ByNet[netId] = plate
  publish(plate)
end)
RegisterNetEvent('outbreak:veh:class', function(netId, class)
  local plate = ByNet[netId]; if not plate then return end
  local p = classProfile(class); V[plate].noise, V[plate].burn, V[plate].boat = p.noise, p.burn, p.boat or false; publish(plate)
end)

-- SERVER-SIDE FUEL BURN. The server sees velocity and the driver; the client sees nothing it can lie about.
CreateThread(function()
  while true do
    Wait(5000)
    for plate, v in pairs(V) do
      local ent = v.netId and NetworkGetEntityFromNetworkId(v.netId)
      if ent and ent ~= 0 and DoesEntityExist(ent) then
        local driver = GetPedInVehicleSeat(ent, -1)
        if driver and driver ~= 0 and v.hotwired and v.battery == 'ok' and not v.part and v.fuel > 0 then
          local vel = GetEntityVelocity(ent)
          local kmh = math.sqrt(vel.x * vel.x + vel.y * vel.y + vel.z * vel.z) * 3.6
          local factor = kmh < 2.0 and VehCfg.IdleFactor or math.max(0.4, kmh / 60.0)
          if v.boat and VehCfg.Storm.weathers[GlobalState.obWeather or ''] then factor = factor * VehCfg.Storm.burnMult end
          v.fuel = math.max(0, v.fuel - (VehCfg.BurnPerMinute / 12) * factor * v.burn)
          publish(plate)
          if v.claimed and math.random() < 0.2 then save(plate) end
        end
      else
        v.netId = nil
      end
    end
  end
end)

-- ── restore claimed vehicles on start (server-side creation, no client needed) ──
CreateThread(function()
  Wait(1000)
  for _, r in ipairs(MySQL.query.await('SELECT * FROM outbreak_vehicles WHERE claimed = 1') or {}) do
    V[r.plate] = { model = r.model, fuel = r.fuel, battery = r.battery, hotwired = r.hotwired == 1, locked = r.locked == 1, part = r.part, claimed = true, owner = r.owner,
                   pos = vector3(r.x, r.y, r.z), heading = r.heading, noise = 1.0, burn = 1.0, data = json.decode(r.data or '{}'), boat = (json.decode(r.data or '{}')).boat or false }
    if VehCfg.Persistence.respawnOnStart then
      local d = json.decode(r.data or '{}')
      local ent = CreateVehicleServerSetter(r.model, d.boat and 'boat' or 'automobile', r.x, r.y, r.z, r.heading)
      if ent and ent ~= 0 then
        SetVehicleNumberPlateText(ent, r.plate)
        V[r.plate].netId = NetworkGetNetworkIdFromEntity(ent); ByNet[V[r.plate].netId] = r.plate
        publish(r.plate)
      end
    end
  end
end)

-- SCENE CLEAR: delete unoccupied, unclaimed vehicles inside a radius (DM spawns and strays).
-- Claimed vehicles (a key exists) are never touched.
exports('clearNear', function(pos, radius)
  local n = 0
  for _, ent in ipairs(GetAllVehicles()) do
    if DoesEntityExist(ent) and #(GetEntityCoords(ent) - pos) <= radius then
      local plate = (GetVehicleNumberPlateText(ent) or ''):gsub('%s+$', '')
      local v = V[plate]
      local occupied = false
      for seat = -1, 6 do local p = GetPedInVehicleSeat(ent, seat); if p and p ~= 0 and IsPedAPlayer(p) then occupied = true end end
      if not occupied and not (v and v.claimed) then
        if v then ByNet[v.netId or -1] = nil; V[plate] = nil end
        DeleteEntity(ent); n = n + 1
      end
    end
  end
  print(('^5[OB-VEH]^7 scene clear: %d vehicles removed within %.0f m of %.1f,%.1f'):format(n, radius, pos.x, pos.y))
  return n
end)
exports('get', function(plate) return V[plate] end)
exports('byNet', function(netId) return ByNet[netId] and V[ByNet[netId]] or nil, ByNet[netId] end)
exports('set', function(plate, changes, reason)
  local v = V[plate]; if not v then return false end
  for k, val in pairs(changes) do v[k] = val end
  publish(plate); save(plate)
  if GlobalState.obDebug then print(('^5[OB-VEH]^7 %s %s (%s)'):format(plate, json.encode(changes), reason or '-')) end
  return true
end)
exports('spawnManaged', function(model, pos, heading, plate, state, kind)  -- chains spawn special vehicles through here; kind = 'automobile' | 'boat'
  local ent = CreateVehicleServerSetter(joaat(model), kind or 'automobile', pos.x, pos.y, pos.z, heading)
  if not ent or ent == 0 then return nil end
  SetVehicleNumberPlateText(ent, plate)
  V[plate] = { model = joaat(model), netId = NetworkGetNetworkIdFromEntity(ent), locked = true, battery = 'dead', fuel = 0, hotwired = false, part = nil, claimed = false, noise = 1.0, burn = 1.0, data = {} }
  for k, val in pairs(state or {}) do V[plate][k] = val end
  ByNet[V[plate].netId] = plate
  publish(plate)
  return ent, V[plate].netId
end)
CreateThread(function() while true do Wait(120000) for plate, v in pairs(V) do if v.claimed then save(plate) end end end end)

-- marina wrecks: managed boats, unclaimed, deterministic like everything else (ambient boats are disabled by outbreak_map)
CreateThread(function()
  Wait(3000)
  for _, m in ipairs(VehCfg.Marinas) do
    if not V[m.plate] then
      exports.outbreak_vehicles:spawnManaged(m.model, m.pos, m.heading, m.plate, {
        locked = seeded(m.plate, joaat(m.model), 'lock') < 0.5, battery = seeded(m.plate, joaat(m.model), 'bat') < 0.6 and 'dead' or 'ok',
        fuel = 2 + seeded(m.plate, joaat(m.model), 'fuel') * 15, part = seeded(m.plate, joaat(m.model), 'part') < 0.5 and VehCfg.MarinePartItem or nil, boat = true, noise = 1.3, burn = 1.8 }, 'boat')
    end
  end
end)
