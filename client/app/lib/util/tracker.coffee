kd      = require 'kd'
remote  = require('app/remote').getInstance()
globals = require 'globals'

module.exports = class Tracker

  @track = (action, properties) ->

    return  unless globals.config.logToExternal

    remote.api.Tracker.track action, properties, kd.noop
