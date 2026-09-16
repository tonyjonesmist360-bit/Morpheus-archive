fx_version 'cerulean'
game 'gta5'
name 'outbreak_log'
description 'Server logging (daily files, /logs query), performance monitor, restart warnings, moderation (mute/kick/ban with audit trail)'
shared_scripts { '@ox_lib/init.lua' }
server_scripts { 'server/log.lua', 'server/perf.lua', 'server/restart.lua', 'server/moderation.lua' }
lua54 'yes'
