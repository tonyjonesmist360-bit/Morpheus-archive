fx_version 'cerulean'
game 'gta5'
name 'outbreak_hud'
description 'Minimal survival HUD — vitals strip + Zomboid-style moodles'
shared_scripts { '@outbreak_needs/shared/config.lua' }
client_scripts { 'client/hud.lua' }
dependencies { 'outbreak_needs', 'outbreak_noise' }
ui_page 'html/index.html'
files { 'html/index.html' }
lua54 'yes'
