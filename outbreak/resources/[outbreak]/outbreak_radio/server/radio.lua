-- outbreak_radio/server/radio.lua — RADIO MESSAGE SERVICE + item gate
local QBCore = exports['qb-core']:GetCoreObject()

-- exports.outbreak_radio:transmit(channel, title, text, targetSrc)
--   channel 0 = "anyone with a powered radio on any channel"; targetSrc nil = everyone
local function garble(text, q)
  if q >= 0.6 then return text end
  local out = {}
  for word in text:gmatch('%S+') do out[#out + 1] = (math.random() < q + 0.15) and word or '*static*' end
  return table.concat(out, ' ')
end
local function transmit(channel, title, text, target, origin, originRange)
  if origin then
    local targets = target and { target } or GetPlayers()
    for _, s in ipairs(targets) do
      s = tonumber(s)
      local q = exports.outbreak_radio:qualityTo(s, origin, originRange)
      if q >= RadioCfg.Floor then TriggerClientEvent('outbreak:client:radioMsg', s, channel, title, garble(text, q), q) end
    end
    return
  end
  TriggerClientEvent('outbreak:client:radioMsg', target or -1, channel, title, text, 1.0)
  if GlobalState.obDebug then print(('^5[OB-RADIO]^7 ch%s %s: %s'):format(tostring(channel), title, text)) end
end
exports('transmit', transmit)

QBCore.Functions.CreateUseableItem('radio_handheld', function(src)
  if exports.ox_inventory:GetItemCount(src, 'radio_battery') < 1 then
    TriggerClientEvent('ox_lib:notify', src, { title = 'Dead battery.', type = 'error' }) return end
  TriggerClientEvent('outbreak:client:openRadio', src)
end)

-- battery drain: 1 battery per 45 min of being tuned in (client reports channel>0 every 5 min)
local tuned = {}
RegisterNetEvent('outbreak:server:radioHeartbeat', function(on)
  local src = source
  if not on then tuned[src] = nil return end
  tuned[src] = (tuned[src] or 0) + 1
  if tuned[src] >= 9 then
    tuned[src] = 0
    if exports.ox_inventory:RemoveItem(src, 'radio_battery', 1) then
      TriggerClientEvent('ox_lib:notify', src, { title = 'Radio battery swapped. Running low on spares?', type = 'inform' })
    else
      TriggerClientEvent('outbreak:client:radioDead', src)
    end
  end
end)

QBCore.Functions.CreateUseableItem(RadioCfg.Base.item, function(src)
  local pos = GetEntityCoords(GetPlayerPed(src))
  local ok, near, houseId = pcall(function() return exports.outbreak_housing:isNearClaimedHouse(pos, 15.0) end)
  if not ok or not near then TriggerClientEvent('ox_lib:notify', src, { title = 'Set it up inside a safehouse you hold a key to.', type = 'error' }) return end
  if exports.ox_inventory:RemoveItem(src, RadioCfg.Base.item, 1) then
    exports.outbreak_radio:placeBase(src, pos)
    TriggerClientEvent('ox_lib:notify', src, { title = 'Radio room online.', description = 'From here you reach four times farther.', type = 'success' })
  end
end)
