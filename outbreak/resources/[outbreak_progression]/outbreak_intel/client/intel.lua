-- outbreak_intel/client/intel.lua — presentation + arrival sensor
local store = {}
local blips = {}
local opps = {}

local function clearBlip(id) if blips[id] then RemoveBlip(blips[id]); blips[id] = nil end end

local function present(id)
  local def = IntelCatalog[id]; local r = store[id]
  clearBlip(id)
  if not def or not r or r.state == 'obsolete' or r.state == 'completed' or r.state == 'failed' then return end
  if def.coords and (r.state == 'confirmed' or r.state == 'active') then
    local b = AddBlipForCoord(def.coords.x, def.coords.y, def.coords.z)
    SetBlipSprite(b, 66); SetBlipColour(b, r.state == 'active' and 5 or 0); SetBlipScale(b, 0.75)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(def.title); EndTextCommandSetBlipName(b)
    blips[id] = b
  elseif def.area and (r.state == 'rumor' or r.state == 'partial') then
    local b = AddBlipForRadius(def.area.center.x, def.area.center.y, def.area.center.z, def.area.radius)
    SetBlipColour(b, r.state == 'rumor' and 8 or 5); SetBlipAlpha(b, 70)
    blips[id] = b
  end
  -- landmark / frequency / photo / clue: journal only. No marker.
end

RegisterNetEvent('outbreak:intel:journal', function(all, oppView)
  store = all or {}; opps = oppView or opps
  for id in pairs(blips) do clearBlip(id) end
  for id in pairs(store) do present(id) end
  TriggerEvent('outbreak:intel:journalData', store, opps)
end)
RegisterNetEvent('outbreak:intel:update', function(id, rec)
  store[id] = rec; present(id)
  local def = IntelCatalog[id]
  if def then lib.notify({ title = 'Journal: ' .. def.title, description = rec.state:upper() .. (rec.reliability and (' · ' .. rec.reliability) or ''), type = 'inform', duration = 6000 }) end
end)
RegisterNetEvent('outbreak:intel:radioOffer', function(intelId, channel)
  local mine = 0
  pcall(function() mine = exports['pma-voice']:getRadioChannel() or 0 end)
  if mine == 0 then return end
  if channel ~= 0 and mine ~= channel then return end
  TriggerServerEvent('outbreak:intel:radioAck', intelId, mine)
end)

-- arrival sensor, on the core tick (every N ticks), only for records that can be confirmed by arrival
local n = 0
AddEventHandler('outbreak:tick', function(t)
  n = n + 1; if n % IntelCfg.ArrivalCheckTicks ~= 0 then return end
  for id, def in pairs(IntelCatalog) do
    if def.sources.arrival then
      local r = store[id]
      local eligible = (r and r.state ~= 'confirmed' and r.state ~= 'active' and r.state ~= 'completed' and r.state ~= 'obsolete') or (not r and def.category == 'discovery')
      if eligible then
        local center = def.coords or (def.area and def.area.center)
        local radius = def.area and def.area.radius or 25.0
        if center and #(t.pos - center) <= radius then TriggerServerEvent('outbreak:intel:arrived', id) end
      end
    end
  end
end)

exports('getIntel', function() return store end)
