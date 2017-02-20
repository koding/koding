KONFIG._CLIENTVERSION ?= KONFIG.version


module.exports = readClientVersion = (callback = (->)) ->

  fs   = require 'fs'
  path = require 'path'

  kallback = (version) ->
    KONFIG._CLIENTVERSION = version
    callback version

  version = try
    fs.readFileSync(
      (path.join process.env.KONFIG_PROJECTROOT, './CLIENTVERSION'), 'utf-8'
    ).trim()
  catch
    KONFIG.version


  if KONFIG.environment in [ 'sandbox', 'production' ]

    bucketUrl  = 'https://s3.amazonaws.com/koding-assets'
    versionUrl = "#{bucketUrl}/a/p/p/#{KONFIG.environment}-client.version"

    request = require 'request'
    request versionUrl, (error, response, body) ->
      if not error and response.statusCode is 200
        kallback body.trim()
      else
        kallback version

  else

    kallback version


process.on 'SIGPIPE', ->

  currentVersion = KONFIG._CLIENTVERSION
  readClientVersion (version) ->
    if version isnt currentVersion
      console.log 'Client revision changed to', version
