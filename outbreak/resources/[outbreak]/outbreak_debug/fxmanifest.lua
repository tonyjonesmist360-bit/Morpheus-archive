fx_version 'cerulean'
game 'gta5'
name 'outbreak_debug'
description 'Test commands + debug menu. Only active when convar ob_debug=1. Never ensure on a public server.'
shared_scripts { '@ox_lib/init.lua', '@outbreak_worlditems/shared/config.lua', '@outbreak_items/shared/loot_config.lua', '@outbreak_emotes/shared/emotes.lua' }
dependencies { 'outbreak_worlditems', 'outbreak_items', 'outbreak_emotes' }
client_scripts { 'client/debug.lua', 'client/shakedown.lua', 'client/hud.lua' }
server_scripts { 'server/debug.lua', 'server/shakedown.lua' }
ui_page 'html/shakedown.html'
files { 'html/shakedown.html' }
lua54 'yes'
