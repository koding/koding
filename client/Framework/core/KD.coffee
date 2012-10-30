Function::bind or= do ->
  {slice} = []
  (context)->
    func = @
    if 1 < arguments.length
      args = slice.call arguments, 1
      return -> func.apply context, if arguments.length then args.concat slice.call arguments else args
    -> if arguments.z then func.apply context, arguments else func.call context

Function::swiss = (parent, names...)->
  for name in names
    @::[name] = parent::[name]
  @

# Cross-Browser DOM dependencies
window.URL                   = window.URL                   ? window.webkitURL                   ? null
window.BlobBuilder           = window.BlobBuilder           ? window.WebKitBlobBuilder           ? window.MozBlobBuilder           ? null
window.requestFileSystem     = window.requestFileSystem     ? window.webkitRequestFileSystem     ? null
window.requestAnimationFrame = window.requestAnimationFrame ? window.webkitRequestAnimationFrame ? window.mozRequestAnimationFrame ? null

# FIXME: add to utils.coffee
String.prototype.capitalize   = ()-> this.charAt(0).toUpperCase() + this.slice(1)
String.prototype.decapitalize = ()-> this.charAt(0).toLowerCase() + this.slice(1)
String.prototype.trim         = ()-> this.replace(/^\s+|\s+$/g,"")

# KD Global
KD = @KD or {}

noop  = ->

KD.log   = log   = noop
KD.warn  = warn  = noop
KD.error = error = noop

@KD = $.extend (KD), do ->

  # private member for tracking z-indexes
  zIndexContexts  = {}
  debugStates     : {}
  instances       : {}
  singletons      : {}
  subscriptions   : []
  classes         : {}
  apiUri          : KD.config.apiUri
  appsUri         : KD.config.appsUri

  whoami:-> KD.getSingleton('mainController').userAccount

  isLoggedIn:-> @whoami() instanceof KD.remote.api.JAccount

  isMine:(account)-> @whoami().profile.nickname is account.profile.nickname

  checkFlag:(flag, account = KD.whoami())-> account.globalFlags and flag in account.globalFlags

  requireLogin:(errMsg, callback)->

    [callback, errMsg] = [errMsg, callback] unless callback

    if KD.whoami() instanceof KD.remote.api.JGuest
      # KDView::handleEvent {type:"NavigationTrigger",pageName:"Login", appId:"Login"}
      new KDNotificationView
        type     : 'growl'
        title    : 'Access denied!'
        content  : errMsg or 'You must log in to perform this action!'
        duration : 3000
    else
      callback?()

  socketConnected:()->
    @backendIsConnected = yes
    KDObject.emit "KDBackendConnectedEvent"

  setApplicationPartials:(partials)->

    @appPartials = partials

  subscribe : (subscription)->
    # unless subscription.KDEventType.toLowerCase() is "resize"
    @subscriptions.push subscription

  # FIXME: very wasteful way to remove subscriptions, vs. splice ??
  removeSubscriptions : (aKDViewInstance) ->
    newSubscriptions = for subscription,i in @subscriptions
      subscription if subscription.subscribingInstance isnt aKDViewInstance
    @recreateSubscriptions newSubscriptions

  recreateSubscriptions:(newSubscriptions)->
    @subscriptions = []
    for subscription in newSubscriptions
      @subscriptions.push subscription if subscription?

  getAllSubscriptions: ->
    @subscriptions

  registerInstance : (anInstance)->
    warn "Instance being overwritten!!", anInstance if @instances[anInstance.id]
    @instances[anInstance.id] = anInstance
    @classes[anInstance.constructor.name] ?= anInstance.constructor

  unregisterInstance: (anInstanceId)->
    # warn "Instance being unregistered doesn't exist in registry!!", anInstance unless @instances[anInstance.id]
    delete @instances[anInstanceId]

  deleteInstance:(anInstanceId)->
    @unregisterInstance anInstanceId
    # anInstance = null #FIXME: Redundant? See unregisterInstance

  registerSingleton:(singletonName,object,override = no)->
    if (existingSingleton = KD.singletons[singletonName])?
      if override
        warn "singleton overriden! KD.singletons[\"#{singletonName}\"]"
        existingSingleton.destroy?()
        KD.singletons[singletonName] = object
      else
        error "KD.singletons[\"#{singletonName}\"] singleton exists! if you want to override set override param to true]"
        KD.singletons[singletonName]
      KDObject.emit "singleton.#{singletonName}.registered"
    else
      # log "singleton registered! KD.singletons[\"#{singletonName}\"]"
      KD.singletons[singletonName] = object

  getSingleton:(singletonName)->
    if KD.singletons[singletonName]?
      KD.singletons[singletonName]
    else
      warn "\"#{singletonName}\" singleton doesn't exist!"
      null

  getAllKDInstances:()-> KD.instances

  getKDViewInstanceFromDomElement:(domElement)->
    @instances[$(domElement).data("data-id")]

  propagateEvent: (KDEventType, publishingInstance, value)->
    for subscription in @subscriptions
      if (!KDEventType? or !subscription.KDEventType? or !!KDEventType.match(subscription.KDEventType.capitalize()))
        subscription.callback.call subscription.subscribingInstance, publishingInstance, value, {subscription}

  # Get next highest Z-index
  getNextHighestZIndex:(context)->
   uniqid = context.data 'data-id'
   if isNaN zIndexContexts[uniqid]
     zIndexContexts[uniqid] = 0
   else
     zIndexContexts[uniqid]++

  jsonhTest:->
    method    = 'fetchQuestionTeasers'
    testData  = {
      foo: 10
      bar: 11
    }

    start = Date.now()
    $.ajax "/#{method}.jsonh",
      data     : testData
      dataType : 'jsonp'
      success : (data)->
        inflated = JSONH.unpack data
        KD.log 'success', inflated
        KD.log Date.now()-start

  enableLogs:->
    KD.log   = log   = if console?.log   then console.log.bind(console)   else noop
    KD.warn  = warn  = if console?.warn  then console.warn.bind(console)  else noop
    KD.error = error = if console?.error then console.error.bind(console) else noop
    return "Logs are enabled now."

KD.enableLogs() if not KD.config?.suppressLogs

prettyPrint = noop