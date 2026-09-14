fx_version 'cerulean'
game 'gta5'
name 'outbreak_supply'
description 'Settlements: the claimed safehouse as a home. Stockpile read-model over the house stash, NPC residents who eat from it, morale that turns into behaviour, and cooking. Server-authoritative; the client only renders.'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/supply.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/supply.lua' }
dependencies { 'ox_lib', 'oxmysql', 'ox_inventory', 'outbreak_core', 'outbreak_housing', 'outbreak_emotes' }
lua54 'yes'
