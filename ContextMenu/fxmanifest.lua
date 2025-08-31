fx_version 'cerulean'
game 'gta5'

author 'Sicko.'
description 'Context Menu optimisé pour ESX Legacy'
version '2.0.0'

shared_script '@es_extended/imports.lua'

client_scripts {
    'screenToWorld.lua',

    'Drawables/Color.lua',
    'Drawables/Rect.lua',
    'Drawables/Text.lua',
    'Drawables/Sprite.lua',

    'Menu/Item.lua',
    'Menu/CheckboxItem.lua',
    'Menu/SubmenuItem.lua',
    'Menu/Separator.lua',
    'Menu/Border.lua',
    'Menu/Menu.lua',
    'Menu/MenuPool.lua',
    
    'menu.lua',
    'client_events.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory'
}

lua54 'yes'