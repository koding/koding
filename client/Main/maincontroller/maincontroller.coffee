class MainController extends KDController
  ###

  * EMITTED EVENTS
    - AppIsReady
    - AccountChanged                [account, firstLoad]
    - pageLoaded.as.loggedIn        [account, connectedState, firstLoad]
    - pageLoaded.as.loggedOut       [account, connectedState, firstLoad]
    - accountChanged.to.loggedIn    [account, connectedState, firstLoad]
    - accountChanged.to.loggedOut   [account, connectedState, firstLoad]

  ###

  Promise.longStackTraces()

  connectedState = connected : no

  constructor:(options = {}, data)->

    options.failWait  = 10000            # duration in miliseconds to show a connection failed modal

    super options, data

    @appStorages = {}

    @createSingletons()
    @setFailTimer()
    @attachListeners()

    @detectIdleUser()
    @startCachingAssets()  unless KD.isLoggedInOnLoad

  createSingletons:->

    KD.registerSingleton "mainController",            this

    KD.registerSingleton 'kontrol',                   new KodingKontrol

    KD.registerSingleton 'appManager',   appManager = new ApplicationManager
    KD.registerSingleton 'globalKeyCombos',  combos = new KDKeyboardMap priority : 0
    KD.registerSingleton 'notificationController',    new NotificationController
    KD.registerSingleton 'linkController',            new LinkController
    KD.registerSingleton 'display',                   new ContentDisplayController
    KD.registerSingleton 'kiteController',            new KiteController
    KD.registerSingleton 'router',           router = new KodingRouter
    KD.registerSingleton 'localStorageController',    new LocalStorageController
    KD.registerSingleton 'oauthController',           new OAuthController
    KD.registerSingleton 'groupsController',          new GroupsController
    KD.registerSingleton 'activityController',        new ActivityController
    KD.registerSingleton 'paymentController',         new PaymentController
    KD.registerSingleton 'vmController',              new VirtualizationController
    KD.registerSingleton 'computeController',         new ComputeController
    KD.registerSingleton 'locationController',        new LocationController
    KD.registerSingleton 'helpController',            new HelpController
    KD.registerSingleton 'troubleshoot',              new Troubleshoot
    KD.registerSingleton 'appStorageController',      new AppStorageController
    KD.registerSingleton 'localSync',                 new LocalSyncController
    KD.registerSingleton 'dock',                      new DockController
    KD.registerSingleton 'mainView',             mv = new MainView
    KD.registerSingleton 'mainViewController',  mvc = new MainViewController view : mv
    KD.registerSingleton 'kodingAppsController',      new KodingAppsController
    KD.registerSingleton 'socialapi',                 new SocialApiController
    KD.registerSingleton 'autocomplete',              new AutoCompleteController

    router.listen()
    @mainViewController = mvc
    mv.appendToDomBody()

    @ready =>
      KD.registerSingleton 'widgetController',        new WidgetController
      KD.registerSingleton 'onboardingController',    new OnboardingController

      @emit 'AppIsReady'

      console.timeEnd 'Koding.com loaded'

    @forwardEvents KD.remote, ['disconnected', 'reconnected']

  accountChanged:(account, firstLoad = no)->
    account = KD.remote.revive account  unless account instanceof KD.remote.api.JAccount
    KD.userAccount = account
    connectedState.connected = yes

    @on 'pageLoaded.as.loggedIn', (account)-> # ignore othter parameters
      KD.utils.setPreferredDomain account if account

    if KD.useNewKites
      (KD.getSingleton 'kontrol').reauthenticate()
      # (KD.getSingleton 'kontrolProd').reauthenticate()

    account.fetchMyPermissionsAndRoles (err, { permissions, roles }) =>
      return warn err  if err
      KD.config.roles       = roles
      KD.config.permissions = permissions

      @ready @emit.bind this, "AccountChanged", account, firstLoad

      @emit 'ready'

      # this emits following events
      # -> "pageLoaded.as.loggedIn"
      # -> "pageLoaded.as.loggedOut"
      # -> "accountChanged.to.loggedIn"
      # -> "accountChanged.to.loggedOut"
      eventPrefix = if firstLoad then "pageLoaded.as" else "accountChanged.to"
      eventSuffix = if KD.isLoggedIn() then "loggedIn" else "loggedOut"
      @emit "#{eventPrefix}.#{eventSuffix}", account, connectedState, firstLoad

  doLogout:->
    mainView = KD.getSingleton("mainView")
    KD.logout()
    storage = new LocalStorage 'Koding'

    KD.remote.api.JUser.logout (err) =>
      mainView._logoutAnimation()
      KD.singletons.localSync.removeLocalContents()

      wc = KD.singleton 'windowController'
      wc.clearUnloadListeners()

      KD.utils.wait 1000, =>
        @swapAccount replacementAccount: null
        storage.setValue 'loggingOut', '1'
        location.reload()

  attachListeners:->
    # @on 'pageLoaded.as.(loggedIn|loggedOut)', (account)=>
    #   log "pageLoaded", KD.isLoggedIn()

    # TODO: this is a kludge we needed.  sorry for this.  Move it someplace better C.T.
    wc = KD.singleton 'windowController'
    @utils.wait 15000, ->
      KD.remote.api?.JSystemStatus.on 'forceReload', ->
        window.removeEventListener 'beforeunload', wc.bound 'beforeUnload'
        location.reload()

    # async clientId change checking procedures causes
    # race conditions between window reloading and post-login callbacks
    cookieChangeHandler = do (cookie = Cookies.get 'clientId') => =>
      cookieExists = cookie?
      cookieMatches = cookie is (Cookies.get 'clientId')
      cookie = Cookies.get 'clientId'

      if cookieExists and not cookieMatches
        return @isLoggingIn off  if @isLoggingIn() is on

        window.removeEventListener 'beforeunload', wc.bound 'beforeUnload'
        @emit "clientIdChanged"

        # window location path is set to last route to ensure visitor is not
        # redirected to another page
        @utils.defer ->
          lastRoute = localStorage?.routeToBeContinued or KD.getSingleton("router").visitedRoutes.last

          if lastRoute and /^\/(?:Reset|Register|Verify|Confirm)\//.test lastRoute
            lastRoute = "/Activity"

          {entryPoint} = KD.config
          KD.getSingleton('router').handleRoute lastRoute or '/Activity', {replaceState: yes, entryPoint}
          localStorage?.removeItem "routeToBeContinued"

        @utils.wait 3000, cookieChangeHandler
    # Note: I am using wait instead of repeat, for the subtle difference.  See this StackOverflow answer for more info:
    #       http://stackoverflow.com/questions/729921/settimeout-or-setinterval/731625#731625
    @utils.wait 3000, cookieChangeHandler

  swapAccount: (options, callback) ->
    return { message: 'Login failed!' } unless options

    { account, replacementToken } = options

    { maxAge, secure } = KD.config.sessionCookie

    if replacementToken and replacementToken isnt Cookies.get 'clientId'
      Cookies.set 'clientId', replacementToken, { maxAge, secure }

    if account
      @accountChanged account
      if callback
        @once 'AccountChanged', (account) -> callback null, options

  handleLogin: (credentials, callback) ->
    { JUser } = KD.remote.api

    @isLoggingIn on

    credentials.username = credentials.username.toLowerCase().trim()

    JUser.login credentials, (err, result) =>
      return callback err  if err
      @swapAccount result, callback

  handleFinishRegistration: (formData, callback) ->
    { JUser } = KD.remote.api

    @isLoggingIn on

    JUser.finishRegistration formData, (err, result) =>
      return callback err  if err
      @swapAccount result, callback

  handleOauthAuth : (formData, callback)->
    { JUser } = KD.remote.api

    @isLoggingIn on

    # Same oauth flow is used for login and registering, however
    # after auth code paths differs.
    JUser.authenticateWithOauth formData, (err, result) =>
      return callback err          if err
      return callback err, result  if result.isNewUser
      return callback err, result  if formData.isUserLoggedIn

      @swapAccount result, callback

  isLoggingIn: (isLoggingIn) ->

    storage = new LocalStorage 'Koding'
    if storage.getValue('loggingOut') is '1'
      storage.unsetKey 'loggingOut'
      return yes
    if isLoggingIn?
      @_isLoggingIn = isLoggingIn
    else
      @_isLoggingIn ? no

  setFailTimer: do->
    notification = null
    fail  = ->

      notification = new KDNotificationView
        title         : "Couldn't connect to backend!"
        type          : "tray"
        closeManually : no
        content       : """We don't know why, but your browser couldn't reach our server.
                           <br>Still trying but if you want you can click here to refresh the page."""
        duration      : 0
        click         : -> location.reload yes

    checkConnectionState = ->
      unless connectedState.connected
        KD.logToExternalWithTime "Connect to backend"
        fail()

    return ->
      @utils.wait @getOptions().failWait, checkConnectionState
      @on "AccountChanged", -> notification.destroy()  if notification

  detectIdleUser: (threshold = KD.config.userIdleMs) ->
    idleDetector = new IdleUserDetector { threshold }
    @forwardEvents idleDetector, ['userIdle', 'userBack']


  startCachingAssets:->

    KD.utils.defer ->

      KD.singletons.appManager.require 'Login'

      images = [
        '/a/images/city.jpg'
        '/a/images/home-pat.png'
        '/a/images/edu-pat.png'
        '/a/images/biz-pat.png'
        '/a/images/pricing-pat.png'
        '/a/images/ss-activity.jpg'
        '/a/images/ss-terminal.jpg'
        '/a/images/ss-teamwork.jpg'
        '/a/images/ss-environments.jpg'
        "/a/images/unsplash/#{LoginView.backgroundImageNr}.jpg"
      ]

      for src in images
        image     = new Image
        image.src = src
