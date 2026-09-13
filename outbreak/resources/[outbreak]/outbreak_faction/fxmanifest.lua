fx_version 'cerulean'
game 'gta5'
name 'outbreak_faction'
description 'Police job converted to Military; Raider faction for antagonist players'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/faction.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/faction.lua' }
lua54 'yes'
