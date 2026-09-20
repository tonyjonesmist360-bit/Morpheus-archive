-- outbreak_craft/client/craft.lua : /craft or keybind opens the menu
local function openCraft(atBench)
  local opts = {}
  for _, r in ipairs(CraftCfg.Recipes) do
    if r.bench and not atBench then goto skip end
    local needs = {}
    for _, n in ipairs(r.needs) do
      needs[#needs + 1] = (n[2] > 0 and (n[2] .. 'x ') or 'requires ') .. n[1]:gsub('_', ' ')
    end
    opts[#opts + 1] = {
      title = r.label,
      description = r.desc .. '  [' .. table.concat(needs, ', ') .. ']',
      onSelect = function()
        if lib.progressCircle({ duration = CraftCfg.Seconds * 1000, label = 'Crafting ' .. r.label .. '...',
            canCancel = true, disable = { move = true, combat = true },
            anim = { dict = 'mini@repair', clip = 'fixing_a_ped' } }) then
          TriggerServerEvent('outbreak:server:craft', r.id, atBench == true)
        end
      end,
    }
    ::skip::
  end
  if not atBench then opts[#opts + 1] = { title = 'More at a workbench', description = 'Molotov, barricade kit, key blank, padlock. Garages and tool benches, or set down a workbench.', icon = 'screwdriver-wrench', readOnly = true } end
  lib.registerContext({ id = 'outbreak_craft', title = atBench and 'Workbench' or 'Improvise', options = opts })
  lib.showContext('outbreak_craft')
end

RegisterCommand('craft', function() openCraft(false) end, false)  -- key lives in outbreak_binds
RegisterNetEvent('outbreak:client:crafted', function() local s = CraftCfg.Sound; if s then PlaySoundFrontend(-1, s[1], s[2], true) end end)
-- fixed bench sites (zones, no prop names)
CreateThread(function()
  for _, b in ipairs(CraftCfg.BenchSites or {}) do
    exports.ox_target:addSphereZone({ coords = b.pos, radius = 2.5, options = { { label = 'Use the workbench', icon = 'fa-solid fa-screwdriver-wrench', onSelect = function() openCraft(true) end } } })
  end
end)
-- the bench: map tool benches and placed workbenches open the full list
CreateThread(function()
  local models = {}
  for _, m in ipairs(CraftCfg.BenchModels or {}) do models[#models + 1] = joaat(m) end
  if #models == 0 then return end
  exports.ox_target:addModel(models, { { label = 'Use the workbench', icon = 'fa-solid fa-screwdriver-wrench', onSelect = function() openCraft(true) end } })
end)
