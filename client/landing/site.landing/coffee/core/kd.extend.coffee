kd = require 'kd'
kd.extend

  config       : {}
  apiUri       : null
  appsUri      : null
  appClasses   : {}
  appScripts   : {}

  registerAppClass: (fn, options = {}) ->

    return error 'AppClass is missing a name!'  unless options.name

    if kd.appClasses[options.name]

      if kd.config.apps[options.name]
        return warn "AppClass #{options.name} cannot be used, since its conflicting with an internal Koding App."
      else
        warn "AppClass #{options.name} is already registered or the name is already taken!"
        warn 'Removing the old one. It was ', kd.appClasses[options.name]
        @unregisterAppClass options.name

    options.multiple      ?= no           # a Boolean
    options.background    ?= no           # a Boolean
    options.hiddenHandle  ?= no           # a Boolean
    options.openWith     or= 'lastActive' # a String "lastActive","forceNew" or "prompt"
    options.behavior     or= ''           # a String "application", or ""
    options.thirdParty    ?= no           # a Boolean
    options.menu         or= null         # <Array<Object{title: string, eventName: string, shortcut: string}>>
    options.navItem      or= {}           # <Object{title: string, eventName: string, shortcut: string}>
    options.labels       or= []           # <Array<string>> list of labels to use as app name
    options.version       ?= '1.0'        # <string> version
    options.route        or= null         # <string> or <Object{slug: string, handler: function}>
    options.routes       or= null         # <string> or <Object{slug: string, handler: function}>
    options.styles       or= []           # <Array<string>> list of stylesheets

    { routes, route, name }  = options

    if route
    then @registerRoute name, route
    else if routes
    then @registerRoutes name, routes

    Object.defineProperty kd.appClasses, name,
      configurable  : yes
      enumerable    : yes
      writable      : no
      value         : { fn, options }

  registerRoutes: (appName, routes) ->

    @registerRoute appName, route, handler for own route, handler of routes


  registerRoute: (appName, route, handler) ->

    slug   = if 'string' is typeof route then route else route.slug
    route  =
      slug    : slug ? '/'
      handler : handler or route.handler or null

    if route.slug isnt '/' or appName is 'kd.MainApp'

      { slug, handler } = route

      cb = ->
        router = kd.getSingleton 'router'
        handler ?= ({ params:{ name }, query }) ->
          router.openSection appName, name, query
        router.addRoute slug, handler

      if router = kd.singletons.router then cb()
      else kd.Router.on 'RouterIsReady', cb

  unregisterAppClass : (name) -> delete kd.appClasses[name]

  getAppClass        : (name) -> kd.appClasses[name]?.fn or null

  getAppOptions      : (name) -> kd.appClasses[name]?.options or null

  getAppVersion      : (name) -> kd.appClasses[name]?.options?.version or null

  getAppScript       : (name) -> @appScripts[name] or null

  registerAppScript  : (name, script) -> @appScripts[name] = script

  unregisterAppScript: (name) -> delete @appScripts[name]

  resetAppScripts    : -> @appScripts = {}

  runningInFrame: -> window.top isnt window.self
