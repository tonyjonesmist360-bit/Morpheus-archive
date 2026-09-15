fx_version 'cerulean'
game 'gta5'
name 'outbreak_group'
description 'Crews: form a group, see each other (names, vitals, blips) and drop shared map pins. Session-only, server-authoritative.'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua' }
client_scripts { 'client/group.lua' }
server_scripts { 'server/group.lua' }
dependencies { 'ox_lib', 'outbreak_core' }
lua54 'yes'
