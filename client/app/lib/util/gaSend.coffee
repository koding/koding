globals = require 'globals'

module.exports = (args...)->
  return  if not ga? or not globals.config.logToExternal

  lastGAMessage = new Date
  ga "send", args...
