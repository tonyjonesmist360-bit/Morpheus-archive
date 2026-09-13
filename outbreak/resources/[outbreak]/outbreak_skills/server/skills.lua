-- outbreak_skills/server/skills.lua
local QBCore = exports['qb-core']:GetCoreObject()
local cache = {}  -- src -> { xp = {skill=n}, traits = {...} }

local function cid(src) local p = QBCore.Functions.GetPlayer(src); return p and p.PlayerData.citizenid end

local function load(src)
  local id = cid(src); if not id then return end
  local row = MySQL.single.await('SELECT xp FROM outbreak_skills WHERE citizenid = ?', { id })
  local xp = row and json.decode(row.xp) or {}
  for _, s in ipairs(SkillCfg.Skills) do xp[s] = xp[s] or 0 end
  local ident = MySQL.single.await('SELECT traits FROM outbreak_identity WHERE citizenid = ?', { id })
  cache[src] = { xp = xp, traits = ident and json.decode(ident.traits or '[]') or {} }
  Player(src).state:set('scavLevel', math.floor(xp.scavenging / SkillCfg.XPPerLevel), true)
  TriggerClientEvent('outbreak:client:skills', src, cache[src])
end

local function save(src)
  local id = cid(src); local c = cache[src]; if not id or not c then return end
  MySQL.prepare('INSERT INTO outbreak_skills (citizenid, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(xp)', { id, json.encode(c.xp) })
end

AddEventHandler('QBCore:Server:PlayerLoaded', function(player) load(player.PlayerData.source) end)
AddEventHandler('playerDropped', function() save(source); cache[source] = nil end)

AddEventHandler('outbreak:server:traitsSet', function(src, traits)
  Wait(500); load(src)
  local c = cache[src]; if not c then return end
  for _, t in ipairs(traits) do
    local start = SkillCfg.TraitStarts[t]
    if start then for s, v in pairs(start) do c.xp[s] = math.max(c.xp[s], v) end end
  end
  save(src); TriggerClientEvent('outbreak:client:skills', src, c)
end)

local function hasTrait(c, id) for _, t in ipairs(c.traits or {}) do if t == id then return true end end return false end

-- Any resource: TriggerEvent('outbreak:server:xp', src, 'repair')  (server) or TriggerServerEvent('outbreak:server:xp', 'repair') (client)
local function grant(src, action)
  local c = cache[src]; if not c then return end
  local amt = SkillCfg.XP[action]; if not amt then return end
  local skill = ({ repair = 'mechanics', battery = 'mechanics', hotwire = 'mechanics', bandage = 'medicine', splint = 'medicine', stabilize = 'medicine',
                   sneak_tick = 'stealth', sprint_tick = 'fitness', search = 'scavenging', cache = 'scavenging' })[action]
  local mult = 1.0
  for t, m in pairs(SkillCfg.TraitXPMult) do if hasTrait(c, t) then mult = mult * m end end
  local before = math.floor(c.xp[skill] / SkillCfg.XPPerLevel)
  c.xp[skill] = math.min(SkillCfg.MaxLevel * SkillCfg.XPPerLevel, c.xp[skill] + amt * mult)
  local after = math.floor(c.xp[skill] / SkillCfg.XPPerLevel)
  if after > before then TriggerClientEvent('ox_lib:notify', src, { title = ('%s: level %d'):format(skill:gsub('^%l', string.upper), after), type = 'success' }) end
  Player(src).state:set('scavLevel', math.floor(c.xp.scavenging / SkillCfg.XPPerLevel), true)
  TriggerClientEvent('outbreak:client:skills', src, c)
end
RegisterNetEvent('outbreak:server:xp', function(action) grant(source, action) end)
AddEventHandler('outbreak:server:grantXP', grant)

CreateThread(function() while true do Wait(120000) for src in pairs(cache) do save(src) end end end)

exports('hasTrait', function(src, id) local c = cache[src]; return c and hasTrait(c, id) or false end)
exports('getLevel', function(src, skill) local c = cache[src]; return c and math.floor((c.xp[skill] or 0) / SkillCfg.XPPerLevel) or 0 end)
exports('grantXP', grant)
