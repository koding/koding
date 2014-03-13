class TroubleshootResult extends KDObject

  constructor: (name, healthChecker) ->
    @name    = name
    @healthChecker  = healthChecker
    @status  = "failed"
    super

    healthChecker.once "finish", =>
      @status = "ok"
      @responseTime = @getResponseTime()
      @emit "completed"

    healthChecker.once "failed", =>
      @status = "down"
      @emit "completed"

  getResponseTime: ->
    @healthChecker.getResponseTime()