fx_version 'cerulean'
game 'gta5'
name 'outbreak_identity'
description 'Survivor creation: appearance (illenium), callsign, former life, traits, description. /look at people.'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/identity.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/identity.lua' }
dependencies { 'illenium-appearance', 'outbreak_spawn' }
lua54 'yes'
