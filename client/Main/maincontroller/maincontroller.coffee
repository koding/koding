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

  connectedState = connected : no

  constructor:(options = {}, data)->

    options.failWait  = 10000            # duration in miliseconds to show a connection failed modal

    super options, data

    @appStorages = {}

    @createSingletons()
    @setFailTimer()
    @attachListeners()

  createSingletons:->

    KD.registerSingleton "mainController",            this
    KD.registerSingleton "appManager",   appManager = new ApplicationManager
    KD.registerSingleton "notificationController",    new NotificationController
    KD.registerSingleton "linkController",            new LinkController
    KD.registerSingleton "display",                   new ContentDisplayController
    KD.registerSingleton "kiteController",            new KiteController
    KD.registerSingleton 'router',           router = new KodingRouter
    KD.registerSingleton "localStorageController",    new LocalStorageController
    KD.registerSingleton "oauthController",           new OAuthController
    KD.registerSingleton "groupsController",          new GroupsController
    KD.registerSingleton "paymentController",         new PaymentController
    if KD.useNewKites
      KD.registerSingleton "kontrol",                 new Kontrol
    KD.registerSingleton "vmController",              new VirtualizationController
    KD.registerSingleton "locationController",        new LocationController
    KD.registerSingleton "badgeController",           new BadgeController
    KD.registerSingleton "helpController",            new HelpController

    # appManager.create 'Chat', (chatController)->
    #   KD.registerSingleton "chatController", chatController

    @ready =>
      router.listen()
      KD.registerSingleton "widgetController",        new WidgetController
      KD.registerSingleton "activityController",      new ActivityController
      KD.registerSingleton "appStorageController",    new AppStorageController
      KD.registerSingleton "kodingAppsController",    new KodingAppsController
      # KD.registerSingleton "kontrol",                 new Kontrol

      # @showInstructionsBook()
      @emit 'AppIsReady'

      console.timeEnd "Koding.com loaded"

    @forwardEvents KD.remote, ['disconnected', 'reconnected']

  accountChanged:(account, firstLoad = no)->
    account = KD.remote.revive account  unless account instanceof KD.remote.api.JAccount
    @userAccount             = account
    connectedState.connected = yes

    @on "pageLoaded.as.loggedIn", (account)-> # ignore othter parameters
      KD.utils.setPreferredDomain account if account

    account.fetchMyPermissionsAndRoles (err, permissions, roles)=>
      return warn err  if err
      KD.config.roles       = roles
      KD.config.permissions = permissions

      @ready @emit.bind this, "AccountChanged", account, firstLoad

      @createMainViewController()  unless @mainViewController

      @emit 'ready'

      # this emits following events
      # -> "pageLoaded.as.loggedIn"
      # -> "pageLoaded.as.loggedOut"
      # -> "accountChanged.to.loggedIn"
      # -> "accountChanged.to.loggedOut"
      eventPrefix = if firstLoad then "pageLoaded.as" else "accountChanged.to"
      eventSuffix = if @isUserLoggedIn() then "loggedIn" else "loggedOut"
      @emit "#{eventPrefix}.#{eventSuffix}", account, connectedState, firstLoad

  createMainViewController:->
    KD.registerSingleton "dock", new DockController
    @mainViewController  = new MainViewController
      view    : mainView = new MainView
        domId : "kdmaincontainer"
    mainView.appendToDomBody()

  doLogout:->
    mainView = KD.getSingleton("mainView")
    KD.logout()
    storage = new LocalStorage 'Koding'

    KD.remote.api.JUser.logout (err, account, replacementToken)=>
      mainView._logoutAnimation()

      wc = KD.singleton 'windowController'
      wc.clearUnloadListeners()

      KD.utils.wait 1000, ->
        Cookies.set 'clientId', replacementToken, secure: yes  if replacementToken
        storage.setValue 'loggingOut', '1'
        location.reload()

  attachListeners:->
    # @on 'pageLoaded.as.(loggedIn|loggedOut)', (account)=>
    #   log "pageLoaded", @isUserLoggedIn()

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

  setVisitor:(visitor)-> @visitor = visitor
  getVisitor: -> @visitor
  getAccount: -> KD.whoami()

  swapAccount: (options, callback) ->
    return { message: 'Login failed!' } unless options

    { account, replacementToken } = options

    { maxAge, secure } = KD.config.sessionCookie

    if replacementToken and replacementToken isnt Cookies.get 'clientId'
      Cookies.set 'clientId', replacementToken, { maxAge, secure }

    @accountChanged account

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

  isUserLoggedIn: -> KD.isLoggedIn()

  isLoggingIn: (isLoggingIn) ->

    storage = new LocalStorage 'Koding'
    if storage.getValue('loggingOut') is '1'
      storage.unsetKey 'loggingOut'
      return yes
    if isLoggingIn?
      @_isLoggingIn = isLoggingIn
    else
      @_isLoggingIn ? no

  showInstructionsBook:->
    if Cookies.get 'newRegister'
      @emit "ShowInstructionsBook", 9
      Cookies.expire 'newRegister'
    else if @isUserLoggedIn()
      BookView::getNewPages (pages)=>
        return unless pages.length
        BookView.navigateNewPages = yes
        @emit "ShowInstructionsBook", pages.first.index

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
