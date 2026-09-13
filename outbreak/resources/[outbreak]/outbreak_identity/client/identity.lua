-- outbreak_identity/client/identity.lua
local function traitOptions(list)
  local o = {}
  for _, t in ipairs(list) do o[#o + 1] = { value = t.id, label = t.label, description = t.desc } end
  return o
end

RegisterNetEvent('outbreak:client:createSurvivor', function()
  -- 1) face + body + clothes in illenium's creator
  -- No config table: illenium builds its own from its config.lua. Passing a flat
  -- { components = true, props = true } made its NUI read .masks/.hats off undefined
  -- and crash, leaving the player frozen in the creator with no UI. See SHAKEDOWN-NOTES FB-7.
  pcall(function() exports['illenium-appearance']:startPlayerCustomization(function() end) end)
  Wait(500)
  -- Bounded wait: illenium's creator NUI can hang (see SHAKEDOWN-NOTES FB-7), and an
  -- unbounded loop here traps the player with no dialog and no way out. After 90s we
  -- give up on the creator and go straight to the identity dialog.
  local waited = 0
  while IsNuiFocused() and waited < 90000 do Wait(500); waited = waited + 500 end
  if waited >= 90000 then SetNuiFocus(false, false) end
  -- 2) who you were
  local input = lib.inputDialog('WHO WERE YOU', {
    { type = 'input', label = 'Callsign / what people call you', required = true, max = 20 },
    { type = 'select', label = 'Former life', required = true, options = (function() local o = {} for _, f in ipairs(IdentityCfg.FormerLives) do o[#o + 1] = { value = f, label = f } end return o end)() },
    { type = 'textarea', label = 'What people notice about you', description = 'One or two lines. This is what others see when they /look at you.', required = true, max = 160 },
    { type = 'multi-select', label = 'Strengths (pick 2)', required = true, options = traitOptions(IdentityCfg.Traits.positive) },
    { type = 'select', label = 'Flaw (pick 1)', required = true, options = traitOptions(IdentityCfg.Traits.negative) },
  })
  if not input then TriggerEvent('outbreak:client:createSurvivor') return end
  local pos = input[4] or {}
  if #pos > 2 then pos = { pos[1], pos[2] } end
  local traits = { pos[1], pos[2], input[5] }
  TriggerServerEvent('outbreak:server:saveIdentity', { callsign = input[1], former = input[2], description = input[3], traits = traits })
  lib.notify({ title = 'That\'s who you were.', description = 'Now stay alive.', type = 'inform', duration = 7000 })
end)

-- /look : read the person in front of you (NoPixel-style description)
RegisterCommand('look', function()
  local me = PlayerPedId(); local mpos = GetEntityCoords(me)
  local best, bd = nil, IdentityCfg.LookRadius
  for _, pid in ipairs(GetActivePlayers()) do
    if pid ~= PlayerId() then
      local d = #(GetEntityCoords(GetPlayerPed(pid)) - mpos)
      if d < bd then best, bd = pid, d end
    end
  end
  if not best then lib.notify({ title = 'Nobody close enough to read.', type = 'inform' }) return end
  local info = lib.callback.await('outbreak:identity:get', false, GetPlayerServerId(best))
  if not info then lib.notify({ title = 'A stranger. Nothing to go on yet.', type = 'inform' }) return end
  lib.notify({ title = ('"%s" — formerly a %s'):format(info.callsign, info.former:lower()), description = info.description, type = 'inform', duration = 9000 })
end, false)

-- /me : local emote text over your head (NoPixel staple)
RegisterCommand('me', function(_, args)
  local text = table.concat(args, ' ')
  if text == '' then return end
  TriggerServerEvent('outbreak:server:me', text)
end, false)
RegisterNetEvent('outbreak:client:me', function(src, text)
  local ped = GetPlayerPed(GetPlayerFromServerId(src))
  if not DoesEntityExist(ped) or #(GetEntityCoords(ped) - GetEntityCoords(PlayerPedId())) > 20.0 then return end
  CreateThread(function()
    local t = GetGameTimer()
    while GetGameTimer() - t < 6000 do
      local c = GetEntityCoords(ped)
      SetDrawOrigin(c.x, c.y, c.z + 1.1, 0)
      SetTextFont(4); SetTextScale(0.32, 0.32); SetTextColour(216, 210, 192, 220); SetTextCentre(true); SetTextOutline()
      BeginTextCommandDisplayText('STRING'); AddTextComponentSubstringPlayerName('* ' .. text .. ' *'); EndTextCommandDisplayText(0.0, 0.0)
      ClearDrawOrigin()
      Wait(0)
    end
  end)
end)

-- Safehouse wardrobe: free clothing changes, no shop, no money (target lives in outbreak_housing)
RegisterCommand('wardrobe', function()
  pcall(function() exports['illenium-appearance']:startPlayerCustomization(function() end) end)
end, false)

-- Shakedown tool: cycle clothing combos slowly to spot clipping
RegisterCommand('outfitcheck', function(_, args)
  local ped = PlayerPedId()
  local comp = tonumber(args[1]) or 11  -- 11 torso, 8 undershirt, 4 legs, 3 arms
  local n = GetNumberOfPedDrawableVariations(ped, comp)
  lib.notify({ title = ('Cycling component %d: %d drawables, 1.5s each'):format(comp, n), type = 'inform' })
  CreateThread(function()
    for i = 0, n - 1 do
      SetPedComponentVariation(ped, comp, i, 0, 0)
      lib.notify({ title = ('comp %d drawable %d'):format(comp, i), type = 'inform', duration = 1400 })
      Wait(1500)
    end
  end)
end, false)
