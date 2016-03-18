remote = require('../remote').getInstance()
parseLogs = require './parseLogs'
uploadLogs = require './uploadLogs'
globals = require 'globals'

module.exports = (eventName, options = {}) ->

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

  else

    # Send only events when hostname is koding.com
    # and user enabled logs somehow
    sendEvent()  if global.location.hostname is 'koding.com'
