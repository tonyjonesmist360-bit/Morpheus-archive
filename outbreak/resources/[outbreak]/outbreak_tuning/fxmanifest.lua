fx_version 'cerulean'
game 'gta5'
name 'outbreak_tuning'
description 'Every magic number in one place (tuning.json), hot-reloadable: ob_tune set <key> <value> takes effect next tick, no restart'
shared_scripts { '@ox_lib/init.lua', 'shared/defaults.lua' }
server_scripts { 'server/tuning.lua' }
lua54 'yes'
