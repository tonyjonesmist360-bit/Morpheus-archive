-- The world's weapon catalog. Anything not listed does not exist in loot (ox_inventory still knows it, we never spawn it).
-- noise: what a shot does to the noise meter (suppressed value if a suppressor is fitted). tier: common | scarce | legendary
-- jamBelow: durability % under which jams start; jamChance at 0 durability (scales linearly up to jamBelow)
WeaponCfg = {
  Weapons = {
    -- melee (ox drains durability per hit; at 0 the weapon is unusable = "broke")
    WEAPON_BAT           = { label = 'Bat',             tier = 'common',    melee = true,  noise = 30 },
    WEAPON_CROWBAR       = { label = 'Crowbar',         tier = 'common',    melee = true,  noise = 32 },
    WEAPON_KNIFE         = { label = 'Knife',           tier = 'common',    melee = true,  noise = 15 },
    WEAPON_MACHETE       = { label = 'Machete',         tier = 'scarce',    melee = true,  noise = 22 },
    WEAPON_HATCHET       = { label = 'Hatchet',         tier = 'scarce',    melee = true,  noise = 28 },
    -- firearms
    WEAPON_PISTOL        = { label = 'Pistol',          tier = 'common',    ammo = 'ammo-9',      noise = 92, suppressed = 45, jamBelow = 30, jamChance = 0.35 },
    WEAPON_REVOLVER      = { label = 'Heavy Revolver',  tier = 'legendary', ammo = 'ammo-44',     noise = 100, jamBelow = 15, jamChance = 0.15, drawback = 'Six rounds. Every one is a dinner bell.' },
    WEAPON_PUMPSHOTGUN   = { label = 'Pump Shotgun',    tier = 'scarce',    ammo = 'ammo-shotgun', noise = 100, jamBelow = 35, jamChance = 0.4 },
    WEAPON_CARBINERIFLE  = { label = 'Carbine',         tier = 'scarce',    ammo = 'ammo-rifle',  noise = 95, suppressed = 50, jamBelow = 30, jamChance = 0.3, military = true },
    WEAPON_SNIPERRIFLE   = { label = 'Marksman Rifle',  tier = 'legendary', ammo = 'ammo-sniper', noise = 100, suppressed = 55, jamBelow = 20, jamChance = 0.2, conceal = false, drawback = 'Heavy. Slow. Everyone within a kilometre knows.' },
    WEAPON_MG            = { label = 'Belt-fed MG',     tier = 'legendary', ammo = 'ammo-rifle',  noise = 100, jamBelow = 50, jamChance = 0.6, conceal = false, heavy = true, drawback = 'Eats a belt in seconds. Jams when dirty. Cannot be hidden.' },
    WEAPON_GRENADELAUNCHER = { label = 'Grenade Launcher', tier = 'legendary', ammo = 'ammo-grenadelauncher', noise = 100, jamBelow = 10, jamChance = 0.1, conceal = false, drawback = 'Rounds are almost extinct.' },
    WEAPON_FLAREGUN      = { label = 'Signal Pistol',   tier = 'scarce',    ammo = 'ammo-flare',  noise = 70, signal = true, drawback = 'Everything for two kilometres sees it. That is the point.' },
  },
  Ammo = { -- weight per round (grams); scarcity is the loot tables' job
    ['ammo-9'] = 12, ['ammo-44'] = 25, ['ammo-shotgun'] = 40, ['ammo-rifle'] = 15, ['ammo-sniper'] = 30, ['ammo-grenadelauncher'] = 400, ['ammo-flare'] = 60,
  },
  Repair = { gun_oil = 25, weapon_kit = 100 },  -- durability restored to the held weapon
  Jam = { clearSeconds = 2.5 },
  LegendaryAttention = { raiderAmbushMult = 2.0 },  -- extended raiders read legendaryCount()
}
