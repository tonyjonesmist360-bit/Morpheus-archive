fx_version 'cerulean'
game 'gta5'
name 'outbreak_weapons'
description 'Weapon catalog + rules on top of ox_inventory durability: per-weapon noise, jams, repair, legendary drawbacks'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/weapons.lua' }
server_scripts { 'server/weapons.lua' }
dependencies { 'ox_lib', 'ox_inventory', 'outbreak_core', 'outbreak_noise', 'outbreak_emotes' }
lua54 'yes'
