fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Ghost Developments'
description 'Standalone Parking Meter Robbery'
version '1.1.0'

ox_lib 'yes'

client_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua'
}

dependencies {
    'ox_target',
    'ox_lib',
    'ox_inventory',
    'cd_dispatch'
}