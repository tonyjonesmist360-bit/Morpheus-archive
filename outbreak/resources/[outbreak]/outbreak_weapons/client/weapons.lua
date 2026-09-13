-- outbreak_weapons/client/weapons.lua — per-shot noise, jams, condition readout. Reads ox's current weapon; never grants anything.
local jammed = false
local lastShotTick = 0

local function current()
  local ok, w = pcall(function() return exports.ox_inventory:getCurrentWeapon() end)
  return ok and w or nil
end
local function def(name) return name and WeaponCfg.Weapons[name] end

-- per-weapon noise: outbreak_noise asks us instead of using a flat gunshot value
exports('noiseOf', function(hash, suppressed)
  for name, d in pairs(WeaponCfg.Weapons) do
    if joaat(name) == hash then return suppressed and (d.suppressed or d.noise) or d.noise end
  end
  return nil
end)

-- jams: on a shot with low durability, roll; while jammed, attack is disabled until cleared (E)
AddEventHandler('outbreak:tick', function(t)
  if not t.shooting or jammed then return end
  local w = current(); local d = w and def(w.name)
  if not d or d.melee or not d.jamBelow then return end
  local dur = (w.metadata and w.metadata.durability) or 100
  if dur >= d.jamBelow then return end
  local chance = d.jamChance * (1 - dur / d.jamBelow)
  if math.random() < chance then
    jammed = true
    lib.showTextUI('JAMMED — press [E] to clear', { icon = 'gun' })
    CreateThread(function()
      while jammed do
        Wait(0)
        DisableControlAction(0, 24, true); DisableControlAction(0, 257, true); DisableControlAction(0, 140, true)
        if IsControlJustPressed(0, 38) then
          lib.hideTextUI()
          if exports.outbreak_emotes:action('repair', WeaponCfg.Jam.clearSeconds * 1000, 'Clearing the jam...') then jammed = false else lib.showTextUI('JAMMED — press [E] to clear', { icon = 'gun' }) end
        end
      end
    end)
  end
end)

-- signal pistol: a flare is a beacon. Everyone with a radio hears about it; zombies within 200 m converge.
AddEventHandler('outbreak:tick', function(t)
  if not t.shooting then return end
  local w = current(); local d = w and def(w.name)
  if d and d.signal and GetGameTimer() - lastShotTick > 3000 then
    lastShotTick = GetGameTimer()
    TriggerEvent('outbreak:noise:spike', 100)
    TriggerServerEvent('outbreak:weapons:flare')
  end
end)

RegisterCommand('condition', function()
  local w = current(); local d = w and def(w.name)
  if not w then lib.notify({ title = 'Nothing in your hands.', type = 'inform' }) return end
  local dur = (w.metadata and w.metadata.durability) or 100
  lib.notify({ title = ('%s — %d%% condition'):format(d and d.label or w.name, dur), description = d and d.drawback or (dur < (d and d.jamBelow or 30) and 'Jam-prone. Oil it.' or nil), type = dur < 30 and 'error' or 'inform' })
end, false)
