-- CHAIN 3 — The buried cache. IMPLEMENTED on outbreak_weapons (untested).
-- Intel: three torn journal pages (documents; page 3 carries exact coordinates). Reading all three makes the opportunity available.
-- Stages: 1 assemble the journal -> 2 reach the pylon (military patrol nearby) -> 3 open the footlocker
-- Solutions: dig (solo: pry it open quietly; a patrol within 60 m investigates noise) | military (hand the pages to the Quartermaster: rep, a cut, the cache seeds the armory)
-- Reward: one legendary weapon, a small ammo lot, gun oil, dog tags. Drawbacks are the weapon's own (noise, jams, raider attention).
local O = function() return exports.outbreak_opportunities end
local ID = 'weapons_cache'
local Cfg = {
  site = vec3(-2044.0, 3170.0, 32.8), pages = { 'cache_journal_1', 'cache_journal_2', 'cache_journal_3' },
  stash = 'cache_pylon3', legendary = { 'WEAPON_MG', 'WEAPON_SNIPERRIFLE', 'WEAPON_REVOLVER' },
  ammoFor = { WEAPON_MG = { 'ammo-rifle', 120 }, WEAPON_SNIPERRIFLE = { 'ammo-sniper', 20 }, WEAPON_REVOLVER = { 'ammo-44', 24 } },
  patrol = { count = 2, radius = 60.0 }, digNoise = 60,
  rep = { military = 15, cut = { { 'gun_oil', 2 }, { 'ammo-rifle', 30 } } },
  cooldownMinutes = 0, repeatable = false,
}
local function transmit(t, title, origin) pcall(function() exports.outbreak_radio:transmit(0, title or 'STATIC', t, nil, origin, 2000.0) end) end
local function hasAllPages(src) for _, p in ipairs(Cfg.pages) do if not exports.outbreak_intel:hasIntel(src, p, 'partial') then return false end end return true end

O():registerOpportunity({
  id = ID, title = 'The buried cache', trigger = 'cache_journal_3', intel = Cfg.pages,
  summary = 'A soldier\'s field journal in three torn pages. He buried something under the third pylon past the Zancudo bridge and locked it with a birthday. There\'s a patrol that still walks that road.',
  stages = { { label = 'Assemble all three pages' }, { label = 'Reach the third pylon' }, { label = 'Open the footlocker' } },
  solutions = {
    { id = 'dig',      label = 'Dig it up quietly',            desc = 'Pry the lock. Every miss is loud, and the patrol listens.', solo = true },
    { id = 'military', label = 'Hand the pages to the Remnant', desc = 'The Quartermaster sends a team. You get a cut and their trust. The gun goes in their armory.', solo = true },
  },
  cooldownMinutes = Cfg.cooldownMinutes, repeatable = Cfg.repeatable,
  onIntel = function(r, src, intelId)
    -- available only when the reader holds all three pages; the registry made it available on page 3 alone, so gate here
    if not hasAllPages(src) then TriggerClientEvent('ox_lib:notify', src, { title = 'A page is missing. The coordinates mean nothing without the rest.', type = 'inform' }) end
  end,
  onStart = function(r, src)
    if not hasAllPages(src) then return end
    r.data.weapon = Cfg.legendary[math.random(#Cfg.legendary)]
    exports.ox_inventory:RegisterStash(Cfg.stash, 'Footlocker', 10, 40000, nil)
    if next(exports.ox_inventory:GetInventoryItems(Cfg.stash) or {}) == nil then
      exports.ox_inventory:AddItem(Cfg.stash, r.data.weapon, 1)
      local a = Cfg.ammoFor[r.data.weapon]; exports.ox_inventory:AddItem(Cfg.stash, a[1], a[2])
      exports.ox_inventory:AddItem(Cfg.stash, 'gun_oil', 1); exports.ox_inventory:AddItem(Cfg.stash, 'dog_tags', 1, { name = 'CPL. M. REYES' })
    end
    O():advance(ID, 2, src, {})
    TriggerClientEvent('outbreak:opp:cache:site', -1, Cfg.site, Cfg.patrol)
  end,
  onStage = function(r, stage) end,
  onRestore = function(r) TriggerClientEvent('outbreak:opp:cache:site', -1, Cfg.site, Cfg.patrol) end,
  onChoose = function(r, src, sol)
    if sol == 'military' then
      if r.stage >= 3 then return false end
      pcall(function() exports.outbreak_faction:addRep(src, 'military', Cfg.rep.military, 'turned in the reyes journal') end)
      for _, c in ipairs(Cfg.rep.cut) do exports.ox_inventory:AddItem(src, c[1], c[2]) end
      pcall(function() exports.ox_inventory:AddItem('mil_armory', r.data.weapon, 1) end)
      exports.ox_inventory:ClearInventory(Cfg.stash)
      transmit('...recovery team to the third pylon. Reyes\' locker. Good work, civilian.', 'MILITARY NET', Cfg.site)
      for _, p in ipairs(Cfg.pages) do exports.outbreak_intel:obsolete(p, 'turned in') end
      O():resolve(ID, 'military', { by = src, weapon = r.data.weapon })
    end
    return true
  end,
  onReport = function(r, src, kind, p)
    if kind == 'arrived' and r.stage == 2 then
      if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.site) > 8.0 then return end
      O():advance(ID, 3, src, {})
    elseif kind == 'opened' and r.stage == 3 and r.data.solution == 'dig' then
      if #(GetEntityCoords(GetPlayerPed(src)) - Cfg.site) > 5.0 then return end
      exports.ox_inventory:forceOpenInventory(src, 'stash', Cfg.stash)
      pcall(function() exports.outbreak_skills:grantXP(src, 'cache') end)
      transmit('Gunfire will follow. It always does.', 'STATIC', Cfg.site)
      O():resolve(ID, 'dug', { by = src, weapon = r.data.weapon })
    end
  end,
  onResolve = function(r, state, outcome) TriggerClientEvent('outbreak:opp:cache:end', -1, outcome) end,
  debug = { pages = function(r, src) for _, p in ipairs(Cfg.pages) do exports.outbreak_intel:giveDocument(src, p) end end },
})
