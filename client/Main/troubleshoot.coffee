KD.troubleshoot = ->
  KD.singleton("troubleshoot").run()

class Troubleshoot extends KDObject

  [PENDING, STARTED] = [1..2]

  constructor: (options = {}) ->
    @items = {}
    @status = PENDING
    options.timeout ?= 20000

    super options
    @init()
    @registerItems()


  init: ->
    setInterval =>
      run.call this
    , @getOptions().timeout

    # after a timeout period
    @timeout = setTimeout =>
      @status = PENDING
      decorateResult.call this
      , 10000


  registerItems:->
    #register connection
    externalUrl = "https://s3.amazonaws.com/koding-ping/ping.json"
    @registerItem "connection", item = new ConnectionChecker(crossDomain: yes, externalUrl), item.ping
    # register webserver status
    webserverStatus = new ConnectionChecker({}, window.location.origin + "/healthCheck")
    @registerItem "webServer", webserverStatus, webserverStatus.ping
    # register bongo
    KD.remote.once "modelsReady", =>
      bongoStatus = KD.remote.api.JSystemStatus
      @registerItem "bongo", bongoStatus, bongoStatus.healthCheck
    # register kite
    @registerItem "kiteBroker", KD.kite.mq, KD.kite.mq.ping
    @vc = KD.singleton "vmController"
    @registerItem "broker", KD.remote.mq
    @registerItem "osKite", @vc

    @on "pingCompleted", =>
      @timeout = null
      @status = PENDING
      decorateResult.call this


  decorateResult = ->
    response = {}
    for own name, item of @result
      {status, responseTime} = item
      response[name] = {status, responseTime}
    console.log 'response', response


  # registerItem registers ServicePinger objects: "broker", item
  registerItem : (name, item) ->
    # we can register item after troubleshoot is completed
    unless @status is STARTED
      @items[name] = new ServicePinger item


  getItems: ->
    @items


  run = ->
    @status = STARTED
    @result = {}
    waitingResponse = Object.keys(@items).length
    for own name, item of @items
      item.run()
      @result[name] = new TroubleshootResult name, item
      @result[name].on "completed", =>
        waitingResponse -= 1
        # we can also send each response to user
        unless waitingResponse
          @emit "pingCompleted"


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


class ConnectionChecker extends KDObject

  constructor: (options, data)->
    super options, data
    @url = data

  ping: (callback) ->
    {crossDomain} = @getOptions()
    # if there are more than two consecutive crossDomain calls
    # this window.jsonp will be overriden and it will cause errors - CtF
    window.jsonp = callback  if crossDomain

    $.ajax
      url     : @url
      success : -> callback()
      timeout : 5000
      dataType: "jsonp"
      error   : ->


class HealthCheck extends KDObject
  [NOTSTARTED, WAITING, SUCCESS, FAILED] = [1..4]

  constructor: (options={}, @item, @cb) ->
    super options

    @identifier = options.identifier or Date.now()
    @status = NOTSTARTED

  run: ->
    @status = WAITING
    @startTime = Date.now()
    @setPingTimeout()
    @cb.call @item, @finish.bind(this)

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
