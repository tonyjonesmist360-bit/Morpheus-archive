-- outbreak_skills/client/skills.lua
local data = { xp = {}, traits = {} }
RegisterNetEvent('outbreak:client:skills', function(d) data = d end)

local function level(skill) return math.floor((data.xp[skill] or 0) / SkillCfg.XPPerLevel) end
local function hasTrait(id) for _, t in ipairs(data.traits or {}) do if t == id then return true end end return false end

exports('getLevel', level)
exports('hasTrait', hasTrait)
exports('effects', function(skill) return SkillCfg.Effects[skill](level(skill)) end)

-- passive XP via the core tick (sampled every 20 ticks = 10s)
local n = 0
AddEventHandler('outbreak:tick', function(t)
  n = n + 1; if n % 20 ~= 0 then return end
  if t.sprinting then TriggerServerEvent('outbreak:server:xp', 'sprint_tick') end
  if t.stealth and t.nearestDist < 15.0 then TriggerServerEvent('outbreak:server:xp', 'sneak_tick') end
end)

RegisterCommand('skills', function()
  local opts = {}
  for _, s in ipairs(SkillCfg.Skills) do
    local xp = data.xp[s] or 0
    opts[#opts + 1] = { title = ('%s — level %d'):format(s:gsub('^%l', string.upper), level(s)), progress = (xp % SkillCfg.XPPerLevel), description = ('%d / %d to next'):format(xp % SkillCfg.XPPerLevel, SkillCfg.XPPerLevel) }
  end
  local tr = {}
  for _, t in ipairs(data.traits or {}) do tr[#tr + 1] = t:gsub('_', ' ') end
  opts[#opts + 1] = { title = 'Traits', description = #tr > 0 and table.concat(tr, ', ') or 'none yet' }
  lib.registerContext({ id = 'ob_skills', title = 'WHAT YOU\'VE LEARNED', options = opts })
  lib.showContext('ob_skills')
end, false)
