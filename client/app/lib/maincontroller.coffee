kd                       = require 'kd'
KDController             = kd.Controller
KDNotificationView       = kd.NotificationView
emojify                  = require 'emojify.js'
Promise                  = require 'bluebird'
kookies                  = require 'kookies'
globals                  = require 'globals'
remote                   = require('./remote').getInstance()
getGroup                 = require './util/getGroup'
setPreferredDomain       = require './util/setPreferredDomain'
logout                   = require './util/logout'
logToExternalWithTime    = require './util/logToExternalWithTime'
isLoggedIn               = require './util/isLoggedIn'
whoami                   = require './util/whoami'
checkFlag                = require './util/checkFlag'
setVersionCookie         = require './util/setVersionCookie'
ActivityController       = require './activitycontroller'
AppStorageController     = require './appstoragecontroller'
ApplicationManager       = require './applicationmanager'
ComputeController        = require './providers/computecontroller'
ContentDisplayController = require './contentdisplay/contentdisplaycontroller'
GroupsController         = require './maincontroller/groupscontroller'
HelpController           = require './maincontroller/helpcontroller'
IdleUserDetector         = require './idleuserdetector'
KiteCache                = require './kite/kitecache'
KodingAppsController     = require './kodingappscontroller'
KodingKontrol            = require './kite/kodingkontrol'
KodingRouter             = require './kodingrouter'
LinkController           = require './linkcontroller'
LocalStorage             = require './localstorage'
LocalStorageController   = require './localstoragecontroller'
LocalSyncController      = require './localsynccontroller'
LocationController       = require './locationcontroller'
MainView                 = require './mainview'
MainViewController       = require './mainviewcontroller'
NotificationController   = require './notificationcontroller'
OAuthController          = require './oauthcontroller'
OnboardingController     = require './onboarding/onboardingcontroller'
PaymentController        = require './payment/paymentcontroller'
RealtimeController       = require './realtimecontroller'
SearchController         = require './searchcontroller'
SocialApiController      = require './socialapicontroller'
WelcomeModal             = require './welcomemodal'
WidgetController         = require './widgetcontroller'
PageTitleController      = require './pagetitlecontroller'
ShortcutsController      = require './shortcutscontroller'

