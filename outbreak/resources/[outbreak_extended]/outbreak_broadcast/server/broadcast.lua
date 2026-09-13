-- outbreak_broadcast/server/broadcast.lua
local function streetName(pos) return ('%.0f, %.0f'):format(pos.x, pos.y) end -- client resolves to a street

local function toChannel(ch, title, text)
  TriggerClientEvent('outbreak:client:radioMsg', -1, ch, title, text)
end

-- Emergency loop
CreateThread(function()
  local i = 0
  while true do
    Wait(BroadcastCfg.Emergency.everyMinutes * 60000)
    i = (i % #BroadcastCfg.Emergency.lines) + 1
    toChannel(BroadcastCfg.Emergency.channel, 'EMERGENCY BROADCAST', BroadcastCfg.Emergency.lines[i])
  end
end)

-- Numbers station: a cache, read out as digits. Sometimes it's bait.
local activeCache = nil
CreateThread(function()
  while true do
    local N = BroadcastCfg.Numbers
    Wait(math.random(N.everyMinutes[1], N.everyMinutes[2]) * 60000)
    if activeCache then goto continue end
    local site = N.sites[math.random(#N.sites)]
    local bait = math.random() < N.baitChance
    local id = ('cache_%d'):format(os.time())
    if not bait then
      exports.ox_inventory:RegisterStash(id, 'Supply Cache', N.lootSlots, 60000, nil)
      local picks = {}
      for _, l in ipairs(N.loot) do picks[#picks + 1] = l end
      for k = 1, 4 do local l = table.remove(picks, math.random(#picks)); exports.ox_inventory:AddItem(id, l[1], l[2]) end
    end
    activeCache = { id = id, pos = site, bait = bait }
    local digits = ('%d %d %d ... %d %d %d'):format(math.abs(site.x) // 100, (math.abs(site.x) // 10) % 10, math.abs(site.x) % 10, math.abs(site.y) // 100, (math.abs(site.y) // 10) % 10, math.abs(site.y) % 10)
    toChannel(N.channel, 'NUMBERS STATION', ('*tone* ... %s ... %s%s ... *tone*'):format(digits, site.x < 0 and 'west ' or 'east ', site.y < 0 and 'south' or 'north'))
    TriggerClientEvent('outbreak:client:cacheActive', -1, activeCache)
    SetTimeout(45 * 60000, function() if activeCache and activeCache.id == id then activeCache = nil; TriggerClientEvent('outbreak:client:cacheActive', -1, nil) end end)
    ::continue::
  end
end)

RegisterNetEvent('outbreak:server:cacheOpened', function(id)
  if activeCache and activeCache.id == id and not activeCache.bait then
    exports.ox_inventory:forceOpenInventory(source, 'stash', id)
  end
end)

-- Distress calls
local activeDistress = nil
CreateThread(function()
  while true do
    local D = BroadcastCfg.Distress
    Wait(math.random(D.everyMinutes[1], D.everyMinutes[2]) * 60000)
    if activeDistress then goto continue end
    local players = GetPlayers(); if #players == 0 then goto continue end
    local anchor = GetEntityCoords(GetPlayerPed(players[math.random(#players)]))
    local ang = math.random() * 6.283
    local pos = vector3(anchor.x + math.cos(ang) * 350.0, anchor.y + math.sin(ang) * 350.0, anchor.z)
    activeDistress = { id = os.time(), pos = pos, bait = math.random() < D.baitChance }
    local ch = D.channels[math.random(#D.channels)]
    toChannel(ch, 'DISTRESS CALL', D.lines[math.random(#D.lines)]:format('__STREET__'))
    TriggerClientEvent('outbreak:client:distressActive', -1, activeDistress, ch)
    SetTimeout(20 * 60000, function() activeDistress = nil; TriggerClientEvent('outbreak:client:distressActive', -1, nil) end)
    ::continue::
  end
end)

RegisterNetEvent('outbreak:server:distressResolved', function(id)
  if activeDistress and activeDistress.id == id and not activeDistress.bait then
    for _, r in ipairs(BroadcastCfg.Distress.reward) do exports.ox_inventory:AddItem(source, r[1], r[2]) end
    TriggerClientEvent('ox_lib:notify', source, { title = '"Thank you. Take this. Go."', type = 'success' })
    activeDistress = nil
    TriggerClientEvent('outbreak:client:distressActive', -1, nil)
  end
end)
