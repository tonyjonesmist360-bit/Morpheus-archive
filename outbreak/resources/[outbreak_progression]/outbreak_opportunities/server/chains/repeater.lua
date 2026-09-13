-- CHAIN 4 — Mount Chiliad repeater. IMPLEMENTED on the outbreak_radio range model (untested).
-- Intel: repeater_tower (discovery by arrival; NPC partial). Stages: 1 deliver 2 car batteries -> 2 deliver a radio coil -> 3 boot: hold the tower 3 minutes.
-- Solutions: restore (co-op) | dawn boot (solo: boot in daylight, half the horde, and the boot can't be stopped once started)
-- Consequences: repeater active for everyone (huge coverage), channel 16 maritime broadcasts begin (feeds chain 5), civilian rep.
local O = function() return exports.outbreak_opportunities end
local ID = 'repeater'
local Cfg = {
  tower = vec3(501.0, 5604.0, 797.9), deliveryRadius = 12.0,
  deliveries = { car_battery = { cap = 2 }, radio_coil = { cap = 1 } },
  bootSeconds = 180, hordeSize = 20, dawnHordeSize = 10, damageSeconds = 30, -- zombie within 5 m for 30 cumulative s = damaged
  rep = { restored = 8 }, cooldownMinutes = 0, repeatable = false,
}
local function transmit(t, title, origin) pcall(function() exports.outbreak_radio:transmit(0, title or 'STATIC', t, nil, origin, 9000.0) end) end
local function isDay() local t = GlobalState.obTime or 420; local h = math.floor(t / 60); return h >= 7 and h <= 18 end

O():registerOpportunity({
  id = ID, title = 'Mount Chiliad repeater', trigger = 'repeater_tower', intel = { 'repeater_tower' },
  summary = 'A dead repeater on the summit. Two car batteries, a radio coil, and three minutes of holding the fence while it boots. After that, every radio in the county reaches farther — and the sea starts talking.',
  stages = { { label = 'Deliver two car batteries' }, { label = 'Deliver a radio coil' }, { label = 'Boot: hold the tower for 3 minutes' } },
  solutions = {
    { id = 'restore', label = 'Boot it now',          desc = 'Start the boot whenever you\'re ready. Full horde. Bring friends.', solo = false },
    { id = 'dawn',    label = 'Boot it in daylight',  desc = 'Start between 07:00 and 18:00: half the horde. Once it starts it can\'t be stopped — you can even retreat downhill.', solo = true },
  },
  cooldownMinutes = Cfg.cooldownMinutes, repeatable = Cfg.repeatable,
  onStart = function(r, src) r.data.contrib = {}; r.data.damage = 0; O():advance(ID, 2, src, {}) end,  -- stage numbering: 1 is the arrival itself
  onStage = function(r, stage) end,
  onRestore = function(r) if r.data.bootEndsAt then TriggerEvent('outbreak:opp:repeater:watch') end end,
  onDeliver = function(r, src, item)
    if r.stage ~= 2 then return end
    local d = Cfg.deliveries[item]; if not d then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.tower) > Cfg.deliveryRadius then return end
    if (r.data.contrib[item] or 0) >= d.cap then TriggerClientEvent('ox_lib:notify', src, { title = 'Already fitted.', type = 'inform' }) return end
    if not exports.ox_inventory:RemoveItem(src, item, 1) then return end
    O():contribute(ID, src, item, 1)
    pcall(function() exports.outbreak_skills:grantXP(src, 'repair') end)
    if (r.data.contrib.car_battery or 0) >= 2 and (r.data.contrib.radio_coil or 0) >= 1 then
      O():advance(ID, 3, src, {})
      TriggerClientEvent('ox_lib:notify', src, { title = 'Everything\'s fitted. Choose how to boot it in your journal.', type = 'success', duration = 8000 })
    else
      TriggerClientEvent('ox_lib:notify', src, { title = ('Fitted %s.'):format(item:gsub('_', ' ')), type = 'success' })
    end
  end,
  onChoose = function(r, src, sol)
    if r.stage ~= 3 or r.data.bootEndsAt then return false end
    if sol == 'dawn' and not isDay() then TriggerClientEvent('ox_lib:notify', src, { title = 'Not daylight. Wait, or boot it now and pay for it.', type = 'error' }) return false end
    if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.tower) > Cfg.deliveryRadius then TriggerClientEvent('ox_lib:notify', src, { title = 'You have to be at the tower to throw the switch.', type = 'error' }) return false end
    r.data.bootEndsAt = os.time() + Cfg.bootSeconds; r.data.damage = 0
    O():setData(ID, 'bootEndsAt', r.data.bootEndsAt)
    local size = sol == 'dawn' and Cfg.dawnHordeSize or Cfg.hordeSize
    TriggerClientEvent('outbreak:opp:repeater:boot', -1, Cfg.tower, size, r.data.bootEndsAt)
    pcall(function() exports.outbreak_core:fireEvent('horde', src, { size = size }) end)
    TriggerEvent('outbreak:opp:repeater:watch')
    return true
  end,
  onReport = function(r, src, kind, p)
    if kind == 'towerDamage' and r.data.bootEndsAt then
      if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.tower) > 60.0 then return end
      r.data.damage = math.min(Cfg.damageSeconds, (r.data.damage or 0) + math.min(5, tonumber(p and p.seconds) or 0)) -- capped per report (trust gap)
    end
  end,
  onResolve = function(r, state, outcome)
    if outcome == 'restored' then
      exports.outbreak_radio:setRepeater('chiliad', true, 'restored by survivors')
      transmit('...this is Chiliad relay, automated. Relay online. Relay online. Repeating on all channels.', 'CHILIAD RELAY', Cfg.tower)
      for c in pairs(O():participants(ID)) do local s = GetSrcByCid(c); if s then pcall(function() exports.outbreak_faction:addRep(s, 'civilian', Cfg.rep.restored, 'restored the repeater') end) end end
      -- the sea starts talking: chain 5's opening rumor now broadcasts on 16 from far offshore, reachable only through the relay
      pcall(function() exports.outbreak_core:scheduleEvent('island_maritime', 12, 25, function()
        if not exports.outbreak_radio:isRepeaterActive('chiliad') then return end
        exports.outbreak_intel:broadcastIntel('island_maritime', 16, 'MARITIME', '...all vessels... the light is still on... we can take twelve more... bearing... *static*')
      end) end)
    elseif outcome == 'damaged' then
      transmit('...relay boot aborted. Coil failure. Coil failure.', 'CHILIAD RELAY', Cfg.tower)
    end
  end,
  debug = { kit = function(r, src) exports.ox_inventory:AddItem(src, 'car_battery', 2); exports.ox_inventory:AddItem(src, 'radio_coil', 1) end },
})

local watching = false
AddEventHandler('outbreak:opp:repeater:watch', function()
  if watching then return end
  watching = true
  CreateThread(function()
    while true do
      Wait(5000)
      local r = O():get(ID)
      if not r or r.state ~= 'active' or not r.data.bootEndsAt then watching = false return end
      if (r.data.damage or 0) >= Cfg.damageSeconds then
        r.data.bootEndsAt = nil; r.data.contrib.radio_coil = 0; O():setData(ID, 'bootEndsAt', nil)
        TriggerClientEvent('outbreak:opp:repeater:end', -1, 'damaged')
        transmit('...relay boot aborted. Coil failure.', 'CHILIAD RELAY', Cfg.tower)
        -- not resolved: the coil is burnt, bring another (stage back to 2)
        r.stage = 2; O():setData(ID, 'stage', 2)
        watching = false; return
      end
      if os.time() >= r.data.bootEndsAt then
        TriggerClientEvent('outbreak:opp:repeater:end', -1, 'restored')
        O():resolve(ID, 'restored', { damage = r.data.damage })
        watching = false; return
      end
    end
  end)
end)
