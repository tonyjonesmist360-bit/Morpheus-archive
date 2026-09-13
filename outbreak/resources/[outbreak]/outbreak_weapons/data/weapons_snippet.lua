-- MERGE INTO ox_inventory/data/weapons.lua (Weapons table) and items.lua (repair items below).
-- ox_inventory already ships most of these weapons; the point is durability + the ammo names we use.
-- Weapons: set durability so a magazine costs condition. Melee: 'durability = 0.15' per hit.
-- ['WEAPON_PISTOL'] = { label = 'Pistol', weight = 1100, durability = 0.05, ammoname = 'ammo-9' },
-- ['WEAPON_REVOLVER'] = { label = 'Heavy Revolver', weight = 1500, durability = 0.08, ammoname = 'ammo-44' },
-- ['WEAPON_PUMPSHOTGUN'] = { label = 'Pump Shotgun', weight = 3400, durability = 0.06, ammoname = 'ammo-shotgun' },
-- ['WEAPON_CARBINERIFLE'] = { label = 'Carbine', weight = 3200, durability = 0.04, ammoname = 'ammo-rifle' },
-- ['WEAPON_SNIPERRIFLE'] = { label = 'Marksman Rifle', weight = 6500, durability = 0.06, ammoname = 'ammo-sniper' },
-- ['WEAPON_MG'] = { label = 'Belt-fed MG', weight = 10000, durability = 0.03, ammoname = 'ammo-rifle' },
-- ['WEAPON_GRENADELAUNCHER'] = { label = 'Grenade Launcher', weight = 6000, durability = 0.1, ammoname = 'ammo-grenadelauncher' },
-- ['WEAPON_FLAREGUN'] = { label = 'Signal Pistol', weight = 700, durability = 0.1, ammoname = 'ammo-flare' },
-- ['WEAPON_BAT'] / ['WEAPON_CROWBAR'] / ['WEAPON_KNIFE'] / ['WEAPON_MACHETE'] / ['WEAPON_HATCHET']: durability = 0.15
-- Ammo (ox Ammo table): 'ammo-44' = { label = '.44 Rounds', weight = 25 }, 'ammo-sniper' = { label = 'Long Rounds', weight = 30 }, 'ammo-flare' = { label = 'Flares', weight = 60 } (the rest exist already)

-- ITEMS (paste into items.lua):
['gun_oil']          = { label = 'Gun Oil',            weight = 200,  description = 'Cleans a jam-prone action. +25 condition.' },
['weapon_kit']       = { label = 'Armorer\'s Kit',     weight = 1800, description = 'Springs, brushes, a pin punch. Full rebuild.' },
['dog_tags']         = { label = 'Dog Tags',           weight = 20,   description = 'A name and a number. Someone should know.' },
