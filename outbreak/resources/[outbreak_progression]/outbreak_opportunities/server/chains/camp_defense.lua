-- CHAIN 1 — Silo Farm (Grapeseed) horde defense. IMPLEMENTED (untested).
-- Stages: 1 warning → 2 preparation → 3 defense → resolve
-- Solutions: fortify (co-op), lure (solo-friendly), evacuate (anyone, costs the camp)
-- Consequences: camp stats, reputation, intel obsolescence, radio.
local O = function() return exports.outbreak_opportunities end
local CAMP = 'grapeseed'
local ID = 'camp_defense_grapeseed'

local Cfg = {
  warningMinutes = 25,          -- real minutes from warning to first wave
  deliveryRadius = 25.0,
  deliveries = { plank = { cap = 8, defenses = 4 }, nails = { cap = 4, defenses = 3 }, gas_can_small = { cap = 2, power = 35 }, bandage = { cap = 6, meds = 5 } },
  requiredDefensesPerParticipant = 18,  -- fortify success threshold scales with how many signed on (min 1)
  waves = { { size = 12, gap = 90 }, { size = 18, gap = 90 }, { size = 24, gap = 0 } },
  lure = { seconds = 30, noise = 60 },
  rep = { clean = 15, costly = 8, lured = 10, evacuated = 5, overrun = -10, ignored = -10 },
  cooldownMinutes = 240, repeatable = true,
}

local function transmit(text, title) pcall(function() exports.outbreak_radio:transmit(CampCatalog[CAMP].channel, title or 'SILO FARM', text) end) end
local function repAll(r, delta, reason)
  for c in pairs(r.participants) do local s = GetSrcByCid(c); if s then pcall(function() exports.outbreak_faction:addRep(s, 'civilian', delta, reason) end) end end
end
local function camp() return O():getCamp(CAMP) end

-- the rumor drip: every 5 minutes, anyone on channel 4 with a radio hears the camp (server-originated intel)
CreateThread(function()
  Wait(5000)
  pcall(function() exports.outbreak_core:scheduleEvent('camp_grapeseed_rumor', 5, 9, function()
    local c = camp(); if not c or c.state ~= 'alive' then return end
    exports.outbreak_intel:broadcastIntel('camp_grapeseed_rumor', CampCatalog[CAMP].channel, 'FAINT VOICE', '...east of Grapeseed... the farm with the silo... we have water... *static*')
  end) end)
end)

-- once someone has CONFIRMED the camp, the horde warning can be issued (director decides when; debug can force)
local function issueWarning()
  local r = O():get(ID); if r.state ~= 'available' then return end
  local c = camp(); if not c or c.state ~= 'alive' then return end
  O():activate(ID)  -- warning is time-boxed: it activates itself
end

