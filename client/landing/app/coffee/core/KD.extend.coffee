KD.extend
  newKodingLaunchDate: do ->
    d = new Date()
    d.setUTCFullYear 2014
    d.setUTCMonth 7
    d.setUTCDate 30
    d.setUTCHours 17
    d.setUTCMinutes 0
    d

  setVersionCookie: ({ meta:{ createdAt }}) ->
    if (new Date createdAt) > KD.newKodingLaunchDate
      Cookies.set 'koding082014', 'koding082014'

  config       : {}
  apiUri       : null
  appsUri      : null
  singleton    : KD.getSingleton.bind KD
  appClasses   : {}
  appScripts   : {}
  appLabels    : {}
  navItems     : []
  navItemIndex : {}

  whoami:-> KD.userAccount

  isLoggedIn:-> KD.whoami()?.type is 'registered'

  registerAppClass:(fn, options = {})->

    return error "AppClass is missing a name!"  unless options.name

    if KD.appClasses[options.name]

      if KD.config.apps[options.name]
        return warn "AppClass #{options.name} cannot be used, since its conflicting with an internal Koding App."
      else
        warn "AppClass #{options.name} is already registered or the name is already taken!"
        warn "Removing the old one. It was ", KD.appClasses[options.name]
        @unregisterAppClass options.name

    options.multiple      ?= no           # a Boolean
    options.background    ?= no           # a Boolean
    options.hiddenHandle  ?= no           # a Boolean
    options.openWith     or= "lastActive" # a String "lastActive","forceNew" or "prompt"
    options.behavior     or= ""           # a String "application", or ""
    options.thirdParty    ?= no           # a Boolean
    options.menu         or= null         # <Array<Object{title: string, eventName: string, shortcut: string}>>
    options.navItem      or= {}           # <Object{title: string, eventName: string, shortcut: string}>
    options.labels       or= []           # <Array<string>> list of labels to use as app name
    options.version       ?= "1.0"        # <string> version
    options.route        or= null         # <string> or <Object{slug: string, handler: function}>
    options.routes       or= null         # <string> or <Object{slug: string, handler: function}>
    options.styles       or= []           # <Array<string>> list of stylesheets

    {routes, route, name}  = options

    if route
    then @registerRoute name, route
    else if routes
    then @registerRoutes name, routes

    if options.navItem?.order
      @registerNavItem options.navItem

    Object.defineProperty KD.appClasses, name,
      configurable  : yes
      enumerable    : yes
      writable      : no
      value         : { fn, options }

  registerRoutes: (appName, routes) ->

    @registerRoute appName, route, handler for own route, handler of routes


  registerRoute: (appName, route, handler) ->

    slug   = if "string" is typeof route then route else route.slug
    route  =
      slug    : slug ? '/'
      handler : handler or route.handler or null

    if route.slug isnt '/' or appName is 'KDMainApp'

      {slug, handler} = route

      cb = ->
        router = KD.getSingleton 'router'
        handler ?= ({params:{name}, query}) ->
          router.openSection appName, name, query
        router.addRoute slug, handler

      if router = KD.singletons.router then cb()
      else KDRouter.on 'RouterIsReady', cb


  resetNavItems      : (items)->
    @navItems        = items
    @navItemIndex    = KD.utils.arrayToObject items, 'title'

  registerNavItem    : (itemData)->
    unless @navItemIndex[itemData.title]
      @navItemIndex[itemData.title] = itemData
      @navItems.push itemData
      return true
    return false

  getNavItems        : -> @navItems.sort (a, b)-> a.order - b.order

  setNavItems        : (navItems)->
    @registerNavItem item for item in navItems.sort (a, b)-> a.order - b.order

  unregisterAppClass :(name)-> delete KD.appClasses[name]

  getAppClass        :(name)-> KD.appClasses[name]?.fn or null

  getAppOptions      :(name)-> KD.appClasses[name]?.options or null

  getAppVersion      :(name)-> KD.appClasses[name]?.options?.version or null

  getAppScript       :(name)-> @appScripts[name] or null

  registerAppScript  :(name, script)-> @appScripts[name] = script

  unregisterAppScript:(name)-> delete @appScripts[name]

  resetAppScripts    :-> @appScripts = {}

  disableLogs:->
    for method in ['log','warn','error','trace','info','time','timeEnd']
      window[method] = noop
      KD[method]     = noop
    delete KD.logsEnabled
    return "Logs are disabled now."

  enableLogs:(state = yes)->
    return KD.disableLogs()  unless state
    KD.log     = window.log     = console.log.bind     console
    KD.warn    = window.warn    = console.warn.bind    console
    KD.error   = window.error   = console.error.bind   console
    KD.info    = window.info    = console.info.bind    console
    KD.time    = window.time    = console.time.bind    console
    KD.timeEnd = window.timeEnd = console.timeEnd.bind console
    KD.logsEnabled = yes
    return "Logs are enabled now."

  runningInFrame: -> window.top isnt window.self

  tell: -> KD.getSingleton('appManager').tell arguments...
