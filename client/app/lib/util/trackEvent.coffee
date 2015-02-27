kd = require 'kd'
globals = require 'globals'
whoami = require './whoami'
isLoggedIn = require './isLoggedIn'
gaEvent = require './gaEvent'

# Access control wrapper around segmentio object.
module.exports = exports = (args...) ->
  return  unless analytics? and globals.config.logToExternal

  if args.length < 2
    args.push {}

  me = whoami()
  return  unless me.profile

  gaEvent args[0]

  args[1]["username"] = me.profile.nickname

  analytics.track args...

exports.alias = (args...)->
  return  unless analytics? and globals.config.logToExternal
  analytics.alias args...
