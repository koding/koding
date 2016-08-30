_       = require 'lodash'
kd      = require 'kd'
remote  = require 'app/remote'
globals = require 'globals'

defaults = require './tracking/defaults'

module.exports = class Tracker

  _.assign this, require('./tracking/trackingtypes')


  @track = (action, properties = {}) ->

    return  unless globals.config.sendEventsToSegment

    @assignDefaultProperties action, properties
    remote.api.Tracker.track action, properties, kd.noop


  @assignDefaultProperties: (action, properties) ->

    _.defaults properties, defaults.properties[action]
