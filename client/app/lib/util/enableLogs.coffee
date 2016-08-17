dateFormat = require 'dateformat'
globals = require 'globals'
disableLogs = require './disableLogs'

module.exports = enableLogs = (state = yes) ->

  return disableLogs()  unless state
  return if globals.logsEnabled

  if global.konsole?

    global.onerror = null

    globals.__logs?.push \
      "[#{dateFormat Date.now(), "HH:MM:ss"}][!] Logging disabled manually."

    for method in ['warn', 'log', 'error', 'info', 'debug']
      global.console[method] = global.konsole[method]

  globals.logsEnabled = yes

  return 'Logs are enabled now.'
