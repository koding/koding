KD.extend troubleshoot: -> KD.singleton("troubleshoot").run()

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
    @idleUserDetector = new IdleUserDetector threshold: KD.config.troubleshoot.idleTime
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
            terminal   : 0
        bongo          :
          broker       :
            liveUpdate : 0
        newKite        : 0

  isSystemOK: ->
    for own name, item of @items
      return no  if item.status is "fail"

    return yes

  reset: (event) ->
    @status = PENDING
    KD.utils.killWait @timeout
    @emit event

  resetAllItems: ->
    for own name, item of @items
      item.reset()

  registerItems:->

    @registerConnections()
    @registerBrokers()

    if localStorage.useNewKites is '1'
      @registerItem "newKite",
        troubleshoot: (callback) ->
          KD.singletons.kontrol.fetchKite({ query: { name: 'kontrol' }})
          .then(callback)
          .catch (err) ->
            warn err
        recover: ->
          ErrorLog.create "Troubleshoot toggled kite stack"
          KD.toggleKiteStack()

    # register osKite
    vc = KD.singleton "vmController"
    @registerItem "osKite",
      troubleshoot : vc.bound 'ping'
      recover      : vc.bound 'ping'

    # register bongo
    KD.remote.once "modelsReady", =>
      bongoStatus = KD.remote.api.JSystemStatus
      @registerItem "bongo",
        troubleshoot : bongoStatus.healthCheck.bind bongoStatus
        recover      : bongoStatus.healthCheck.bind bongoStatus

    KD.singleton("mainController").on "AccountChanged", =>
      liveUpdateChecker = new LiveUpdateChecker
      @registerItem "liveUpdate",
        troubleshoot: liveUpdateChecker.bound 'healthCheck'
        recover     : liveUpdateChecker.bound 'healthCheck'

    @registerItem "version",
      speedCheck   : no
      troubleshoot : checkVersion.bind this

    vmChecker = new VMChecker
    @registerItem "vm",
      speedCheck   : no
      troubleshoot : vmChecker.bound 'healthCheck'

    @registerItem "terminal",
      troubleshoot : vmChecker.bound 'terminalHealthCheck'

  registerConnections: ->
    #register connection
    {externalUrl} = KD.config.troubleshoot
    item = new ConnectionChecker crossDomain: yes, externalUrl
    @registerItem "connection", speedCheck: no, troubleshoot: item.bound 'ping'

    # register webserver status
    webserverStatus = new ConnectionChecker({}, "#{window.location.origin}/-/healthCheck")
    @registerItem "webServer", troubleshoot: webserverStatus.bound 'ping'

  registerBrokers: ->
    # register broker
    broker = KD.remote.mq
    @registerItem "broker",
      troubleshoot : broker.bound 'ping'
      recover      : @brokerRecovery.bound 'recover'

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
        @items.version.status = "fail"
        @status = "fail"
        callback null

  getFailureFeedback: ->
    result = ""
    for own name, item of @items
      premium = if name in ["broker", "brokerKite"] and KD.config.usePremiumBroker then "premium" else ""
      result = "#{result} #{premium}#{name}"  if item.status is "fail"
    return result


  healthChecker: (root) ->
    for own name, children of root
      item = @items[name]
      do (name, children, item) =>
        unless item
          @waitingResponse -= @getSuccessorCount children
          return warn "#{name} is not registered for health checking"

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

    return count

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

    return waitingRecovery

  canBeRecovered: ->
    for own name, item of @items
      return yes  if item.status is "fail" and item.canBeRecovered()
    return no

  run: ->
    return  warn "there is an ongoing troubleshooting"  if @status is STARTED
    @timeout = KD.utils.wait @getOptions().timeout, => @status = PENDING

    @resetAllItems()

    @status = STARTED
    @result = {}
    @waitingResponse = Object.keys(@items).length

    @healthChecker @checkSequence

  sendFeedback: (feedback, callback) ->
    KD.logToExternal "troubleshoot feedback", {failure:@getFailureFeedback(), feedback}
    {JSystemStatus} = KD.remote.api
    JSystemStatus.sendFeedback
      feedback : feedback
      status   : @getFailureFeedback()
      userAgent: navigator.userAgent
    , callback

