remote  = require('app/remote').getInstance()
globals = require 'globals'

isLoggedIn = require './isLoggedIn'

trackEligible = ->

  return analytics? and globals.config.logToExternal

# Access control wrapper around segmentio object.
module.exports = exports = (action, properties) ->

  return  unless trackEligible()

  remote.api.Tracker.track action, properties