O():registerOpportunity({
  id = ID, title = 'Hold Silo Farm', trigger = 'camp_grapeseed_location', intel = { 'camp_grapeseed_rumor', 'camp_grapeseed_location', 'camp_grapeseed_horde' },
  summary = 'A migration is coming up the river road. The people at Silo Farm can\'t stop it alone. Fortify the fence, pull the horde off with noise, or get everyone out.',
  stages = { { label = 'Warning received' }, { label = 'Preparation: deliver planks, nails, fuel, bandages' }, { label = 'Defense: hold the fence through three waves' } },
  solutions = {
    { id = 'fortify',  label = 'Fortify and hold',   desc = 'Deliver materials at the gate. Guards get better. Hold three waves.', solo = false },
    { id = 'lure',     label = 'Lure the horde away', desc = 'Get to the decoy point south of the camp and make noise for 30 seconds. One person can do this.', solo = true },
    { id = 'evacuate', label = 'Evacuate the camp',   desc = 'Convince them to leave tonight. Nobody dies. Silo Farm is gone.', solo = true },
  },
  cooldownMinutes = Cfg.cooldownMinutes, repeatable = Cfg.repeatable,

  onIntel = function(r, src, intelId)
    if intelId == 'camp_grapeseed_location' then
      pcall(function() exports.outbreak_faction:addRep(src, 'civilian', 2, 'found silo farm') end)
    end
  end,

  onStart = function(r, src)
    r.data.deadline = os.time() + Cfg.warningMinutes * 60
    r.data.contrib = {}; r.data.wave = 0; r.data.kills = 0; r.data.spawned = 0
    transmit('If anyone can hear this — they saw it from the water tower. Hundreds. Coming up the river road. We have maybe half an hour.', 'SILO FARM — URGENT')
    -- everyone who confirmed the location gets the horde intel confirmed
    for _, s in ipairs(exports.outbreak_intel:whoKnows('camp_grapeseed_location', 'confirmed')) do
      exports.outbreak_intel:discover(s, 'camp_grapeseed_horde', 'credible', 'opportunity')
    end
    O():advance(ID, 2, nil, { deadline = r.data.deadline })
  end,

  onRestore = function(r)
    -- resume the deadline watcher from the epoch, not a timer
    CreateThread(function() Wait(2000) TriggerEvent('outbreak:opp:campdef:watch') end)
  end,

  onChoose = function(r, src, sol)
    if r.stage ~= 2 then return false end
    if sol == 'evacuate' then
      O():modifyCamp(CAMP, { state = 'abandoned', population = -100 }, 'evacuated')
      transmit('...that\'s it then. Pack what you can carry. Thank you. Whoever you are, thank you.')
      repAll(r, Cfg.rep.evacuated, 'evacuated silo farm')
      exports.outbreak_intel:obsolete('camp_grapeseed_location', 'evacuated')
      exports.outbreak_intel:obsolete('camp_grapeseed_rumor', 'evacuated')
      O():resolve(ID, 'evacuated', { by = src })
      return true
    end
    if sol == 'lure' then r.data.lureTicks = 0; TriggerClientEvent('outbreak:opp:campdef:decoy', -1, CampCatalog[CAMP].decoy) end
    return true
  end,

  onDeliver = function(r, src, item)
    if r.stage ~= 2 then return end
    local d = Cfg.deliveries[item]; if not d then return end
    if #(GetEntityCoords(GetPlayerPed(src)) - CampCatalog[CAMP].gate) > Cfg.deliveryRadius then return end
    if (r.data.contrib[item] or 0) >= d.cap then TriggerClientEvent('ox_lib:notify', src, { title = 'They have enough of those.', type = 'inform' }) return end
    if not exports.ox_inventory:RemoveItem(src, item, 1) then return end
    O():contribute(ID, src, item, 1)
    local deltas = {}
    for k, v in pairs(d) do if k ~= 'cap' then deltas[k] = v end end
    O():modifyCamp(CAMP, deltas, 'delivery:' .. item)
    pcall(function() exports.outbreak_skills:grantXP(src, 'search') end)
    TriggerClientEvent('outbreak:opp:campdef:camp', -1, camp())
    TriggerClientEvent('ox_lib:notify', src, { title = ('Delivered %s. Defenses %d, power %d.'):format(item:gsub('_', ' '), camp().defenses, camp().power), type = 'success' })
  end,

  onReport = function(r, src, kind, p)
    if kind == 'kills' and r.stage == 3 then
      -- accept only up to what this wave spawned, across everyone
      local n = math.max(0, math.min(tonumber(p and p.n) or 0, (r.data.spawned or 0) - (r.data.kills or 0)))
      if n > 0 then r.data.kills = r.data.kills + n; O():contribute(ID, src, 'kills', n) end
    elseif kind == 'decoy' and r.stage == 2 and r.data.solution == 'lure' then
      if #(GetEntityCoords(GetPlayerPed(src)) - CampCatalog[CAMP].decoy) > 15.0 then return end
      if (tonumber(p and p.noise) or 0) < Cfg.lure.noise then r.data.lureTicks = 0 return end  -- trust gap: noise is client-reported
      r.data.lureTicks = (r.data.lureTicks or 0) + 1
      if r.data.lureTicks >= Cfg.lure.seconds then
        O():modifyCamp(CAMP, { morale = 15, threat = -20 }, 'horde lured')
        transmit('...they\'re turning. Whatever you\'re doing out there, it\'s working. They\'re turning south.')
        repAll(r, Cfg.rep.lured, 'lured the horde')
        exports.outbreak_intel:setState(src, 'camp_grapeseed_horde', 'completed', 'opportunity')
        O():resolve(ID, 'lured', { by = src })
      end
    end
  end,

  onStage = function(r, stage, data)
    if stage == 3 then
      r.data.wave = 1; r.data.spawned = Cfg.waves[1].size
      TriggerClientEvent('outbreak:opp:campdef:wave', -1, 1, Cfg.waves[1].size, CampCatalog[CAMP].entries.south, camp())
      transmit('Here they come. South fence. Everyone who can hold a gun, HOLD IT.')
    end
  end,

  onResolve = function(r, state, outcome)
    local c = camp()
    if state == 'expired' then
      O():modifyCamp(CAMP, { state = 'overrun', population = -100, defenses = -100, threat = 100 }, 'overrun')
      transmit('...they\'re inside... they\'re inside the-- *static*')
      for _, s in ipairs(exports.outbreak_intel:whoKnows('camp_grapeseed_location', 'confirmed')) do pcall(function() exports.outbreak_faction:addRep(s, 'civilian', Cfg.rep.ignored, 'let silo farm fall') end) end
      exports.outbreak_intel:obsolete('camp_grapeseed_location', 'overrun')
      exports.outbreak_intel:obsolete('camp_grapeseed_rumor', 'overrun')
    elseif outcome == 'clean' then
      O():modifyCamp(CAMP, { morale = 25, population = 2, defenses = 10, threat = -30 }, 'clean defense')
      transmit('Fence held. FENCE HELD. Get in here, all of you. There\'s soup.'); repAll(r, Cfg.rep.clean, 'held silo farm')
    elseif outcome == 'costly' then
      O():modifyCamp(CAMP, { morale = -10, population = -4, defenses = -20, meds = -10 }, 'costly defense')
      transmit('We held. We... we lost people. Thank you for coming.'); repAll(r, Cfg.rep.costly, 'held silo farm, losses')
    elseif outcome == 'overrun' then
      O():modifyCamp(CAMP, { state = 'overrun', population = -100, defenses = -100 }, 'overrun in defense')
      transmit('*screaming* *static*'); repAll(r, Cfg.rep.overrun, 'silo farm fell')
      exports.outbreak_intel:obsolete('camp_grapeseed_location', 'overrun')
    end
    TriggerClientEvent('outbreak:opp:campdef:end', -1, outcome)
  end,

  debug = {
    warn = function(r, src) issueWarning() end,
    wave = function(r) if r.state == 'active' and r.stage == 2 then r.data.deadline = os.time() end end,
  },
})

