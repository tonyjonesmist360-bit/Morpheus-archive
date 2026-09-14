fx_version 'cerulean'
game 'gta5'
name 'outbreak_ambience'
description 'Atmosphere: wind bed outdoors, distant groans scaled by the dead nearby (synthesized, no assets), night darkening, Discord rich presence. Reads the core tick; no loop of its own beyond audio.'
shared_scripts { 'shared/config.lua' }
client_scripts { 'client/ambience.lua' }
ui_page 'html/index.html'
files { 'html/index.html', 'html/sfx/*.wav' }
dependencies { 'outbreak_core' }
lua54 'yes'
