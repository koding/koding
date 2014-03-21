KD.troubleshoot = ->
  KD.singleton("troubleshoot").run()

class Troubleshoot extends KDObject

  [PENDING, STARTED] = [1..2]

  constructor: (options = {}) ->
    options.timeout ?= 10000 #overall troubleshoot timeout
    super options

    @items = {}
    @status = PENDING

    @prepareCheckSequence()
    @brokerRecovery = new BrokerRecovery
    @brokerKiteRecovery = new BrokerRecovery type: 'kite'
    @registerItems()
    # when a user stays idle for an hour we forward userIdle event
    @idleUserDetector = new IdleUserDetector threshold: 3600000
    @forwardEvent @idleUserDetector, "userIdle"

  # prepareCheckSequence builds a tree structured health check sequence.
  # With predecessor's successful health check, successors status is checked
  prepareCheckSequence: ->
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

  isSystemOK: ->
    for own name, item of @items
      return no  if item.status is "fail"

    yes

  reset: (event) ->
    @status = PENDING
    KD.utils.killWait @timeout
    @emit event

  isConnectionFailed: ->
    @items["connection"].status is "fail"

  resetAllItems: ->
    for own name, item of @items
      item.reset()

  registerItems:->

    @registerConnections()
    @registerBrokers()

    # register osKite
    vc = KD.singleton "vmController"
    @registerItem "osKite",
      troubleshoot : vc.ping.bind vc
      recover      : vc.ping.bind vc #temp

    # register bongo
    KD.remote.once "modelsReady", =>
      bongoStatus = KD.remote.api.JSystemStatus
      @registerItem "bongo",
        troubleshoot : bongoStatus.healthCheck.bind bongoStatus
        recover      : bongoStatus.healthCheck.bind bongoStatus

    KD.singleton("mainController").on "AccountChanged", =>
      liveUpdateChecker = new LiveUpdateChecker
      @registerItem "liveUpdate",
        troubleshoot: liveUpdateChecker.healthCheck.bind liveUpdateChecker
        recover     : liveUpdateChecker.healthCheck.bind liveUpdateChecker

    @registerItem "version",
      speedCheck   : no
      troubleshoot : checkVersion

    vmChecker = new VMChecker
    @registerItem "vm",
      speedCheck   : no
      troubleshoot : vmChecker.healthCheck.bind vmChecker
      recover      : vmChecker.healthCheck.bind vmChecker

  registerConnections: ->
    #register connection
    externalUrl = "https://s3.amazonaws.com/koding-ping/healthcheck.json"
    item = new ConnectionChecker crossDomain: yes, externalUrl
    @registerItem "connection", troubleshoot: item.ping.bind item

    # register webserver status
    webserverStatus = new ConnectionChecker({}, "#{window.location.origin}/-/healthCheck")
    @registerItem "webServer", troubleshoot: webserverStatus.ping.bind webserverStatus

  registerBrokers: ->
    # register broker
    broker = KD.remote.mq
    @registerItem "broker",
      troubleshoot : broker.ping.bind broker
      recover      : @brokerRecovery.recover.bind @brokerRecovery

    # register kite
    brokerKite = KD.kite.mq
    @registerItem "brokerKite",
      troubleshoot : brokerKite.ping.bind brokerKite
      recover      : @brokerKiteRecovery.recover.bind @brokerKiteRecovery

  registerItem : (name, options) ->
    options.name = name
    @items[name] = new HealthChecker options


  checkVersion = (callback) ->
    $.ajax
      url     : "#{window.location.origin}/-/version"
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
      result = "#{result} #{premium}#{name}"  if item.status is "fail"
    result


  healthChecker: (root) ->
    for own name, children of root
      item = @items[name]
      do (name, children, item) =>
        return warn "#{name} is not registered for health checking"  unless item

        item.once "healthCheckCompleted", =>
          @waitingResponse -= 1
          # no need to wait for child services
          @waitingResponse -= @getSuccessorCount children  if item.status is "fail"
          @healthChecker children  if children and item.status in ["success", "slow"]
          @reset "troubleshootCompleted"  unless @waitingResponse

        item.run()

  getSuccessorCount: (root) ->
    count = 0
    for own name, child of root
      count += @getSuccessorCount child
      count += 1

    count

  recover: ->
    waitingRecovery = 0
    for own name, item of @items
      do (item) =>
        item.once "recoveryCompleted", =>
          waitingRecovery--
          @reset "recoveryCompleted"  unless waitingRecovery

        if item.status is "fail" and item.canBeRecovered()
          waitingRecovery++
          item.recover()

    waitingRecovery

  canBeRecovered: ->
    for own name, item of @items
      return yes  if item.status is "fail" and item.canBeRecovered()
    no

  run: ->
    return  warn "there is an ongoing troubleshooting"  if @status is STARTED
    @timeout = KD.utils.wait @getOptions().timeout, => @status = PENDING

    @resetAllItems()

    @status = STARTED
    @result = {}
    @waitingResponse = Object.keys(@items).length

    @healthChecker @checkSequence
