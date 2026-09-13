fx_version 'cerulean'
game 'gta5'
name 'outbreak_dm'
description 'Director menu: live events, spawns, story tools, scene presets. Ace-gated (outbreak.dm), server-validated, audit-logged.'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/dm.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/dm.lua' }
dependencies { 'ox_lib', 'oxmysql', 'outbreak_core' }
lua54 'yes'
