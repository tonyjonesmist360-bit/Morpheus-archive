fx_version 'cerulean'
game 'gta5'
name 'outbreak_director'
description 'World Director: every 30-60 minutes reads each settlement (stock, residents, morale, defense) and the players, then nudges the world once - a stranger at the door, a rumour on the radio, a probe at the barricade, a word from home. Rides outbreak_core''s scheduler; no loop of its own.'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/director.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/director.lua' }
dependencies { 'ox_lib', 'oxmysql', 'outbreak_core', 'outbreak_housing', 'outbreak_supply' }
lua54 'yes'
