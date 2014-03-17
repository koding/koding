class LiveUpdateChecker extends KDObject

  constructor: (options, data) ->
    super options, data
    @cb = ->
    KD.whoami().on "healthCheck", =>
      @cb()


  healthCheck: (callback) ->
    @cb = callback
    KD.remote.api.JNewStatusUpdate.healthCheck callback