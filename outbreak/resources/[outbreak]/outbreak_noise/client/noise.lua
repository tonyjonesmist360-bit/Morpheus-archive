-- outbreak_noise/client/noise.lua
-- One number, 0-100: how loud you are right now. Zombie senses scale off it.
local noise = 0.0
local spike = 0.0

NoiseCfg = {
  Crouch = 4, Walk = 14, Run = 28, Sprint = 42,
  VehicleBase = 25, VehicleMax = 65,     -- scales with speed
  Horn = 80,
  GunshotSuppressed = 45, Gunshot = 92,
  Melee = 30,
  Decay = 22,                            -- spike fade per second
}

-- External spikes (prying doors, breaking glass, future scripts)
AddEventHandler('outbreak:noise:spike', function(v)
  spike = math.max(spike, math.min(100, v))
end)

-- Subscribes to the core tick bus. No loop of its own.
AddEventHandler('outbreak:tick', function(t)
  local base
  if t.veh ~= 0 and t.engineOn then
    base = NoiseCfg.VehicleBase + math.min(1.0, t.speedKmh / 120.0) * (NoiseCfg.VehicleMax - NoiseCfg.VehicleBase)
    local vs = Entity(t.veh).state.veh; if vs and vs.noise then base = math.min(100, base * vs.noise) end
    if IsControlPressed(0, 86) then spike = math.max(spike, NoiseCfg.Horn) end
  elseif t.sprinting then base = NoiseCfg.Sprint
  elseif t.running then base = NoiseCfg.Run
  elseif t.stealth then base = NoiseCfg.Crouch
  elseif t.walking then base = NoiseCfg.Walk
  else base = 2 end
  if t.shooting then
    local sup = IsPedCurrentWeaponSilenced(t.ped)
    local v = nil
    pcall(function() local _, h = GetCurrentPedWeapon(t.ped, true); v = exports.outbreak_weapons:noiseOf(h, sup) end)
    spike = math.max(spike, v or (sup and NoiseCfg.GunshotSuppressed or NoiseCfg.Gunshot))
  end
  if t.melee then spike = math.max(spike, NoiseCfg.Melee) end
  spike = math.max(0, spike - NoiseCfg.Decay * 0.5)
  local footMult = 1.0
  pcall(function()
    footMult = exports.outbreak_skills:effects('stealth').noiseMult
    if exports.outbreak_skills:hasTrait('graceful') then footMult = footMult * 0.7 end
    if exports.outbreak_skills:hasTrait('clumsy') then footMult = footMult * 1.3 end
  end)
  noise = math.max(base * footMult, spike)
  TriggerEvent('outbreak:hud:noise', noise)
end)

exports('getNoise', function() return noise end)
