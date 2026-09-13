fx_version 'cerulean'
game 'gta5'
name 'outbreak_down'
description 'Two-stage downed system: unconscious (melee) vs incapacitated (lethal)'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/down.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/down.lua' }
dependencies { 'outbreak_needs', 'outbreak_emotes', 'outbreak_housing' }
ui_page 'html/down.html'
files { 'html/down.html' }
lua54 'yes'
