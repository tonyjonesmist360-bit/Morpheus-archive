fx_version 'cerulean'
game 'gta5'
name 'outbreak_items'
description 'Zomboid-style items, useables, and searchable loot containers'
shared_scripts { '@ox_lib/init.lua', 'shared/loot_config.lua' }
client_scripts { 'client/loot.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/items.lua', 'server/loot.lua' }
dependencies { 'outbreak_needs', 'outbreak_emotes' }
lua54 'yes'