module.exports =

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

    @detectIdleUser()
    @startCachingAssets()  unless globals.isLoggedInOnLoad

    @welcomeUser()

    emojify?.setConfig
      img_dir      : 'https://s3.amazonaws.com/koding-cdn/emojis'
      ignored_tags :
        'TEXTAREA' : 1,
        'A'        : 1,
        'PRE'      : 1,
        'CODE'     : 1

  welcomeUser : ->

    return unless isLoggedIn()

    {appStorageController} = kd.singletons
    storage                = appStorageController.storage 'WelcomeModal', '1.0.0'

    storage.fetchStorage (_storage) =>

      return if storage.getValue('shownBefore')

      account = whoami()

      registrationDate = new Date(account.meta.createdAt)
      releaseDate      = new Date("Oct 02 2014")

      if registrationDate < releaseDate

        storage.setValue 'shownBefore', 'true'

        return new WelcomeModal


  createSingletons:->

    kd.registerSingleton 'mainController',            this

    kd.registerSingleton 'kontrol',                   new KodingKontrol

    kd.registerSingleton 'appManager',   appManager = new ApplicationManager
    kd.registerSingleton 'notificationController',    new NotificationController
    kd.registerSingleton 'linkController',            new LinkController
    kd.registerSingleton 'display',                   new ContentDisplayController
    kd.registerSingleton 'router',           router = new KodingRouter
    kd.registerSingleton 'localStorageController',    new LocalStorageController
    kd.registerSingleton 'oauthController',           new OAuthController
    kd.registerSingleton 'groupsController',          new GroupsController
    kd.registerSingleton 'activityController',        new ActivityController
    kd.registerSingleton 'paymentController',         new PaymentController
    kd.registerSingleton 'computeController',         new ComputeController
    kd.registerSingleton 'locationController',        new LocationController
    kd.registerSingleton 'helpController',            new HelpController
    kd.registerSingleton 'appStorageController',      new AppStorageController
    kd.registerSingleton 'localSync',                 new LocalSyncController
    kd.registerSingleton 'mainView',             mv = new MainView
    kd.registerSingleton 'mainViewController',  mvc = new MainViewController view : mv
    kd.registerSingleton 'kodingAppsController',      new KodingAppsController
    kd.registerSingleton 'socialapi',                 new SocialApiController
    kd.registerSingleton 'realtime',                  new RealtimeController
    kd.registerSingleton 'pageTitle',                 new PageTitleController
    kd.registerSingleton 'shortcuts',     shortcuts = new ShortcutsController

    shortcuts.addEventListeners()

    router.listen()

    @mainViewController = mvc

    mv.appendToDomBody()

    @ready =>
      kd.registerSingleton 'search',                  new SearchController
      kd.registerSingleton 'widgetController',        new WidgetController
      kd.registerSingleton 'onboardingController',    new OnboardingController

      @emit 'AppIsReady'

      @prepareSupportShortcuts()

    @forwardEvents remote, ['disconnected', 'reconnected']


  isFeatureDisabled: (name) ->

    return no  if checkFlag 'super-admin'
    return no  unless name

    {roles}            = globals.config
    {disabledFeatures} = getGroup()

    return no  unless disabledFeatures

    role = 'member'    if 'member'    in roles
    role = 'moderator' if 'moderator' in roles
    role = 'admin'     if 'admin'     in roles

    return no   if !disabledFeatures[role]
    return yes  if disabledFeatures[role] and name in disabledFeatures[role]

    return no



  accountChanged: (account, firstLoad = no)->

    unless account instanceof remote.api.JAccount
      account = remote.revive account

    # this is last guard that we can take for guestuser issue ~ GG
    if account.profile?.nickname is "guestuser"
      kookies.expire 'clientId'
      global.location.href = '/'
      return

    globals.userAccount = account
    connectedState.connected = yes

    @on 'pageLoaded.as.loggedIn', (account)-> # ignore othter parameters
      setPreferredDomain account if account

    unless firstLoad
      (kd.getSingleton 'kontrol').reauthenticate()

    account.fetchMyPermissionsAndRoles (err, res)=>

      return kd.warn err  if err

      globals.config.roles       = res.roles
      globals.config.permissions = res.permissions

      tzOffset = (new Date()).getTimezoneOffset()

      account.setLastLoginTimezoneOffset lastLoginTimezoneOffset: tzOffset, (err) ->

        kd.warn err  if err


      @ready @emit.bind this, "AccountChanged", account, firstLoad

      @emit 'ready'

      # this emits following events
      # -> "pageLoaded.as.loggedIn"
      # -> "pageLoaded.as.loggedOut"
      # -> "accountChanged.to.loggedIn"
      # -> "accountChanged.to.loggedOut"
      eventPrefix = if firstLoad then "pageLoaded.as" else "accountChanged.to"
      eventSuffix = if isLoggedIn() then "loggedIn" else "loggedOut"
      @emit "#{eventPrefix}.#{eventSuffix}", account, connectedState, firstLoad

  doLogout: ->

    mainView = kd.getSingleton 'mainView'

    logout()

    storage = new LocalStorage 'Koding', '1.0'

    KiteCache.clearAll()

    remote.api.JUser.logout (err) =>

      mainView._logoutAnimation()
      kd.singletons.localSync.removeLocalContents()

      kookies.expire 'koding082014'
      kookies.expire 'useOldKoding'
      kookies.expire 'clientId'
      kookies.expire 'realtimeToken'

      wc = kd.singleton 'windowController'
      wc.clearUnloadListeners()

      kd.utils.wait 1000, =>
        @swapAccount replacementAccount: null
        storage.setValue 'loggingOut', '1'
        global.location.href = '/'


  attachListeners:->
    # @on 'pageLoaded.as.(loggedIn|loggedOut)', (account)=>
    #   log "pageLoaded", isLoggedIn()

    # TODO: this is a kludge we needed.  sorry for this.  Move it someplace better C.T.
    wc = kd.singleton 'windowController'
    kd.utils.wait 15000, ->
      remote.api?.JSystemStatus.on 'forceReload', ->
        global.removeEventListener 'beforeunload', wc.bound 'beforeUnload'
        global.location.reload yes

    # async clientId change checking procedures causes
    # race conditions between window reloading and post-login callbacks
    cookieChangeHandler = do (cookie = kookies.get 'clientId') => =>
      cookieExists      = cookie?
      cookieMatches     = cookie is (kookies.get 'clientId')

      if not cookieExists or (cookieExists and not cookieMatches)
        global.location.href = '/'

      kd.utils.wait 1000, cookieChangeHandler

    # Note: I am using wait instead of repeat, for the subtle difference.  See this StackOverflow answer for more info:
    #       http://stackoverflow.com/questions/729921/settimeout-or-setinterval/731625#731625
    kd.utils.wait 1000, cookieChangeHandler

  swapAccount: (options, callback) ->
    return { message: 'Login failed!' } unless options

    { account, replacementToken } = options

    { maxAge, secure } = globals.config.sessionCookie

    if replacementToken and replacementToken isnt kookies.get 'clientId'
      kookies.set 'clientId', replacementToken, { maxAge, secure }
      global.location.href= '/'

    if account
      @accountChanged account
      if callback
        @once 'AccountChanged', (account) -> callback null, options

  handleLogin: (credentials, callback) ->
    { JUser } = remote.api

    @isLoggingIn on

    credentials.username = credentials.username.toLowerCase().trim()

    JUser.login credentials, (err, result) =>
      return callback err  if err
      setVersionCookie result.account
      @swapAccount result, callback


  handleOauthAuth : (formData, callback)->
    { JUser } = remote.api

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
        click         : -> global.location.reload yes

    useChrome = ->

      notification = new KDNotificationView
        title         : "Please use Google Chrome"
        type          : "tray"
        closeManually : no
        content       : """Since Safari 8.0.5 update we are having difficulties connecting to our backend.
                           <br>Please use another browser until we fix the ongoing issue."""
        duration      : 0

    checkConnectionState = ->
      unless connectedState.connected
        logToExternalWithTime "Connect to backend"

        {userAgent} = global.navigator
        isSafari    = /Safari/.test userAgent
        notChrome   = not /Chrome/.test userAgent

        if isSafari and notChrome
        then useChrome()
        else fail()

    return ->
      kd.utils.wait @getOptions().failWait, checkConnectionState
      @on "AccountChanged", -> notification.destroy()  if notification

  detectIdleUser: (threshold = globals.config.userIdleMs) ->
    idleDetector = new IdleUserDetector { threshold }
    @forwardEvents idleDetector, ['userIdle', 'userBack']

  prepareSupportShortcuts: ->

    return  unless checkFlag ['super-admin']

    kd.impersonate = require './util/impersonate'
    kd.remote      = remote
    kd.whoami      = whoami

  startCachingAssets:->

    kd.singletons.appManager.require 'Login', ->

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


