-- outbreak_intel/server/intel.lua — per-character intel store (write-through)
local QBCore = exports['qb-core']:GetCoreObject()
local I = {}

local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end
local function rank(s) return IntelCfg.Rank[s] or 0 end
local function push(src, id) TriggerClientEvent('outbreak:intel:update', src, id, I[src][id]) end

local function save(src, id)
  local c = cid(src); local r = I[src] and I[src][id]; if not c or not r then return end
  MySQL.prepare([[INSERT INTO outbreak_intel (citizenid, intel_id, state, reliability, source, discovered_at, updated_at)
    VALUES (?, ?, ?, ?, ?, FROM_UNIXTIME(?), NOW())
    ON DUPLICATE KEY UPDATE state=VALUES(state), reliability=VALUES(reliability), source=VALUES(source), updated_at=NOW()]],
    { c, id, r.state, r.reliability, r.source, r.discoveredAt })
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
  local src = player.PlayerData.source
  I[src] = {}
  for _, r in ipairs(MySQL.query.await('SELECT intel_id, state, reliability, source, UNIX_TIMESTAMP(discovered_at) AS d FROM outbreak_intel WHERE citizenid = ?', { player.PlayerData.citizenid }) or {}) do
    I[src][r.intel_id] = { state = r.state, reliability = r.reliability, source = r.source, discoveredAt = r.d }
  end
  TriggerClientEvent('outbreak:intel:journal', src, I[src])
end)
AddEventHandler('playerDropped', function() I[source] = nil end)

local function transition(src, id, state, reliability, source)
  local def = IntelCatalog[id]; if not def or not I[src] then return false end
  local cur = I[src][id]
  if cur and cur.state == 'obsolete' then return false end
  if cur and rank(cur.state) >= rank(state) then return false end
  I[src][id] = { state = state, reliability = reliability or (cur and cur.reliability) or def.reliability, source = source, discoveredAt = cur and cur.discoveredAt or os.time() }
  save(src, id); push(src, id)
  if GlobalState.obDebug then print(('^5[OB-INTEL]^7 %s: %s -> %s via %s'):format(tostring(cid(src)), id, state, source)) end
  if state == 'confirmed' and def.opportunity then TriggerEvent('outbreak:intel:confirmed', src, id, def.opportunity) end
  return true
end

local function discover(src, id, reliability, source)
  local def = IntelCatalog[id]; if not def then return nil end
  local level = def.sources[source]; if not level then return nil end
  local ok = transition(src, id, level, reliability, source)
  return ok and level or nil
end

exports('discover', discover)
exports('confirm', function(src, id, source) local def = IntelCatalog[id]; if not def or def.sources[source] ~= 'confirmed' then return false end return transition(src, id, 'confirmed', 'confirmed', source) end)
exports('setState', function(src, id, state, source)
  if source ~= 'opportunity' then return false end
  if state ~= 'active' and state ~= 'completed' and state ~= 'failed' then return false end
  return transition(src, id, state, nil, source)
end)
exports('obsolete', function(id, reason)
  for src, store in pairs(I) do
    if store[id] then store[id].state = 'obsolete'; store[id].source = reason or 'obsolete'; save(src, id); push(src, id) end
  end
  MySQL.update('UPDATE outbreak_intel SET state = "obsolete", updated_at = NOW() WHERE intel_id = ?', { id })
end)
exports('getIntel', function(src) return I[src] or {} end)
exports('hasIntel', function(src, id, minState) local r = I[src] and I[src][id]; return r ~= nil and r.state ~= 'obsolete' and rank(r.state) >= rank(minState or 'rumor') end)
exports('whoKnows', function(id, minState)
  local out = {}
  for src, store in pairs(I) do local r = store[id]; if r and r.state ~= 'obsolete' and rank(r.state) >= rank(minState or 'confirmed') then out[#out + 1] = src end end
  return out
end)

RegisterNetEvent('outbreak:intel:arrived', function(id)
  local src = source
  local def = IntelCatalog[id]; if not def or not def.sources.arrival then return end
  local center = def.coords or (def.area and def.area.center); if not center then return end
  local radius = def.area and def.area.radius or 25.0
  if #(GetEntityCoords(GetPlayerPed(src)) - center) > radius then return end
  if def.category ~= 'discovery' and not (I[src] and I[src][id]) then return end -- can't confirm what you never heard
  discover(src, id, 'confirmed', 'arrival')
end)

RegisterNetEvent('outbreak:intel:openJournal', function()
  local src = source
  local opps = {}
  pcall(function() opps = exports.outbreak_opportunities:journalView(src) end)
  TriggerClientEvent('outbreak:intel:journal', src, I[src] or {}, opps)
end)
