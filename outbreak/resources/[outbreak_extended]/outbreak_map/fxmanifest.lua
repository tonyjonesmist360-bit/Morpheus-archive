fx_version 'cerulean'
game 'gta5'
name 'outbreak_map'
description 'World dressing (wrecks, sandbags, blocked roads), ambient scuff removal, and /scuff reporting'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/map.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/scuff.lua' }
lua54 'yes'
