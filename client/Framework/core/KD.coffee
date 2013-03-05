Function::bind or= do ->
  {slice} = []
  (context)->
    func = @
    if 1 < arguments.length
      args = slice.call arguments, 1
      return -> func.apply context, if arguments.length then args.concat slice.call arguments else args
    -> if arguments.length then func.apply context, arguments else func.call context

Function::swiss = (parent, names...)->
  for name in names
    @::[name] = parent::[name]
  @

# Cross-Browser DOM dependencies
window.URL                   ?= window.webkitURL                   ? null
window.BlobBuilder           ?= window.WebKitBlobBuilder           ? window.MozBlobBuilder           ? null
window.requestFileSystem     ?= window.webkitRequestFileSystem     ? null
window.requestAnimationFrame ?= window.webkitRequestAnimationFrame ? window.mozRequestAnimationFrame ? null

# FIXME: add to utils.coffee
String.prototype.capitalize   = ()-> this.charAt(0).toUpperCase() + this.slice(1)
String.prototype.decapitalize = ()-> this.charAt(0).toLowerCase() + this.slice(1)
String.prototype.trim         = ()-> this.replace(/^\s+|\s+$/g,"")

# Dict = Object.create.bind null, null, Object.create null

unless Array.prototype.last
  Object.defineProperty Array.prototype, "last", get : -> this[this.length-1]

unless Array.prototype.first
  Object.defineProperty Array.prototype, "first", get : -> this[0]

# KD Global
KD = @KD or {}

noop  = ->

KD.log   = log   = noop
KD.warn  = warn  = noop
KD.error = error = noop

@KD = $.extend (KD), do ->
  # private member for tracking z-indexes
  zIndexContexts  = {}

  create = (constructorName, options, data)->
    konstructor = @classes[constructorName] \
                ? @classes["KD#{constructorName}"]
    new konstructor options, data  if konstructor?

  create    : create
  new       : create

  impersonate: (username)->
    @remote.api.JAccount.impersonate username, (err)->
      if err then new KDNotificationView title: err.message
      else location.reload()

  # testKDML:->
  #   {KDMLParser} = Bongo.KDML
  #   kdml = new KDMLParser @classes

  debugStates     : {}
  instances       : {}
  singletons      : {}
  subscriptions   : []
  classes         : {}
  apiUri          : KD.config.apiUri
  appsUri         : KD.config.appsUri
  utils           : __utils
  appClasses      : {}

  whoami:-> KD.getSingleton('mainController').userAccount

  logout:->
    mainController = KD.getSingleton('mainController')
    delete mainController?.userAccount

  isLoggedIn:-> @whoami() instanceof KD.remote.api.JAccount

  isMine:(account)-> @whoami().profile.nickname is account.profile.nickname

  checkFlag:(flagToCheck, account = KD.whoami())->
    if account.globalFlags
      if 'string' is typeof flagToCheck
        return flagToCheck in account.globalFlags
      else
        for flag in flagToCheck
          if flag in account.globalFlags
            return yes
    no

  requireLogin:(errMsg, callback)->

    [callback, errMsg] = [errMsg, callback] unless callback

    if KD.whoami() instanceof KD.remote.api.JGuest
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
    warn "Instance being overwritten!!", anInstance  if @instances[anInstance.id]
    @instances[anInstance.id] = anInstance
    # @classes[anInstance.constructor.name] ?= anInstance.constructor

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

  registerAppClass:(fn, options = {})->

    {name} = options

    unless name
      return error "AppClass is missing a name!"

    if KD.appClasses[name]
      return warn "AppClass #{name} is already registered or the name is already taken!"

    options.multiple      ?= no           # a Boolean
    options.background    ?= no           # a Boolean
    options.hiddenHandle  ?= no           # a Boolean
    options.route        or= ""           # a String
    options.openWith     or= "lastActive" # a String "lastActive" or "prompt"
    options.behavior     or= ""           # a String "application", "hideTabs", or ""

    Object.defineProperty KD.appClasses, options.name,
      configurable  : yes
      enumerable    : yes
      writable      : no
      value         : {
        fn
        options
      }

  unregisterAppClass:(name)-> delete KD.appClasses[name]

  getAppClass:(name)-> KD.appClasses[name]?.fn or null
  getAppOptions:(name)-> KD.appClasses[name]?.options or null

  getAllKDInstances:()-> KD.instances

  getKDViewInstanceFromDomElement:(domElement)->
    @instances[$(domElement).data("data-id")]

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

  enableLogs:do->
    oldConsole = window.console
    window.console = {}
    console[method] = noop  for method in ['log','warn','error','trace','time','timeEnd']

    enableLogs =->
      window.console = oldConsole
      KD.log   = log   = if console?.log   then console.log.bind(console)   else noop
      KD.warn  = warn  = if console?.warn  then console.warn.bind(console)  else noop
      KD.error = error = if console?.error then console.error.bind(console) else noop
      return "Logs are enabled now."

  exportKDFramework:->
    (window[item] = KD.classes[item] for item of KD.classes)
    KD.exportKDFramework = -> "Already exported."
    "KDFramework loaded successfully."

KD.enableLogs() if not KD.config?.suppressLogs

prettyPrint = noop