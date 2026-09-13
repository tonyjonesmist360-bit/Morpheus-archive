fx_version 'cerulean'
game 'gta5'
name 'outbreak_skills'
description 'Zomboid-style skills that grow with use; traits from outbreak_identity shape them'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/skills.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/skills.lua' }
dependencies { 'outbreak_core', 'outbreak_identity' }
lua54 'yes'
