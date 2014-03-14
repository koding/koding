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
      @emit "troubleshootCompleted"


  registerItems:->
    #register connection
    externalUrl = "https://s3.amazonaws.com/koding-ping/ping.json"
    item = new ConnectionChecker crossDomain: yes, externalUrl
    @registerItem "connection", item.ping.bind item
    # register webserver status
    webserverStatus = new ConnectionChecker({}, window.location.origin + "/healthCheck")
    @registerItem "webServer", webserverStatus.ping.bind webserverStatus
    # register broker
    @registerItem "broker", KD.remote.mq.ping.bind KD.remote.mq
    # register kite
    @registerItem "kiteBroker", KD.kite.mq.ping.bind KD.kite.mq
    # register osKite
    @vc = KD.singleton "vmController"
    @registerItem "osKite", @vc.ping.bind @vc
    # register bongo
    KD.remote.once "modelsReady", =>
      bongoStatus = KD.remote.api.JSystemStatus
      @registerItem "bongo", bongoStatus.healthCheck.bind bongoStatus



  # registerItem registers HealthChecker objects: "broker", item
  registerItem : (name, item, cb) ->
    @items[name] = new HealthChecker {}, item, cb

  getItems: ->
    @items

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
      item.on "healthCheckCompleted", (item) =>
        waitingResponse -= 1
        unless waitingResponse
          @emit "pingCompleted"
