fx_version 'cerulean'
game 'gta5'
name 'outbreak_mapkey'
description 'Map legend: every Outbreak blip named; the vanilla store/bank/clothing blips gone'
shared_scripts { '@ox_lib/init.lua', '@outbreak_items/shared/loot_config.lua', '@outbreak_down/shared/config.lua', '@outbreak_craft/shared/recipes.lua', 'shared/config.lua' }  -- read-only includes: sites, stations, benches
client_scripts { 'client/mapkey.lua', 'client/places.lua' }
lua54 'yes'
