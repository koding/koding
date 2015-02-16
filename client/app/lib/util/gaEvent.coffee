gaSend = require './gaSend'

module.exports = (args...)->
  gaSend "event", args...
