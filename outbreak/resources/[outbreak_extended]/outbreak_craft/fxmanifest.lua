fx_version 'cerulean'
game 'gta5'
name 'outbreak_craft'
description 'Field crafting — tear, splice, improvise'
shared_scripts { '@ox_lib/init.lua', 'shared/recipes.lua' }
client_scripts { 'client/craft.lua' }
dependencies { 'ox_lib', 'ox_target', 'ox_inventory' }
server_scripts { 'server/craft.lua' }
lua54 'yes'
