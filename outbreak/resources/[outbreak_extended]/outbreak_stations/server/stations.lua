-- outbreak_stations/server/stations.lua
local state = {}  -- id -> { kind = 'dry'|'trickle'|'deadpump', dryUntil = 0 }

local function roll(seedStr)
  local h = 0
  for i = 1, #seedStr do h = (h * 31 + seedStr:byte(i)) % 1000003 end
  local r = (h % 1000) / 1000.0
  local W = StationCfg.Weights
  if r < W.dry then return 'dry' elseif r < W.dry + W.trickle then return 'trickle' else return 'deadpump' end
end

CreateThread(function()
  for _, s in ipairs(StationCfg.Stations) do
    state[s.id] = { kind = roll(s.id), dryUntil = 0 }
  end
  GlobalState.obStations = state
end)

local function push() GlobalState.obStations = state end

RegisterNetEvent('outbreak:server:pump', function(id)
  local src = source
  local st = state[id]; if not st then return end
  if st.kind == 'dry' or (st.kind == 'trickle' and os.time() < st.dryUntil) then
    TriggerClientEvent('ox_lib:notify', src, { title = 'The pump coughs air.', type = 'error' }) return
  end
  if st.kind == 'deadpump' then
    TriggerClientEvent('ox_lib:notify', src, { title = 'No power to the pump.', type = 'error' }) return
  end
  if exports.ox_inventory:GetItemCount(src, 'gas_can_small') < 1 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Nothing to fill.', type = 'error' }) return
  end
  local pct = math.random(StationCfg.TrickleYield[1], StationCfg.TrickleYield[2])
  st.dryUntil = os.time() + StationCfg.TrickleRechargeHours * 3600
  push()
  local slot = exports.ox_inventory:Search(src, 'slots', 'gas_can_small')[1]
  exports.ox_inventory:SetMetadata(src, slot.slot, { fuel = pct, description = ('Contains ~%d%% of a tank'):format(pct) })
  TriggerClientEvent('ox_lib:notify', src, { title = ('The pump gives up ~%d%%, then sputters dry.'):format(pct), type = 'success' })
end)

RegisterNetEvent('outbreak:server:powerPump', function(id)
  local src = source
  local st = state[id]; if not st or st.kind ~= 'deadpump' then return end
  if exports.ox_inventory:RemoveItem(src, StationCfg.DeadPumpItem, 1) then
    st.kind = 'trickle'; st.dryUntil = 0; push()
    TriggerClientEvent('ox_lib:notify', src, { title = 'The pump hums to life.', type = 'success' })
  end
end)

RegisterNetEvent('outbreak:server:stationLoot', function(id)
  local src = source
  local key = 'station_' .. id
  GlobalState['loot_' .. key] = GlobalState['loot_' .. key] or 0
  if os.time() - GlobalState['loot_' .. key] < 3600 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Picked over.', type = 'error' }) return
  end
  GlobalState['loot_' .. key] = os.time()
  local found = false
  for _, e in ipairs(StationCfg.Loot) do
    if math.random() < e[4] then exports.ox_inventory:AddItem(src, e[1], math.random(e[2], e[3])); found = true end
  end
  if not found then TriggerClientEvent('ox_lib:notify', src, { title = 'Empty shelves. Someone beat you here.', type = 'inform' }) end
end)
