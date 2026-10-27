fx_version 'cerulean'
game 'gta5'

name 'sxIllegals'
description 'Illegal groups, territories and laboratories'
author 'sxIllegals'
version '1.0.0'

lua54 'yes'

dependencies {
    'es_extended',
    'oxmysql',
}

shared_scripts {
    '@es_extended/imports.lua',
    'core/sh_translation.lua',
    'translations/*.lua',
    'core/sh_logger.lua',
    'core/sh_modules.lua',
    'core/sh_class.lua',
    'core/sh_callback.lua',
    'core/sh_utils.lua',
    'core/sh_generate.lua',
    'shared/*.lua',
    'modules/**/sh_*.lua',
}

client_scripts {
    'core/cl_hook.lua',
    'core/cl_entities.lua',
    'core/cl_base.lua',
    'modules/**/cl_*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/**/sv_*.lua',
}

ui_page 'web/dist/index.html'

files {
    'core/MINIMAP_LOADER.gfx',
    'web/dist/index.html',
    'web/dist/**/*'
}
