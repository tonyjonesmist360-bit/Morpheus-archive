-- outbreak_military/client/checkpoints.lua
local active = {} -- id -> {peds}
local MGROUP = `OUTBREAK_MIL`

AddRelationshipGroup('OUTBREAK_MIL')
SetRelationshipBetweenGroups(3, MGROUP, `PLAYER`)  -- dislike (wary, not hostile)
SetRelationshipBetweenGroups(5, MGROUP, `OUTBREAK_ZOMBIES`) -- soldiers fight zombies
SetRelationshipBetweenGroups(5, `OUTBREAK_ZOMBIES`, MGROUP)

local function spawnCheckpoint(cp)
  active[cp.id] = {}
  for i = 1, cp.guards do
    local model = joaat(MilCfg.Models[math.random(#MilCfg.Models)])
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    local ped = CreatePed(4, model,
      cp.pos.x + math.random(-4, 4), cp.pos.y + math.random(-4, 4), cp.pos.z, cp.pos.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedRelationshipGroupHash(ped, MGROUP)
    GiveWeaponToPed(ped, MilCfg.Weapon, 250, false, true)
    SetPedArmour(ped, 100)
    SetPedCombatAttributes(ped, 46, true)
    SetPedAccuracy(ped, 60)
    TaskGuardCurrentPosition(ped, 15.0, 15.0, true)
    active[cp.id][#active[cp.id] + 1] = ped
  end
end

local function despawnCheckpoint(id)
  for _, ped in ipairs(active[id] or {}) do
    if DoesEntityExist(ped) then DeleteEntity(ped) end
  end
  active[id] = nil
end

-- The Quartermaster: spawn once, barter menu via ox_target
CreateThread(function()
  local t = MilCfg.Trader
  if not t then return end
  local model = joaat(t.ped)
  RequestModel(model); while not HasModelLoaded(model) do Wait(50) end
  local ped = CreatePed(4, model, t.offset.x, t.offset.y, t.offset.z, t.offset.w, false, true)
  SetEntityAsMissionEntity(ped, true, true)
  SetEntityInvincible(ped, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  FreezeEntityPosition(ped, true)
  TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_CLIPBOARD', 0, true)
  exports.ox_target:addLocalEntity(ped, {
    {
      label = 'Barter with the Quartermaster',
      icon = 'fa-solid fa-arrows-rotate',
      onSelect = function()
        local opts = {}
        for i, tr in ipairs(t.Trades) do
          opts[#opts + 1] = { title = tr.label,
            onSelect = function() TriggerServerEvent('outbreak:server:barter', i) end }
        end
        lib.registerContext({ id = 'ob_barter', title = 'QUARTERMASTER — no cash, no credit', options = opts })
        lib.showContext('ob_barter')
      end,
    },
  })
end)

CreateThread(function()
  for _, cp in ipairs(MilCfg.Checkpoints) do
    local blip = AddBlipForCoord(cp.pos.x, cp.pos.y, cp.pos.z)
    SetBlipSprite(blip, 543); SetBlipColour(blip, 25); SetBlipScale(blip, 0.7)
    BeginTextCommandSetBlipName('STRING'); AddTextComponentString(cp.label); EndTextCommandSetBlipName(blip)
  end
  while true do
    Wait(3000)
    local ppos = GetEntityCoords(PlayerPedId())
    for _, cp in ipairs(MilCfg.Checkpoints) do
      local d = #(ppos - vec3(cp.pos.x, cp.pos.y, cp.pos.z))
      if d < MilCfg.SpawnDistance and not active[cp.id] then
        spawnCheckpoint(cp)
      elseif d >= MilCfg.SpawnDistance + 50 and active[cp.id] then
        despawnCheckpoint(cp.id)
      end
      -- provoke check: armed player close to the line
      if active[cp.id] and d < MilCfg.FireIfArmedRadius then
        local _, weapon = GetCurrentPedWeapon(PlayerPedId(), true)
        if weapon ~= `WEAPON_UNARMED` then
          for _, ped in ipairs(active[cp.id]) do
            if DoesEntityExist(ped) and not IsEntityDead(ped) then
              TaskCombatPed(ped, PlayerPedId(), 0, 16)
            end
          end
          lib.notify({ title = 'WEAPON DOWN! OPEN FIRE!', type = 'error' })
        end
      elseif active[cp.id] and d < MilCfg.WarnRadius then
        -- one-shot warning could go here (flag per checkpoint visit)
      end
    end
  end
end)
