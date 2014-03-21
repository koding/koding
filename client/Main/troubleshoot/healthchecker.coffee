class HealthChecker extends KDObject

  constructor: (options = {}) ->
    super options

    options.slownessIndicator ?= 1000
    options.speedCheck        ?= yes
    options.timeout           ?= 5000
    @identifier = options.identifier or Date.now()
    @status = "not started"
    @name = options.name

  run: ->
    @emit "healthCheckStarted"

    {troubleshoot} = @getOptions()
    return @forceComplete "undefined callback"  unless troubleshoot
    @completeEvent = "healthCheckCompleted"
    @startCheck()
    troubleshoot @finish.bind(this)

  setPingTimeout: ->
    @pingTimeout = KD.utils.wait @getOptions().timeout, =>
      @status = "fail"
      @emit @completeEvent

  finish: (data) ->
    # some services (e.g. kite controller) does return callback with error parameter
    # hence we are having
    unless @status is "fail"
      {slownessIndicator, speedCheck} = @getOptions()
      @finishTime = Date.now()
      @status = if speedCheck and @getResponseTime() > slownessIndicator then "slow" else "success"

      @status = data.status  if data?.status #set custom status
      KD.utils.killWait @pingTimeout
      @emit @completeEvent

  startCheck: ->
    @status = "waiting"
    @startTime = Date.now()
    @setPingTimeout @completeEvent

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

  recover: ->
    @completeEvent = "recoveryCompleted"
    @startCheck()
    @emit "recoveryStarted"
    {recover} = @getOptions()
    recover @finish.bind(this)

  canBeRecovered: ->
    @getOptions().recover?

