fx_version 'cerulean'
game 'gta5'
name 'outbreak_radio'
description 'Radios instead of phones — pma-voice channels, batteries, static events'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/radio.lua', 'client/voice.lua', 'client/fx.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/radio.lua', 'server/range.lua' }
client_scripts { 'client/range.lua' }
ui_page 'html/index.html'
files { 'html/index.html', 'html/sfx/*.wav' }
dependencies { 'pma-voice', 'outbreak_emotes', 'outbreak_core' }
lua54 'yes'
