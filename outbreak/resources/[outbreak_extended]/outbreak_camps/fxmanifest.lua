fx_version 'cerulean'
game 'gta5'
name 'outbreak_camps'
description 'Raider camps (static loot-fortresses) and military convoys rolling between checkpoints'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/camps.lua', 'client/convoy.lua' }
server_scripts { 'server/camps.lua' }
lua54 'yes'
