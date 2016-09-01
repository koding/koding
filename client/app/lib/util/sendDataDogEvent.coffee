remote = require('../remote')
parseLogs = require './parseLogs'
uploadLogs = require './uploadLogs'
globals = require 'globals'

module.exports = sendDataDogEvent = (eventName, options = {}) ->

  options.eventName = eventName
  options.sendLogs ?= yes

  sendEvent = (logs) ->

    options.tags ?= {}
    options.tags.version = globals.config.version

    options.logs = logs
    remote.api.DataDog.sendEvent options

  kdlogs = parseLogs()

  # If there is enough log to send, no more checks required
  # just send them away, first to s3 then datadog
  if kdlogs.length > 100 and options.sendLogs

    uploadLogs (err, publicUrl) ->

      logs = if err? and not publicUrl
      then parseLogs()
      else publicUrl

      sendEvent logs

    , options.prefix

  else

    # Send only events on production
    # and user enabled logs somehow
    sendEvent()  if globals.config.environment is 'production'
