KD.troubleshoot = ->
  KD.singleton("troubleshoot").run()

class Troubleshoot extends KDObject

  [PENDING, STARTED] = [1..2]

  constructor: (options = {}) ->
    @items = {}
    @status = PENDING
    options.timeout ?= 10000

    super options
    @registerItems()

    @on "pingCompleted", =>
      @status = PENDING
      clearTimeout @timeout
      @timeout = null
      decorateResult.call this


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
    # register broker
    @registerItem "broker", KD.remote.mq, KD.remote.mq.ping
    # register kite
    @registerItem "kiteBroker", KD.kite.mq, KD.kite.mq.ping
    # register osKite
    @vc = KD.singleton "vmController"
    @registerItem "osKite", @vc, @vc.ping

  decorateResult = ->
    response = {}
    for own name, item of @result
      {status, responseTime} = item
      response[name] = {status, responseTime}
    @emit "troubleshootCompleted", response


  # registerItem registers HealthChecker objects: "broker", item
  registerItem : (name, item, cb) ->
    @items[name] = new HealthChecker {}, item, cb


  run: ->
    return  warn "there is an ongoing troubleshooting"  if @status is STARTED
    @timeout = setTimeout =>
      @status = PENDING
      decorateResult.call this
    , @getOptions().timeout

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
