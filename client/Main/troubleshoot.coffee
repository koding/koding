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
    @vc = KD.singleton "vmController"
    @registerItem "bongo", KD.remote
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
        unless waitingResponse
          @emit "pingCompleted"


class TroubleshootResult extends KDObject

  constructor: (name, pinger) ->
    @name    = name
    @pinger  = pinger
    @status  = "failed"
    super

    pinger.once "finish", =>
      @status = "ok"
      @responseTime = @getResponseTime()
      @emit "completed"

    pinger.once "failed", =>
      @status = "failed"
      @emit "completed"

  getResponseTime: ->
    @pinger.getResponseTime()

class ConnectionChecker extends KDObject

  constructor: (options, data)->
    super options, data
    @url = data

  ping: (callback) ->
    KD.connectionPong = callback.bind this
    window.jsonp = -> KD.connectionPong()

    $.ajax
      url     : @url+"?callback" + KD.connectionPong
      timeout : 5000
      dataType: "jsonp"
      error   : ->


class ServicePinger extends KDObject
  [NOTSTARTED, WAITING, SUCCESS, FAILED] = [1..4]

  constructor: (item, options={}) ->
    super options

    @item = item
    @identifier = options.identifier or Date.now()
    @status = NOTSTARTED

  run: ->
    @status = WAITING
    @startTime = Date.now()
    @setPingTimeout()
    # unless @item.ping is typeof "function"
    #   throw new Error "ping is not defined"
    @item.ping(@finish.bind(this))

  setPingTimeout: ->
    @pingTimeout = setTimeout =>
      @status = FAILED
      @emit "failed", @item, @name
    , 5000

  finish: ->
    @status = SUCCESS
    @finishTime = Date.now()
    clearTimeout @pingTimeout
    @pingTimeout = null
    @emit "finish", @item

  getResponseTime: ->
    status = switch @status
      when NOTSTARTED
        "not started"
      when FAILED
        "failed"
      when SUCCESS
        @finishTime - @startTime
      when "WAITING"
        "waiting"

    return status
