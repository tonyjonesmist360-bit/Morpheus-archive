fx_version 'cerulean'
game 'gta5'
name 'outbreak_mechanics'
description 'The Yard: a mechanics faction. Deliver cars for standing (raiders give chase), standing buys free repairs and mods'
shared_scripts { '@ox_lib/init.lua', '@outbreak_faction/shared/config.lua', 'shared/config.lua' }
client_scripts { 'client/yard.lua', 'client/job.lua', 'client/mods.lua' }
server_scripts { 'server/mechanics.lua' }
dependencies { 'ox_lib', 'ox_target', 'outbreak_core', 'outbreak_faction', 'outbreak_vehicles' }
lua54 'yes'
