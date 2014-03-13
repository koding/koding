class HealthChecker extends KDObject
  [NOTSTARTED, WAITING, SUCCESS, FAILED] = [1..4]

  constructor: (options={}, @cb) ->
    super options

    @identifier = options.identifier or Date.now()
    @status = NOTSTARTED

  run: ->
    @status = WAITING
    @startTime = Date.now()
    @setPingTimeout()
    @cb @finish.bind(this)

  setPingTimeout: ->
    @pingTimeout = setTimeout =>
      @status = FAILED
      @emit "failed"
    , 5000

  finish: (data)->
    @status = SUCCESS
    @finishTime = Date.now()
    clearTimeout @pingTimeout
    @pingTimeout = null
    @emit "finish"

  getResponseTime: ->
    status = switch @status
      when NOTSTARTED
        "not started"
      when FAILED
        "failed"
      when SUCCESS
        @finishTime - @startTime
      when WAITING
        "waiting"

    return status