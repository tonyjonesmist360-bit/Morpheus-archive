fx_version 'cerulean'
game 'gta5'
name 'outbreak_housing'
description 'Claimable safehouses, barricades, sometimes-occupied interiors'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/housing.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/housing.lua' }
dependencies { 'outbreak_items', 'outbreak_minigames', 'outbreak_emotes' }
lua54 'yes'
