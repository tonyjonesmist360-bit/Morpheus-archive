fx_version 'cerulean'
game 'gta5'
name 'outbreak_spawn'
description 'Apocalypse spawn: wake up somewhere with a starter kit. No apartments, no money.'
shared_scripts { '@ox_lib/init.lua', '@outbreak_housing/shared/config.lua', 'shared/config.lua' }  -- housing doors for the first-ten-minutes guide (read-only include, same pattern as outbreak_director)
client_scripts { 'client/spawn.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/spawn.lua' }
dependencies { 'outbreak_needs', 'outbreak_radio', 'outbreak_world' }
lua54 'yes'
