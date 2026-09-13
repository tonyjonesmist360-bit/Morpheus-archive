-- outbreak_intel/server/sources.lua — the ways intel enters a character's head
local QBCore = exports['qb-core']:GetCoreObject()

-- 1) DOCUMENT items: ox item 'document' with metadata.intel = intelId (set server-side when granted)
QBCore.Functions.CreateUseableItem(IntelCfg.DocumentItem, function(src, item)
  local id = item and item.metadata and item.metadata.intel
  if not id or not IntelCatalog[id] then return end
  TriggerClientEvent('outbreak:anim:play', src, 'read', 4000)
  SetTimeout(3500, function()
    if exports.ox_inventory:RemoveItem(src, IntelCfg.DocumentItem, 1, nil, item.slot) then
      local lvl = exports.outbreak_intel:discover(src, id, IntelCatalog[id].reliability, 'document')
      TriggerClientEvent('ox_lib:notify', src, { title = IntelCatalog[id].title, description = lvl and ('Recorded in your journal (%s).'):format(lvl) or 'You already knew this.', type = 'inform', duration = 8000 })
    end
  end)
end)
exports('giveRandomDocument', function(src)
  local pool = {}
  for id, def in pairs(IntelCatalog) do if def.sources and def.sources.document and not def.stub then pool[#pool + 1] = id end end
  if #pool == 0 then return false end
  return exports.outbreak_intel:giveDocument(src, pool[math.random(#pool)])
end)
exports('giveDocument', function(src, intelId)
  local def = IntelCatalog[intelId]; if not def then return false end
  return exports.ox_inventory:AddItem(src, IntelCfg.DocumentItem, 1, { intel = intelId, description = def.title })
end)

-- 2) RADIO: server-originated only. Grant on client ack (channel is client-reported: trust gap, rate-limited, radio item required)
exports('broadcastIntel', function(intelId, channel, title, text, target)
  local def = IntelCatalog[intelId]; if not def or not def.sources.radio then return end
  pcall(function() exports.outbreak_radio:transmit(channel, title, text, target) end)
  TriggerClientEvent('outbreak:intel:radioOffer', target or -1, intelId, channel)
end)
local acks = {}
RegisterNetEvent('outbreak:intel:radioAck', function(intelId, myChannel)
  local src = source
  local def = IntelCatalog[intelId]; if not def or not def.sources.radio then return end
  if type(myChannel) ~= 'number' or myChannel <= 0 then return end
  if exports.ox_inventory:GetItemCount(src, 'radio_handheld') < 1 then return end
  local k = src .. ':' .. intelId
  if acks[k] and os.time() - acks[k] < 30 then return end
  acks[k] = os.time()
  exports.outbreak_intel:discover(src, intelId, def.reliability, 'radio')
end)
-- 3) NPC: chains call discover(src, id, rel, 'npc') from a validated, distance-checked conversation
-- 4) ARRIVAL: server/intel.lua
-- 5) OPPORTUNITY: setState / discover(..., 'opportunity')
