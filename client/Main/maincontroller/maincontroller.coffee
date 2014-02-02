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

    @introductionTooltipController = new IntroductionTooltipController

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
    KD.registerSingleton "vmController",              new VirtualizationController
    KD.registerSingleton "paymentController",         new PaymentController
    KD.registerSingleton "locationController",        new LocationController
    KD.registerSingleton "badgeController",           new BadgeController
    KD.registerSingleton "helpController",            new HelpController


    # appManager.create 'Chat', (chatController)->
    #   KD.registerSingleton "chatController", chatController

    @ready =>
      router.listen()
      KD.registerSingleton "activityController",      new ActivityController
      KD.registerSingleton "appStorageController",    new AppStorageController
      KD.registerSingleton "kodingAppsController",    new KodingAppsController
      # KD.registerSingleton "kontrol",                 new Kontrol

      # @showInstructionsBook()
      @emit 'AppIsReady'

      console.timeEnd "Koding.com loaded"

  accountChanged:(account, firstLoad = no)->
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

      KD.utils.wait 5000, =>
        if KD.isLoggedIn()
          KD.remote.api.JReferral.isCampaingValid (err, isValid, details) =>
            return if err or not isValid

            new TBCampaignController {}, details

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
        $.cookie 'clientId', replacementToken  if replacementToken
        storage.setValue 'loggingOut', '1'
        location.reload()

  oldCookie = $.cookie
  cookieChanges = []
  $.cookie = (name, val) ->
    if val?
      cookieChanges.push (new Error).stack
    oldCookie.apply this, arguments

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
    @utils.repeat 3000, do (cookie = $.cookie 'clientId') => =>
      cookieExists = cookie?
      cookieMatches = cookie is ($.cookie 'clientId')
      cookie = $.cookie 'clientId'

      if cookieExists and not cookieMatches
        KD.logToExternal "cookie changes", {stackTraces:cookieChanges, username:KD.nick()}

        return @isLoggingIn off  if @isLoggingIn() is on

        KD.logToExternal "cookie changes", {stackTraces:cookieChanges, username:KD.nick(), inlogin:true}

        window.removeEventListener 'beforeunload', wc.bound 'beforeUnload'
        @emit "clientIdChanged"

        # window location path is set to last route to ensure visitor is not
        # redirected to another page
        @utils.defer ->
          lastRoute = KD.getSingleton("router").visitedRoutes.last

          lastRoute = KD.getSingleton("router").visitedRoutes.last
          if lastRoute and /^\/(?:Reset|Register|Verify|Confirm)\//.test lastRoute
            lastRoute = "/Activity"

          {entryPoint} = KD.config
          KD.getSingleton('router').handleRoute lastRoute or '/Activity', {replaceState: yes, entryPoint}

  setVisitor:(visitor)-> @visitor = visitor
  getVisitor: -> @visitor
  getAccount: -> KD.whoami()

  swapAccount: (options, callback) ->
    return { message: 'Login failed!' } unless options

    { account, replacementToken } = options

    $.cookie 'clientId', replacementToken  if replacementToken

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
    if $.cookie 'newRegister'
      @emit "ShowInstructionsBook", 9
      $.cookie 'newRegister', erase: yes
    else if @isUserLoggedIn()
      BookView::getNewPages (pages)=>
        return unless pages.length
        BookView.navigateNewPages = yes
        @emit "ShowInstructionsBook", pages.first.index

  setFailTimer: do->
    modal = null
    fail  = ->
      modal = new KDBlockingModalView
        title   : "Couldn't connect to the backend!"
        content : "<div class='modalformline'>
                     We don't know why, but your browser couldn't reach our server.<br><br>Please try again.
                   </div>"
        height  : "auto"
        width   : 600
        overlay : yes
        buttons :
          "Refresh Now" :
            style       : "modal-clean-red"
            callback    : ->
              modal.destroy()
              location.reload yes
      # if location.hostname is "localhost"
      #   KD.utils.wait 5000, -> location.reload yes

    checkConnectionState = ->
      unless connectedState.connected
        KD.logToExternalWithTime "Connect to backend"
        fail()

    return ->
      @utils.wait @getOptions().failWait, checkConnectionState
      @on "AccountChanged", =>
        if modal
          modal.setTitle "Connection Established"
          modal.$('.modalformline').html "<b>It just connected</b>, don't worry about this warning."
          modal.buttons["Refresh Now"].destroy()

          @utils.wait 2500, -> modal?.destroy()
