-- outbreak_identity/client/identity.lua
local function traitOptions(list)
  local o = {}
  for _, t in ipairs(list) do o[#o + 1] = { value = t.id, label = t.label, description = t.desc } end
  return o
end

-- Opens illenium's creator. Bounded and non-blocking: its NUI can hang (SHAKEDOWN-NOTES
-- FB-7) and nothing here is allowed to strand the player. Returns true if it handed
-- control back cleanly.
local function openCreator()
  local ok = pcall(function() exports['illenium-appearance']:startPlayerCustomization(function() end) end)
  if not ok then return false end
  Wait(500)
  local waited = 0
  while IsNuiFocused() and waited < 90000 do Wait(500); waited = waited + 500 end
  if waited >= 90000 then SetNuiFocus(false, false); return false end
  return true
end

RegisterNetEvent('outbreak:client:createSurvivor', function()
  -- ORDER MATTERS. Identity runs FIRST because it is the half that feeds gameplay -
  -- traits set starting skill levels, the callsign is what other survivors see. The
  -- creator is cosmetic, it is the half that is currently broken, and putting it first
  -- meant one broken dependency blocked character creation entirely. See FB-7 / EV-1.
  local input = lib.inputDialog('WHO WERE YOU', {
    { type = 'input', label = 'Callsign / what people call you', required = true, max = 20 },
    { type = 'select', label = 'Former life', required = true, options = (function() local o = {} for _, f in ipairs(IdentityCfg.FormerLives) do o[#o + 1] = { value = f, label = f } end return o end)() },
    { type = 'textarea', label = 'What people notice about you', description = 'One or two lines. This is what others see when they /look at you.', required = true, max = 160 },
    { type = 'multi-select', label = 'Strengths (pick 2)', required = true, options = traitOptions(IdentityCfg.Traits.positive) },
    { type = 'select', label = 'Flaw (pick 1)', required = true, options = traitOptions(IdentityCfg.Traits.negative) },
  })
  if not input then
    -- Dismissed. Re-ask, but never in a tight loop.
    Wait(2000)
    TriggerEvent('outbreak:client:createSurvivor')
    return
  end
  local pos = input[4] or {}
  if #pos > 2 then pos = { pos[1], pos[2] } end
  local traits = { pos[1], pos[2], input[5] }
  TriggerServerEvent('outbreak:server:saveIdentity', { callsign = input[1], former = input[2], description = input[3], traits = traits })
  lib.notify({ title = 'That\'s who you were.', description = 'Now stay alive.', type = 'inform', duration = 7000 })

  -- Then the mirror. Failure here costs you a face, not a character.
  Wait(800)
  if not openCreator() then
    lib.notify({ title = 'The mirror is cracked.', description = 'Appearance editor did not open. Use /wardrobe to try again later.', type = 'warning', duration = 9000 })
  end
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
