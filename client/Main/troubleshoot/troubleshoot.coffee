KD.troubleshoot = ->
  KD.singleton("troubleshoot").run()

class Troubleshoot extends KDObject

  [PENDING, STARTED] = [1..2]

  constructor: (options = {}) ->
    @items = {}
    @status = PENDING
    options.timeout ?= 10000

    super options

    # this is a tree structured health check sequence.
    # health check of leaves happens with its successor root
    @checkSequence =
      connection       :
        webServer      :
          version      : 0
        brokerKite     :
          osKite       :
            vm         : 0
        bongo          :
          broker       :
            liveUpdate : 0

    @registerItems()

  isSystemOK: ->
    for own name, item of @items
      return no  if item.status is "down"

    yes

  reset: ->
    @status = PENDING
    clearTimeout @timeout
    @timeout = null
    @emit "troubleshootCompleted"

  isConnectionDown: ->
    @items["connection"].status is "down"

  resetAllItems: ->
    for own name, item of @items
      item.reset()

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
    @registerItem "brokerKite", KD.kite.mq.ping.bind KD.kite.mq
    # register osKite
    @vc = KD.singleton "vmController"
    @registerItem "osKite", @vc.ping.bind @vc
    # register bongo
    KD.remote.once "modelsReady", =>
      bongoStatus = KD.remote.api.JSystemStatus
      @registerItem "bongo", bongoStatus.healthCheck.bind bongoStatus

    @registerItem "version", speedCheck: no, checkVersion

    @registerItem "vm", timeout: 10000, speedCheck: no, checkVm

  registerItem : (name, options, cb) ->
    cb = options  unless cb
    @items[name] = new HealthChecker options, cb


  getItems: ->
    @items


  checkVm = (callback) ->
    {vmController} = KD.singletons
    # probably we will need to check all vms
    vmController.once "vm.state.info", ({alias, state}) =>
      @status = "fail"  if state.state isnt "RUNNING"
      callback null


  checkVersion = (callback) ->
    $.ajax
      url     : window.location.origin + "/getVersion"
      success : (data) =>
        @status = "fail"  unless data.version is KD.config.version
        callback null
      timeout : 5000
      dataType: "jsonp"
      error   : =>
        @status = "fail"
        callback null


  getFailureFeedback: ->
    result = ""
    for own name, item of @items
      premium = if name in ["broker", "brokerKite"] and KD.config.usePremiumBroker then "premium" else ""
      result = "#{result} #{premium}#{name}"  if item.status is "down"
    result


  healthChecker: (root) ->
    for own name, children of root
      item = @items[name]
      do (name, children, item) =>
        return warn "#{name} is not registered for health checking"  unless item

        item.once "healthCheckCompleted", =>
          @waitingResponse -= 1
          @healthChecker children  if children and item.status is "success"
          @reset()  unless @waitingResponse

        item.run()

  run: ->
    return  warn "there is an ongoing troubleshooting"  if @status is STARTED
    @timeout = setTimeout =>
      @status = PENDING
    , @getOptions().timeout

    @resetAllItems()

    @status = STARTED
    @result = {}
    @waitingResponse = Object.keys(@items).length

    @healthChecker @checkSequence
