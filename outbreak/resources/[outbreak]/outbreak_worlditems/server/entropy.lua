-- outbreak_worlditems/server/entropy.lua — the world pushes back. NPCs tidy, scavengers replace, raiders break in, food rots.
local E = WorldItemsCfg.Entropy
local WI = function() return exports.outbreak_worlditems end
local lastRaid = 0

local function campAt(pos)  -- soft: progression's camp catalog if present
  local ok, res = pcall(function() return exports.outbreak_opportunities:campAt(pos) end)
  return ok and res or nil
end

CreateThread(function()
  while true do
    Wait(E.tickMinutes * 60000)
    local now = os.time()
    -- 1) camp residents tidy strangers' junk into the camp cache ("NPCs put it back")
    for id, rec in pairs(WI():list()) do
      local camp = campAt(rec.pos)
      if camp and now - rec.at > E.camps.tidyAfterHours * 3600 and rec.by ~= 'world' then
        pcall(function() exports.ox_inventory:AddItem(camp.stash, rec.item, rec.count, rec.metadata) end)
        WI():remove(id)
        pcall(function() exports.outbreak_radio:transmit(4, 'SILO FARM', 'Whoever left the ' .. rec.item:gsub('_', ' ') .. ' by the fence — it\'s in the store now. We don\'t leave things out.', nil, rec.pos, 3000.0) end)
      end
    end
    -- 2) taken map props come back: someone replaced it
    for id, h in pairs(WI():hidden()) do
      if h.shelf then
        local hours = campAt(h.pos) and WorldItemsCfg.ShelfRestock.nearCampHours or WorldItemsCfg.ShelfRestock.hours
        if now - h.at > hours * 3600 then WI():restoreProp(id) end
      elseif now - h.at > E.takeables.restoreAfterHours * 3600 then WI():restoreProp(id) end
    end
    -- 3) perishables rot
    for id, rec in pairs(WI():list()) do
      local hours = E.perishables[rec.item]
      if hours and now - rec.at > hours * 3600 then
        WI():remove(id)
        if rec.item ~= 'rotten_meat' then WI():placeSystem('rotten_meat', 1, {}, rec.pos, rec.rot, 'time') end
      end
    end
    -- 4) raiders break into unlocked storage left outside claimed houses (near roads = in the open)
    if now - lastRaid > E.raiders.checkHours * 3600 then
      lastRaid = now
      for id, rec in pairs(WI():list()) do
        if rec.storage and not rec.locked and not rec.house and math.random() < E.raiders.chance then
          local items = exports.ox_inventory:GetInventoryItems('wi_' .. id) or {}
          local took = 0
          for _, it in pairs(items) do if it and it.name and math.random() < 0.6 then exports.ox_inventory:RemoveItem('wi_' .. id, it.name, it.count, nil, it.slot); took = took + 1 end end
          if took > 0 then
            WI():placeSystem('note', 1, { text = 'THANKS FOR THE DONATION — BONEYARD' }, rec.pos + vector3(0.6, 0.0, 0.0), rec.rot, 'raiders')
            pcall(function() exports.outbreak_radio:transmit(0, 'STATIC', '...found a crate just sitting there... easiest haul all week...', nil, rec.pos, 2500.0) end)
          end
        end
      end
    end
  end
end)
