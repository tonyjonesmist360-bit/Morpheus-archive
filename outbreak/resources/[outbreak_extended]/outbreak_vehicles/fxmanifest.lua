fx_version 'cerulean'
game 'gta5'
name 'outbreak_vehicles'
description 'v2 — SERVER-AUTHORITATIVE vehicle state: fuel, battery, ignition, locks, keys, parts, persistence of claimed vehicles'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/vehicles.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/state.lua', 'server/actions.lua' }
dependencies { 'ox_lib', 'oxmysql', 'ox_inventory', 'ox_target', 'outbreak_core', 'outbreak_minigames', 'outbreak_emotes' }
lua54 'yes'