-- deadline watcher (one loop; survives restart via onRestore)
local watching = false
AddEventHandler('outbreak:opp:campdef:watch', function()
  if watching then return end
  watching = true
  CreateThread(function()
    while true do
      Wait(5000)
      local r = O():get(ID)
      if r.state == 'active' and r.stage == 2 and r.data.deadline and os.time() >= r.data.deadline then
        -- nobody engaged at all? it's ignored → expired. Otherwise waves.
        if O():participantCount(ID) == 0 and r.data.solution == nil then O():expire(ID, { reason = 'nobody came' })
        else O():advance(ID, 3, nil, {}) end
      elseif r.state == 'active' and r.stage == 3 and r.data.waveEndsAt and os.time() >= r.data.waveEndsAt then
        local w = r.data.wave
        local killed = r.data.kills or 0
        local c = camp()
        -- wave outcome: kills + defenses vs wave size
        local held = killed + (c.defenses / 4) + (c.power > 0 and 4 or 0) >= Cfg.waves[w].size * 0.6
        if not held then
          O():modifyCamp(CAMP, { defenses = -25, population = -2, morale = -15 }, 'wave ' .. w .. ' breached')
          if c.defenses <= 25 then O():resolve(ID, 'overrun', { wave = w }) goto continue end
        end
        if w >= #Cfg.waves then
          local participants = math.max(1, O():participantCount(ID))
          local clean = (c.defenses >= Cfg.requiredDefensesPerParticipant * math.min(participants, 3) * 0.5) and killed >= (r.data.spawned * 0.5)
          O():resolve(ID, clean and 'clean' or 'costly', { kills = killed, spawned = r.data.spawned })
        else
          r.data.wave = w + 1; r.data.spawned = (r.data.spawned or 0) + Cfg.waves[w + 1].size; r.data.waveEndsAt = nil
          O():setData(ID, 'wave', r.data.wave)
          TriggerClientEvent('outbreak:opp:campdef:wave', -1, r.data.wave, Cfg.waves[r.data.wave].size, CampCatalog[CAMP].entries[r.data.wave == 2 and 'west' or 'south'], camp())
        end
      elseif r.state == 'active' and r.stage == 3 and not r.data.waveEndsAt then
        r.data.waveEndsAt = os.time() + 120 + Cfg.waves[r.data.wave].gap  -- a wave lasts ~2 min + gap
        O():setData(ID, 'waveEndsAt', r.data.waveEndsAt)
      end
      ::continue::
    end
  end)
end)
CreateThread(function() Wait(3000) TriggerEvent('outbreak:opp:campdef:watch') end)

-- the director issues the warning some time after the camp is confirmed by anyone
AddEventHandler('outbreak:intel:confirmed', function(src, intelId, oppId)
  if oppId ~= ID or intelId ~= 'camp_grapeseed_location' then return end
  SetTimeout(math.random(8, 20) * 60000, issueWarning)
end)
