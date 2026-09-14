fx_version 'cerulean'
game 'gta5'
name 'outbreak_core'
description 'Zombie population, AI, infection on hit'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/zombies.lua', 'client/quietkill.lua' }
server_scripts { 'server/director.lua' }
lua54 'yes'
