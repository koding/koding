Function::bind or= (context) ->
  if 1 < arguments.length
    args = [].slice.call arguments, 1
    return => @apply context, if arguments.length then args.concat [].slice.call arguments else args
  => if arguments.length then @apply context, arguments else @call context

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

do (arrayProto = Array.prototype, {defineProperty} = Object)->
  # set up .first and .last getters for Array prototype

  "last" of arrayProto or
    defineProperty arrayProto, "last", { get: -> @[@length-1] }

  "first" of arrayProto or
    defineProperty arrayProto, "first", { get: -> @[0] }

# KD Global
KD = @KD or {}

noop  = ->

KD.log   = log   = noop
KD.warn  = warn  = noop
KD.error = error = noop


unless window.event?
  try
    # warn when the global "event" property is accessed.
    Object.defineProperty window, "event", get:->
      KD.warn "Global \"event\" property is accessed. Did you forget a parameter in a DOM event handler?"
  catch e
    log "we fail silently!", e

try
  # warn when the global "event" property is accessed.
  Object.defineProperty window, "appManager", get:->
    console.trace()
    KD.warn "window.appManager is deprecated, use KD.getSingleton(\"appManager\") instead!"
catch e
  log "we fail silently!", e

@KD = $.extend (KD), do ->
  create = (constructorName, options, data)->
    konstructor = @classes[constructorName] \
                ? @classes["KD#{constructorName}"]
    new konstructor options, data  if konstructor?

  create          : create
  new             : create

  debugStates     : {}
  instances       : {}
  introInstances  : {}
  singletons      : {}
  subscriptions   : []
  classes         : {}
  apiUri          : KD.config.apiUri
  appsUri         : KD.config.appsUri
  utils           : __utils
  appClasses      : {}
  appScripts      : {}
  lastFuncCall    : null
  navItems        : []

  socketConnected:->
    @backendIsConnected = yes

  setApplicationPartials:(@appPartials)->

  registerInstance : (anInstance)->
    warn "Instance being overwritten!!", anInstance  if @instances[anInstance.id]
    @instances[anInstance.id] = anInstance

    {introId} = anInstance.getOptions()
    @introInstances[introId] = anInstance if introId
    # @classes[anInstance.constructor.name] ?= anInstance.constructor

  unregisterInstance: (anInstanceId)->
    # warn "Instance being unregistered doesn't exist in registry!!", anInstance unless @instances[anInstance.id]
    delete @instances[anInstanceId]

  deleteInstance:(anInstanceId)->
    @unregisterInstance anInstanceId
    # anInstance = null #FIXME: Redundant? See unregisterInstance

  extend:(obj)->
    for key, val of obj
      if @[key] then throw new Error "#{key} is allready registered"
      else @[key] = val

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

    return error "AppClass is missing a name!"  unless options.name

    if KD.appClasses[options.name]
      return warn "AppClass #{options.name} is already registered or the name is already taken!"

    options.multiple      ?= no           # a Boolean
    options.background    ?= no           # a Boolean
    options.hiddenHandle  ?= no           # a Boolean
    options.openWith     or= "lastActive" # a String "lastActive","forceNew" or "prompt"
    options.behavior     or= ""           # a String "application", "hideTabs", or ""
    options.thirdParty    ?= no           # a Boolean
    options.menu         or= null         # <Array<Object{title: string, eventName: string, shortcut: string}>>

    options.route        or= {}           # <string> or <Object{slug: string, handler: function}>

    slug                   = if "string" is typeof options.route then options.route else options.route.slug
    options.route          =
      slug                 : slug or '/'
      handler              : options.route.handler or null

    if options.route.slug isnt '/'

      {route}         = options
      {slug, handler} = route

      cb = (router)->
        handler or= ({params:{name}, query})->
          router.openSection options.name, name, query
        router.addRoute slug, handler

      if KD.getSingleton 'router'
      then @utils.defer -> cb KD.getSingleton('router')
      else KodingRouter.on 'RouterReady', cb

    if options.navItem?.order
      @registerNavItem options.navItem

    Object.defineProperty KD.appClasses, options.name,
      configurable  : yes
      enumerable    : yes
      writable      : no
      value         : { fn, options }

  registerNavItem    : (itemData)-> @navItems.push itemData

  getNavItems        : -> @navItems.sort (a, b)-> a.order - b.order

  unregisterAppClass :(name)-> delete KD.appClasses[name]

  getAppClass        :(name)-> KD.appClasses[name]?.fn or null

  getAppOptions      :(name)-> KD.appClasses[name]?.options or null

  getAppScript       :(name)-> @appScripts[name] or null

  registerAppScript  :(name, script)-> @appScripts[name] = script

  unregisterAppScript:(name)-> delete @appScripts[name]

  resetAppScripts    :-> @appScripts = {}

  getAllKDInstances  :-> KD.instances

  getKDViewInstanceFromDomElement:(el)-> @instances[el.getAttribute "data-id"]

  enableLogs:do->
    oldConsole = window.console
    window.console = {}
    console[method] = noop  for method in ['log','warn','error','trace','time','timeEnd']

    enableLogs =->
      window.console = oldConsole
      KD.log     = log     = if console?.log     then console.log.bind(console)     else noop
      KD.warn    = warn    = if console?.warn    then console.warn.bind(console)    else noop
      KD.error   = error   = if console?.error   then console.error.bind(console)   else noop
      KD.time    = time    = if console?.time    then console.time .bind(console)   else noop
      KD.timeEnd = timeEnd = if console?.timeEnd then console.timeEnd.bind(console) else noop
      KD.logsEnabled = yes
      return "Logs are enabled now."

  exportKDFramework:->
    (window[item] = KD.classes[item] for item of KD.classes)
    KD.exportKDFramework = -> "Already exported."
    "KDFramework loaded successfully."

KD.enableLogs() if not KD.config?.suppressLogs

prettyPrint = noop