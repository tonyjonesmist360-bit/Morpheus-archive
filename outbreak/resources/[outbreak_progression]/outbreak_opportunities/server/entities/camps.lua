-- outbreak_opportunities/server/entities/camps.lua — minimal survivor-camp world entity (future: its own resource)
local Camps = {}
CampCatalog = {
  grapeseed = { label = 'Silo Farm', pos = vec3(2211.7, 4988.3, 41.6), radius = 45.0, channel = 4,
    gate = vec3(2196.0, 4975.0, 41.2), entries = { south = vec3(2190.0, 4930.0, 41.0), west = vec3(2150.0, 4990.0, 41.5) },
    decoy = vec3(2160.0, 4730.0, 39.5), defaults = { population = 12, food = 40, water = 60, meds = 10, ammo = 20, power = 0, defenses = 10, morale = 50, threat = 30 } },
}
local function save(id)
  local c = Camps[id]
  MySQL.prepare([[INSERT INTO outbreak_camps (camp_id, population, food, water, meds, ammo, power, defenses, morale, threat, state, data) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
    ON DUPLICATE KEY UPDATE population=VALUES(population), food=VALUES(food), water=VALUES(water), meds=VALUES(meds), ammo=VALUES(ammo), power=VALUES(power), defenses=VALUES(defenses), morale=VALUES(morale), threat=VALUES(threat), state=VALUES(state), data=VALUES(data)]],
    { id, c.population, c.food, c.water, c.meds, c.ammo, c.power, c.defenses, c.morale, c.threat, c.state, json.encode(c.data or {}) })
  GlobalState['camp_' .. id] = c
end
CreateThread(function()
  for id, def in pairs(CampCatalog) do
    local row = MySQL.single.await('SELECT * FROM outbreak_camps WHERE camp_id = ?', { id })
    Camps[id] = row and { population = row.population, food = row.food, water = row.water, meds = row.meds, ammo = row.ammo, power = row.power, defenses = row.defenses, morale = row.morale, threat = row.threat, state = row.state, data = json.decode(row.data or '{}') }
      or (function() local c = {} for k, v in pairs(def.defaults) do c[k] = v end c.state = 'alive'; c.data = {} return c end)()
    save(id)
  end
end)
exports('getCamp', function(id) return Camps[id] end)
exports('modifyCamp', function(id, deltas, reason)
  local c = Camps[id]; if not c then return end
  for k, v in pairs(deltas) do
    if k == 'state' then c.state = v elseif type(c[k]) == 'number' then c[k] = math.max(0, math.min(100, c[k] + v)) end
  end
  save(id)
  if GlobalState.obDebug then print(('^5[OB-CAMP]^7 %s %s (%s)'):format(id, json.encode(deltas), reason or '-')) end
  return c
end)
exports('campAt', function(pos)
  for id, c in pairs(CampCatalog) do if #(pos - c.pos) <= c.radius then return { id = id, stash = 'camp_' .. id } end end
  return nil
end)
