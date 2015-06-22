{argv}    = require 'optimist'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")
Analytics = require('analytics-node')
analytics = new Analytics(KONFIG.segment)

module.exports = class Analytics

  @track = (userId, event, properties={}) ->
    properties = @addDefaults properties
    analytics.track {userId, event, properties}


  @identify = (userId, traits={}) ->
    traits = @addDefaults traits
    analytics.identify {userId, traits}


  @addDefaults = (opts) ->
    opts["env"]      = KONFIG.environment
    opts["hostname"] = KONFIG.publicHostname

    opts
