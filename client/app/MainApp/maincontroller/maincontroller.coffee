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

  connectedState =
    connected   : no

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
    KD.registerSingleton "kiteController",            new KiteController
    KD.registerSingleton "vmController",              new VirtualizationController
    KD.registerSingleton "contentDisplayController",  new ContentDisplayController
    KD.registerSingleton "notificationController",    new NotificationController
    KD.registerSingleton "paymentController",         new PaymentController
    KD.registerSingleton "linkController",            new LinkController
    KD.registerSingleton 'router',           router = new KodingRouter
    KD.registerSingleton "localStorageController",    new LocalStorageController
    KD.registerSingleton "oauthController",           new OAuthController
    # KD.registerSingleton "fatih", new Fatih

    appManager.create 'Groups', (groupsController)->
      KD.registerSingleton "groupsController", groupsController

    appManager.create 'Chat', (chatController)->
      KD.registerSingleton "chatController", chatController

    @ready =>
      router.listen()
      KD.registerSingleton "activityController",      new ActivityController
      KD.registerSingleton "appStorageController",    new AppStorageController
      KD.registerSingleton "kodingAppsController",    new KodingAppsController
      @showInstructionsBookIfNeeded()
      @emit 'AppIsReady'

      console.timeEnd "Koding.com loaded"

  accountChanged:(account, firstLoad = no)->
    @userAccount             = account
    connectedState.connected = yes

    account.fetchMyPermissionsAndRoles (err, permissions, roles)=>
      return warn err  if err
      KD.config.roles       = roles
      KD.config.permissions = permissions

      @ready @emit.bind this, "AccountChanged", account, firstLoad

      @createMainViewController()  unless @mainViewController

      @decorateBodyTag()
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
    @loginScreen = new LoginView
      testPath   : "landing-login"
    @loginScreen.appendToDomBody()
    @mainViewController  = new MainViewController
      view    : mainView = new MainView
        domId : "kdmaincontainer"
    mainView.appendToDomBody()

  doLogout:->

    KD.logout()
    KD.remote.api.JUser.logout (err, account, replacementToken)=>
      $.cookie 'clientId', replacementToken if replacementToken
      location.reload()

    # fixme: make a old tv switch off animation and reload
    # $('body').addClass "turn-off"

  attachListeners:->

    # @on 'pageLoaded.as.(loggedIn|loggedOut)', (account)=>
    #   log "pageLoaded", @isUserLoggedIn()

    # TODO: this is a kludge we needed.  sorry for this.  Move it someplace better C.T.
    wc = @getSingleton 'windowController'
    @utils.wait 15000, ->
      KD.remote.api?.JSystemStatus.on 'forceReload', ->
        window.removeEventListener 'beforeunload', wc.bound 'beforeUnload'
        location.reload()

    # async clientId change checking procedures causes
    # race conditions between window reloading and post-login callbacks
    @utils.repeat 1000, do (cookie = $.cookie 'clientId') => =>
      if cookie? and cookie isnt $.cookie 'clientId'
        window.removeEventListener 'beforeunload', wc.bound 'beforeUnload'
        @emit "clientIdChanged"

        # window location path is set to last route to ensure visitor is not
        # redirected to another page
        @utils.defer -> window.location.pathname = KD.getSingleton("router").visitedRoutes.first or "/"
      cookie = $.cookie 'clientId'



  # some day we'll have this :)
  hashDidChange:(params,query)->

  setVisitor:(visitor)-> @visitor = visitor
  getVisitor: -> @visitor
  getAccount: -> KD.whoami()

  isUserLoggedIn: -> KD.whoami() instanceof KD.remote.api.JAccount

  showInstructionsBookIfNeeded:->
    if $.cookie 'newRegister'
      @emit "ShowInstructionsBook", 9
      $.cookie 'newRegister', erase: yes

  decorateBodyTag:->
    if KD.checkFlag 'super-admin'
    then $('body').addClass 'super'
    else $('body').removeClass 'super'

  setFailTimer: do->
    modal = null
    fail  = ->
      modal = new KDBlockingModalView
        title   : "Couldn't connect to the backend!"
        content : "<div class='modalformline'>
                     We don't know why, but your browser couldn't reach our server.<br><br>Please try again.
                   </div>"
        height  : "auto"
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
        fail()

    return ->
      @utils.wait @getOptions().failWait, checkConnectionState
      @on "AccountChanged", =>
        KD.track "Connected to backend"

        if modal
          modal.setTitle "Connection Established"
          modal.$('.modalformline').html "<b>It just connected</b>, don't worry about this warning."
          modal.buttons["Refresh Now"].destroy()

          @utils.wait 2500, -> modal?.destroy()
