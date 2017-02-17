module.exports = readClientVersion = ->

  fs   = require 'fs'
  path = require 'path'

  version = try
    fs.readFileSync(
      (path.join process.env.KONFIG_PROJECTROOT, './CLIENTVERSION'), 'utf-8'
    ).trim()
  catch
    KONFIG.version

  KONFIG._CLIENTVERSION = version

process.on 'SIGPIPE', ->
  currentVersion = KONFIG._CLIENTVERSION
  if (newVersion = readClientVersion()) isnt currentVersion
    console.log 'Client revision changed to', newVersion
