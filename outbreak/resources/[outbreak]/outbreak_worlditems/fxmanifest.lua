fx_version 'cerulean'
game 'gta5'
name 'outbreak_worlditems'
description 'A mutable world: place any item as a prop, take curated map props, placeable storage + notes, and entropy (NPCs tidy, scavengers replace, raiders break in)'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
-- when [outbreak_progression] is enabled, add '@outbreak_opportunities/server/entities/camps.lua' is NOT possible (server file); entropy reads exports instead
client_scripts { 'client/place.lua', 'client/take.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/worlditems.lua', 'server/entropy.lua' }
dependencies { 'ox_lib', 'oxmysql', 'ox_inventory', 'ox_target', 'outbreak_core', 'outbreak_emotes' }
lua54 'yes'
