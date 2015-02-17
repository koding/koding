globals = require 'globals'

module.exports = ->
  localStorage.isPubnubEnabled is "true" or globals.config.pubnub.enabled
