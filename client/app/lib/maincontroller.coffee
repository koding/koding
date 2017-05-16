kd                     = require 'kd'
kookies                = require 'kookies'
globals                = require 'globals'
remote                 = require './remote'
checkGuestUser         = require './util/checkGuestUser'
getGroup               = require './util/getGroup'
setPreferredDomain     = require './util/setPreferredDomain'
isLoggedIn             = require './util/isLoggedIn'
checkFlag              = require './util/checkFlag'
expireClientId         = require './util/expireClientId'
AppStorageController   = require './appstoragecontroller'
ApplicationManager     = require './applicationmanager'
ComputeController      = require './providers/computecontroller'
GroupsController       = require './maincontroller/groupscontroller'
KiteCache              = require './kite/kitecache'
KodingAppsController   = require './kodingappscontroller'
KodingKontrol          = require './kite/kodingkontrol'
KodingRouter           = require './kodingrouter'
LinkController         = require './linkcontroller'
LocalStorage           = require './localstorage'
LocalStorageController = require './localstoragecontroller'
LocalSyncController    = require './localsynccontroller'
MainView               = require './mainview'
MainViewController     = require './mainviewcontroller'
NotificationController = require './notificationcontroller'
OAuthController        = require './oauthcontroller'
OnboardingController   = require './onboarding/onboardingcontroller'
RealtimeController     = require './realtimecontroller'
SearchController       = require './searchcontroller'
SocialApiController    = require './socialapicontroller'
PageTitleController    = require './pagetitlecontroller'
ShortcutsController    = require './shortcutscontroller'
SidebarController      = require './sidebarcontroller'
KodingFluxReactor      = require './flux/base/reactor'
bowser                 = require 'bowser'
fetchChatlioKey        = require 'app/util/fetchChatlioKey'
createStore            = require './redux/createStore'

NotificationViewController  = require './notificationviewcontroller'

dispatchInitialActions = require './redux/dispatchInitialActions'

