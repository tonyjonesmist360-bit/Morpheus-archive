fx_version 'cerulean'
game 'gta5'
name 'outbreak_needs'
description 'Hunger, thirst, fatigue, infection, bleeding — Zomboid-style survival stats'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/needs.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/needs.lua' }
dependencies { 'outbreak_core', 'ox_inventory' }
lua54 'yes'
