fx_version 'cerulean'
game 'gta5'
name 'outbreak_intel'
description 'Knowledge layer: intel records per character, discovery sources, presentation rules, field journal'
shared_scripts { '@ox_lib/init.lua', 'shared/config.lua', 'data/intel.lua' }
client_scripts { 'client/intel.lua', 'client/journal.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/intel.lua', 'server/sources.lua' }
ui_page 'html/journal.html'
files { 'html/journal.html' }
dependencies { 'ox_lib', 'oxmysql', 'outbreak_core' }
lua54 'yes'
