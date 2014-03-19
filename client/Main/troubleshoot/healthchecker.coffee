class HealthChecker extends KDObject

  constructor: (options={}, @cb) ->
    super options
    options.slownessIndicator ?= 1000
    options.speedCheck        ?= yes
    options.timeout           ?= 5000
    @identifier = options.identifier or Date.now()
    @status = "not started"

  run: ->
    @emit "healthCheckStarted"
    @status = "waiting"
    @startTime = Date.now()
    @setPingTimeout()
    @cb @finish.bind(this)
    return @forceComplete "undefined callback"  unless troubleshoot

  setPingTimeout: ->
    @pingTimeout = setTimeout =>
      @status = "fail"
      @emit "healthCheckCompleted"
    , @getOptions().timeout

  finish: (data)->
    # some services (e.g. kite controller) does return callback with error parameter
    # hence we are having
    unless @status is "fail"
      {slownessIndicator, speedCheck} = @getOptions()
      @finishTime = Date.now()
      @status = if speedCheck and @getResponseTime() > slownessIndicator then "slow" else "success"
      clearTimeout @pingTimeout
      @pingTimeout = null
      @emit "healthCheckCompleted"

  reset: ->
    @status = "waiting"
    @finishTime = null
    @startTime = null

  getResponseTime: ->
    @finishTime - @startTime

  forceComplete: (err) ->
    warn err  if err
    @status = "fail"
    @emit "healthCheckCompleted"
