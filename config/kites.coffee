fs = require 'fs'
{ join: joinPath } = require 'path'

versionFile = (kiteName) ->
  (fs.readFileSync (joinPath __dirname, "../versions/#{ kiteName }.version"), 'utf-8').trim()

module.exports =
  disableWebSocketByDefault: yes
  stack:
    force: no
    newKites: yes
  kontrol:
    username: 'koding'
  os:
    version: versionFile 'os'
  terminal:
    version: versionFile 'terminal'