module.exports = class MainController extends kd.Controller

  ###

  * EMITTED EVENTS
    - AppIsReady
    - AccountChanged                [account, firstLoad]
    - pageLoaded.as.loggedIn        [account, connectedState, firstLoad]
    - pageLoaded.as.loggedOut       [account, connectedState, firstLoad]
    - accountChanged.to.loggedIn    [account, connectedState, firstLoad]
    - accountChanged.to.loggedOut   [account, connectedState, firstLoad]

  ###

  connectedState = { connected : no }

  constructor: (options = {}, data) ->

    options.failWait = 10000            # duration in miliseconds to show a connection failed modal

    super options, data

    @appStorages = {}

    @createSingletons()
    @setFailTimer()
    @attachListeners()

    @setTeamCookie()

    @setElektronHandlers()


  createSingletons: ->

    kd.registerSingleton 'mainController',            this
    kd.registerSingleton 'kontrol',                   new KodingKontrol
    kd.registerSingleton 'appManager',   appManager = new ApplicationManager
    kd.registerSingleton 'store',             store = createStore()
    kd.registerSingleton 'notificationController',    new NotificationController
    kd.registerSingleton 'linkController',            new LinkController
    kd.registerSingleton 'router',           router = new KodingRouter
    kd.registerSingleton 'localStorageController',    new LocalStorageController
    kd.registerSingleton 'oauthController',           new OAuthController
    kd.registerSingleton 'groupsController',          new GroupsController
    kd.registerSingleton 'computeController',         new ComputeController
    kd.registerSingleton 'appStorageController',      new AppStorageController
    kd.registerSingleton 'localSync',                 new LocalSyncController
    kd.registerSingleton 'mainView',             mv = new MainView
    kd.registerSingleton 'mainViewController',  mvc = new MainViewController { view : mv }
    kd.registerSingleton 'kodingAppsController',      new KodingAppsController
    kd.registerSingleton 'socialapi',                 new SocialApiController
    kd.registerSingleton 'realtime',                  new RealtimeController
    kd.registerSingleton 'pageTitle',                 new PageTitleController
    kd.registerSingleton 'shortcuts',     shortcuts = new ShortcutsController
    kd.registerSingleton 'sidebar',                   new SidebarController
    kd.registerSingleton 'onboarding',                new OnboardingController
    kd.registerSingleton 'reactor',                   new KodingFluxReactor

    kd.registerSingleton 'notificationViewController', new NotificationViewController

    @registerFluxModules()

    shortcuts.addEventListeners()

    router.listen()

    @mainViewController = mvc

    mv.appendToDomBody()

    @ready =>
      kd.registerSingleton 'search',                  new SearchController

      @emit 'AppIsReady'

      dispatchInitialActions store
      @prepareSupportShortcuts()

    @forwardEvents remote, ['disconnected', 'reconnected']


  isFeatureDisabled: (name, callback) -> @ready -> callback do ->

    return no  unless name
    return no  if checkFlag 'super-admin'

    { roles }            = globals.config
    { disabledFeatures } = getGroup()

    return no  unless disabledFeatures

    role = 'member'    if 'member'    in roles
    role = 'moderator' if 'moderator' in roles
    role = 'admin'     if 'admin'     in roles

    return no   unless disabledFeatures[role]
    return yes  if disabledFeatures[role] and name in disabledFeatures[role]

    return no


  accountChanged: (account, firstLoad = no) ->

    unless account instanceof remote.api.JAccount
      account = remote.revive account

    clientExpirationValidators = [checkGuestUser, checkLoggedOut]
    for validator in clientExpirationValidators when validator account
      return expireClientId()

    matchIds = account._id is globals.userAccount?._id
    return  if not firstLoad and matchIds

    globals.userAccount = account
    connectedState.connected = yes

    @on 'pageLoaded.as.loggedIn', (account) -> # ignore othter parameters
      setPreferredDomain account if account

    unless firstLoad
      (kd.getSingleton 'kontrol').reauthenticate()

    @ready @emit.bind this, 'AccountChanged', account, firstLoad

    @emit 'ready'

    # this emits following events
    # -> "pageLoaded.as.loggedIn"
    # -> "pageLoaded.as.loggedOut"
    # -> "accountChanged.to.loggedIn"
    # -> "accountChanged.to.loggedOut"
    eventPrefix = if firstLoad then 'pageLoaded.as' else 'accountChanged.to'
    eventSuffix = if isLoggedIn() then 'loggedIn' else 'loggedOut'
    @emit "#{eventPrefix}.#{eventSuffix}", account, connectedState, firstLoad


  doLogout: ->

    mainView = kd.getSingleton 'mainView'

    @isLoggingIn on
    delete globals.userAccount

    storage = new LocalStorage 'Koding', '1.0'

    KiteCache.clearAll()

    kd.singletons.onboarding.stop()

    remote.api.JUser.logout (err) =>

      mainView._logoutAnimation()
      kd.singletons.localSync.removeLocalContents()

      kookies.expire 'koding082014'
      kookies.expire 'useOldKoding'
      kookies.expire 'clientId'
      kookies.expire 'realtimeToken'

      wc = kd.singleton 'windowController'
      wc.clearUnloadListeners()

      window.Intercom? 'shutdown'

      kd.utils.wait 1000, =>
        @swapAccount { replacementAccount: null }
        storage.setValue 'loggingOut', '1'
        global.location.href = '/'


  attachListeners: ->
    # async clientId change checking procedures causes
    # race conditions between window reloading and post-login callbacks
    cookieChangeHandler = do (cookie = kookies.get 'clientId') -> ->
      cookieExists      = cookie?
      cookieMatches     = cookie is (kookies.get 'clientId')

      if not cookieExists or (cookieExists and not cookieMatches)
        return global.location.href = '/'

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
      global.location.href = '/'

    if account
      @accountChanged account
      if callback
        @once 'AccountChanged', (account) -> callback null, options


  handleOauthAuth : (formData, callback) ->
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


  setFailTimer: do ->
    notification = null
    fail  = ->

      notification = new kd.NotificationView
        title         : "Couldn't connect to backend!"
        cssClass      : 'disconnected'
        type          : 'tray'
        closeManually : no
        content       : """We don't know why, but your browser couldn't reach our server.
                           <br>Still trying but if you want you can click here to refresh the page."""
        duration      : 0
        click         : -> global.location.reload yes

    useChrome = ->

      notification = new kd.NotificationView
        title         : 'Please use Google Chrome'
        type          : 'tray'
        closeManually : no
        content       : '''Since Safari 8.0.5 update we are having difficulties connecting to our backend.
                           <br>Please use another browser until we fix the ongoing issue.'''
        duration      : 0

    checkConnectionState = ->
      unless connectedState.connected
        if bowser.safari
        then useChrome()
        else fail()

    return ->
      kd.utils.wait @getOptions().failWait, checkConnectionState
      @on 'AccountChanged', -> notification.destroy()  if notification


  prepareSupportShortcuts: ->

    return  unless checkFlag ['super-admin']

    kd.impersonate = require './util/impersonate'
    kd.remote      = remote
    kd.whoami      = require './util/whoami'


  tellChatlioWidget: (method, options, callback = kd.noop) ->

    fetchChatlioKey (id) ->

      return callback new Error 'Support isn\'t enabled by your team admin!'  unless id

      run = -> callback null, window._chatlio[method] options

      if window._chatlio
      then do run
      else document.addEventListener 'chatlio.ready', run



  registerFluxModules: ->

    fluxModules = [
      require 'app/flux'
      require 'app/flux/environment'
      require 'app/flux/teams'
      require 'home/flux'
    ]

    fluxModules.forEach (fluxModule) ->
      fluxModule.register kd.singletons.reactor


  # this cookie is set when someone logs into a team
  # then on /Teams at team selector page
  # we check the cookies and show shortcuts to
  # users' teams when they want to login to their teams
  setTeamCookie: ->

    { groupsController } = kd.singletons
    groupsController.ready ->
      group = groupsController.getCurrentGroup()

      try
        teams = JSON.parse kookies.get 'koding-teams'

      teams ?= {}

      domain = location.hostname.replace ///#{group.slug}\.///, ''
      path   = '/'
      # domain         = ".#{parentHostname}"
      { maxAge }     = globals.config.sessionCookie

      teams[group.slug] = group.title
      teams.latest      = group.slug

      kookies.set 'koding-teams', JSON.stringify(teams), { domain, maxAge, path }


  setElektronHandlers: ->

    return  unless window.nodeRequire

    { ipcRenderer } = nodeRequire 'electron'

    ipcRenderer.on 'get-previous-teams', =>
      ipcRenderer.send 'answer-previous-teams', @getPreviousTeams()


  getPreviousTeams: ->

    try
      teams = JSON.parse kookies.get 'koding-teams'

    return teams  if teams and Object.keys(teams).length
    return null


  useOldStackEditor: (use = no) ->

    if use
      Cookies.set 'use-ose', yes, { path:'/' }
    else
      Cookies.expire 'use-ose', { path:'/' }

    global.location.reload yes


# This function compares type of given account with global user
# account to determine whether user is logged out or not.
checkLoggedOut = (account) ->
  return no  unless globals.userAccount

  if globals.userAccount.type is 'registered'
    if account.type is 'unregistered'
      return yes
