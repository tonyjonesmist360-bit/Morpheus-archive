-- outbreak_craft/client/craft.lua : /craft or keybind opens the menu
local function openCraft()
  local opts = {}
  for _, r in ipairs(CraftCfg.Recipes) do
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
          TriggerServerEvent('outbreak:server:craft', r.id)
        end
      end,
    }
  end
  lib.registerContext({ id = 'outbreak_craft', title = 'Improvise', options = opts })
  lib.showContext('outbreak_craft')
end

RegisterCommand('craft', openCraft, false)  -- key lives in outbreak_binds
