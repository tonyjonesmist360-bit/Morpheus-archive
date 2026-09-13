fx_version 'cerulean'
game 'gta5'
name 'outbreak_status'
description 'One key, the whole picture: condition, what you are carrying, skills, world. Reads existing client exports only - no new server surface.'
shared_scripts { '@ox_lib/init.lua' }
client_scripts { 'client/status.lua' }
ui_page 'html/index.html'
files { 'html/index.html' }
dependencies { 'ox_lib', 'outbreak_needs', 'outbreak_skills' }
lua54 'yes'
