dateFormat = require 'dateformat'
globals = require 'globals'
objectToString = require './objectToString'
sendDataDogEvent = require 'app/util/sendDataDogEvent'
kd = require 'kd'

module.exports = ->

  globals.__logs ?= []
  global.konsole ?= {}

  _log = (method) ->

    ->
      line = "[#{dateFormat Date.now(), "HH:MM:ss"}][#{method[0]}] "
      for arg in arguments
        if typeof arg is 'object'
          arg = objectToString arg, { maxDepth: 6 }
        line += "#{arg} "

      unless line is globals.__logs.last
        globals.__logs.push line

      return line

  global.onerror = (err, url, line) ->
    (_log 'error') "#{err} at #{url} line #{line}"
    sendDataDogEvent 'ApplicationError', { prefix: 'app-error' }
    return true

  for method in ['trace', 'time', 'timeEnd']
    global[method] = kd.noop

  for method in ['warn', 'log', 'error', 'info', 'debug']
    global.konsole[method] ?= global.console[method]
    global.console[method] = global[method] = _log method

  delete globals.logsEnabled

  return 'Logs are disabled now.'
