class HealthChecker extends KDObject

  constructor: (options={}, @cb) ->
    super options

    @identifier = options.identifier or Date.now()
    @status = "not started"

  run: ->
    @status = "waiting"
    @startTime = Date.now()
    @setPingTimeout()
    @cb @finish.bind(this)

  setPingTimeout: ->
    @pingTimeout = setTimeout =>
      @status = "down"
      @emit "healthCheckCompleted"
    , 5000

  finish: (data)->
    @status = "success"
    @finishTime = Date.now()
    clearTimeout @pingTimeout
    @pingTimeout = null
    @emit "healthCheckCompleted"

  getResponseTime: ->
    if @status is "success" then @finishTime - @startTime else ""