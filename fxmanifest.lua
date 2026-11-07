fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'muet_voice'
description 'Voix par synthèse vocale pour joueurs muets'
version '1.0.0'

ui_page 'html/index.html'
files {
    'html/index.html',
    'html/vercel.json'
}

shared_script 'config.lua'
client_script 'client.lua'
server_script 'server.lua'
