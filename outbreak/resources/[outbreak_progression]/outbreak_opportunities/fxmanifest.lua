fx_version 'cerulean'
game 'gta5'
name 'outbreak_opportunities'
description 'Objective layer: registry + state machine for opportunity chains; camp world entity'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/registry.lua', 'server/entities/camps.lua',
  'server/chains/camp_defense.lua', 'server/chains/armored_bus.lua', 'server/chains/weapons_cache.lua', 'server/chains/repeater.lua', 'server/chains/island.lua' }
client_scripts { 'client/opportunities.lua', 'client/chains/camp_defense.lua', 'client/chains/armored_bus.lua', 'client/chains/repeater.lua', 'client/chains/weapons_cache.lua', 'client/chains/island.lua' }
dependencies { 'ox_lib', 'oxmysql', 'outbreak_core', 'outbreak_intel' }
lua54 'yes'
