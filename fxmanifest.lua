fx_version 'cerulean'
game { 'gta5' }
author 'Sinaps'
description 'Script to cover your vehicles'
lua54 'yes'

shared_scripts {
    'shared/**/*.lua',
}

client_script {'client/**/*.lua'}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

escrow_ignore {
    'server/server.lua',
    'shared/config.lua',
    'client/client.lua',
}