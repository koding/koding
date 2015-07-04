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

    # force flush so identify call doesn't sit in queue, while events
    # from Go/other systems are being sent
    analytics.flush (err, batch)-> console.error err  if err


  @identifyAndTrack = (userId, event, eventProperties = {}) ->
    @identify userId
    @track userId, event, eventProperties


  @addDefaults = (opts) ->
    opts["env"]      = KONFIG.environment
    opts["hostname"] = KONFIG.hostname

    opts

