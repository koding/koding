# this class will register itself just before application starts loading, right after framework is ready

KD.extend

  apiUri       : KD.config.apiUri
  appsUri      : KD.config.appsUri
  singleton    : KD.getSingleton.bind KD
  useNewKites  : do ->
    useNewKites = switch
      when KD.config.kites.stack.force
        Boolean KD.config.kites.stack.newKites
      when localStorage.useNewKites?
        Boolean Number localStorage.useNewKites
    localStorage.useNewKites = if useNewKites then '1' else ''
    return useNewKites
  useWebSockets : yes
  appClasses   : {}
  appScripts   : {}
  appLabels    : {}
  navItems     : []
  navItemIndex : {}

  toggleKiteStack: ->
    localStorage.useNewKites =
      if @useNewKites
      then ''
      else '1'
    location.reload()

  socketConnected:->
    @backendIsConnected = yes

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


  showEnforceLoginModal: ->

    return  if KD.isLoggedIn()
    if Cookies.get('doNotForceRegistration') or location.search.indexOf('sr=1') > -1
      Cookies.set 'doNotForceRegistration', 'true'
      return

    {appManager} = KD.singletons
    appManager.tell 'Account', 'showRegistrationNeededModal'


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
    for method in ['log','warn','error','trace','time','timeEnd']
      window[method] = noop
      KD[method]     = noop
    delete KD.logsEnabled
    return "Logs are disabled now."

  enableLogs:(state = yes)->
    return KD.disableLogs()  unless state
    KD.log     = window.log     = console.log.bind     console
    KD.warn    = window.warn    = console.warn.bind    console
    KD.error   = window.error   = console.error.bind   console
    KD.time    = window.time    = console.time.bind    console
    KD.timeEnd = window.timeEnd = console.timeEnd.bind console
    KD.logsEnabled = yes
    return "Logs are enabled now."

  # Rewrites console.log to send logs to backend and also browser console.
  enabledBackendLogger: (backendLoggerClass)->
    oldConsoleLog = console.log
    frontloggerConsoleLog = (args...)->
      return unless KD.logsEnabled
      oldConsoleLog.apply this, arguments
      backendLoggerClass.info.apply backendLoggerClass, arguments

    console.log = frontloggerConsoleLog

    return "Logs are logged to backend too."

  impersonate : (username)->
    KD.remote.api.JAccount.impersonate username, (err)->
      if err then new KDNotificationView title: err.message
      else location.reload()

  notify_:(message, type='', duration = 3500)->
    new KDNotificationView
      cssClass : type
      title    : message
      duration : duration

  requireMembership:(options={})->

    {callback, onFailMsg, onFail, silence, tryAgain, groupName} = options
    unless KD.isLoggedIn()
      # if there is fail message, display it
      if onFailMsg
        @notify_ onFailMsg, "error"

      # if there is fail method, call it
      onFail?()

      # if it's not a silent operation redirect
      unless silence
        KD.getSingleton('router').handleRoute "/Login",
          entryPoint : KD.config.entryPoint

      # if there is callback and we want to try again
      if callback? and tryAgain
        unless KD.lastFuncCall
          KD.lastFuncCall = callback

          mainController = KD.getSingleton("mainController")
          mainController.once "accountChanged.to.loggedIn", =>
            if KD.isLoggedIn()
              KD.lastFuncCall?()
              KD.lastFuncCall = null
              if groupName
                @joinGroup_ groupName, (err) =>
                  return @notify_ "Joining #{groupName} group failed", "error"  if err
    else if groupName
      @joinGroup_ groupName, (err)=>
        return @notify_ "Joining #{groupName} group failed", "error"  if err
        callback?()
    else
      callback?()

  joinGroup_:(groupName, callback)->
    return callback null unless groupName
    user = @whoami()
    user.checkGroupMembership groupName, (err, isMember)=>
      return callback err  if err
      return callback null if isMember

      #join to group
      @remote.api.JGroup.one { slug: groupName }, (err, currentGroup)=>
        return callback err if err
        return callback null unless currentGroup
        currentGroup.join (err)=>
          return callback err if err
          @notify_ "You have joined to #{groupName} group!", "success"
          return callback null

  nick:-> KD.whoami()?.profile?.nickname

  whoami:-> KD.userAccount

  logout:->
    mainController = KD.getSingleton('mainController')
    mainController.isLoggingIn on
    delete KD.userAccount

  isGuest:-> not KD.isLoggedIn()

  isLoggedIn:-> KD.whoami()?.type is 'registered'

  isMine:(account)-> KD.whoami().profile.nickname is account.profile.nickname

  checkFlag:(flagToCheck, account = KD.whoami())->
    if account.globalFlags
      if 'string' is typeof flagToCheck
        return flagToCheck in account.globalFlags
      else
        for flag in flagToCheck
          if flag in account.globalFlags
            return yes
    no

  showError:(err, messages)->
    return no  unless err

    if Array.isArray err
      @showError er  for er in err
      return err.length

    if 'string' is typeof err
      message = err
      err     = {message}

    defaultMessages =
      AccessDenied : 'Permission denied'
      KodingError  : 'Something went wrong'

    err.name or= 'KodingError'
    content    = ''

    if messages
      errMessage = messages[err.name] or messages.KodingError \
                                      or defaultMessages.KodingError
    messages or= defaultMessages
    errMessage or= err.message or messages[err.name] or messages.KodingError

    if errMessage?
      if 'string' is typeof errMessage
        title = errMessage
      else if errMessage.title? and errMessage.content?
        {title, content} = errMessage

    duration = errMessage.duration or 2500
    title  or= err.message

    new KDNotificationView {title, content, duration}

    unless err.name is 'AccessDenied'
      warn "KodingError:", err.message
      error err
    err?

  getPathInfo: (fullPath)->
    return no unless fullPath
    path      = FSHelper.plainPath fullPath
    basename  = FSHelper.getFileNameFromPath fullPath
    parent    = FSHelper.getParentPath path
    vmName    = FSHelper.getVMNameFromPath fullPath
    isPublic  = FSHelper.isPublicPath fullPath
    {path, basename, parent, vmName, isPublic}

  getPublicURLOfPath: (fullPath, secure=no)->
    {vmName, isPublic, path} = KD.getPathInfo fullPath
    return unless isPublic
    pathPartials = path.match /^\/home\/(\w+)\/Web\/(.*)/
    return unless pathPartials
    [_, user, publicPath] = pathPartials

    publicPath or= ""
    subdomain =
      if /^shared\-/.test(vmName) and user is KD.nick()
      then "#{user}."
      else ""

    return "#{if secure then 'https' else 'http'}://#{subdomain}#{vmName}/#{publicPath}"

  runningInFrame: -> window.top isnt window.self

  getGroup: -> KD.currentGroup

  getReferralUrl: (username) ->
    "#{location.origin}/R/#{username}"

  tell: -> KD.getSingleton('appManager').tell arguments...

  hasAccess:(permission)->
    if "admin" in KD.config.roles then yes else permission in KD.config.permissions

Object.defineProperty KD, "defaultSlug",
  get:->
    if KD.isGuest() then 'guests' else 'koding'

KD.enableLogs (Cookies.get 'enableLogs') or !KD.config?.suppressLogs
