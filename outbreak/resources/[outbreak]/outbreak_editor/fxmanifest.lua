fx_version 'cerulean'
game 'gta5'
name 'outbreak_editor'
description 'The World Editor (F10 -> Editor): place NPCs, make anything interactable, paint zones, edit loot, build missions, export packs. Server-authoritative, no Lua needed.'
shared_scripts { '@ox_lib/init.lua', '@outbreak_items/shared/loot_config.lua', 'shared/config.lua' }
client_scripts { 'client/mode.lua', 'client/world.lua', 'client/ui.lua' }
server_scripts { '@oxmysql/lib/MySQL.lua', 'server/store.lua', 'server/mode.lua', 'server/runner.lua', 'server/missions.lua', 'server/packs.lua' }
ui_page 'html/index.html'
files { 'html/index.html' }
dependencies { 'ox_lib', 'oxmysql', 'ox_target', 'ox_inventory', 'outbreak_core', 'outbreak_dm' }
lua54 'yes'
