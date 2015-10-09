globals = require 'globals'
isLoggedIn = require './isLoggedIn'

trackEligible = ->

  return analytics? and globals.config.logToExternal

# Access control wrapper around segmentio object.
module.exports = exports = (args...) ->

  return  unless trackEligible()

  # send event#action as event for GA
  if args.length > 1
    {action} = args[1]
    args[1].event = args[0]  unless args[1].event

  # if event#action, send that or fallback to event
  event = if action? then action else args[0]
  analytics.track event, args[1]

exports.alias = (args...) ->

  return  unless trackEligible()
  analytics.alias args...

