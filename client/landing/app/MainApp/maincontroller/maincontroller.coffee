class MainController extends KDController

  ###

  * EMITTED EVENTS
    - AppIsReady
    - AccountChanged          [account]
    - UserIsJustLoggedIn      [account, connectedState]
    - UserIsJustLoggedOut     [account, connectedState]
  ###


  connectedState =
    connected   : no
    wasLoggedIn : no

  constructor:(options = {}, data)->

    options.failWait  = 5000            # duration in miliseconds to show a connection failed modal

    super options, data

    # window.appManager is there for backwards compatibilty
    # will be deprecated soon.
    appManager = new ApplicationManager
    window.appManager = appManager

    KD.registerSingleton "appManager", appManager
    KD.registerSingleton "mainController", @
    KD.registerSingleton "kiteController", new KiteController
    KD.registerSingleton "contentDisplayController", new ContentDisplayController
    KD.registerSingleton "notificationController", new NotificationController
    KD.registerSingleton "localStorageController", new LocalStorageController
    KD.registerSingleton "lazyDomController", new LazyDomController

    router = new KodingRouter location.pathname
    KD.registerSingleton 'router', router

    KD.registerSingleton "groupsController", appManager.create 'Groups'

    @appReady =>
      router.listen()
      KD.registerSingleton "activityController", new ActivityController
      KD.registerSingleton "kodingAppsController", new KodingAppsController
      #KD.registerSingleton "bottomPanelController", new BottomPanelController

    @setFailTimer()
    @putGlobalEventListeners()

    @accountReadyState = 0

    @appStorages = {}

  # FIXME GG
  getAppStorageSingleton:(appName, version)->
    if @appStorages[appName]?
      storage = @appStorages[appName]
    else
      storage = @appStorages[appName] = new AppStorage appName, version

    storage.fetchStorage()
    return storage

  appReady:do ->
    applicationIsReady = no
    queue = []
    (listener)->
      if listener
        if applicationIsReady then listener()
        else queue.push listener
      else
        applicationIsReady = yes
        listener() for listener in queue
        queue.length = 0

        @emit 'AppIsReady'

  accountReady:(fn)->
    if @accountReadyState > 0 then fn()
    else @once 'AccountChanged', fn

  accountChanged:(account)->

    @userAccount = account
    @accountReadyState = 1

    connectedState.connected = yes

    @emit "AccountChanged", account

    unless @mainViewController
      @mainViewController = new MainViewController
        view       : mainView = new MainView
          domId    : "kdmaincontainer"
          cssClass : "hidden"

      @loginScreen = new LoginView
      KDView.appendToDOMBody @loginScreen

      @appReady()

    @decorateBodyTag()

    if @isUserLoggedIn()
      connectedState.wasLoggedIn = yes
      @emit 'UserIsJustLoggedIn', account, connectedState
    else
      @emit 'UserIsJustLoggedOut', account, connectedState

  decorateBodyTag:->
    if KD.checkFlag 'super-admin'
      $('body').addClass 'super'
    else
      $('body').removeClass 'super'

  doJoin:->
    @loginScreen.animateToForm 'lr'

  doRegister:->
    @loginScreen.animateToForm 'register'

  doGoHome:->
    @loginScreen.animateToForm 'home'

  doLogin:->
    @loginScreen.animateToForm 'login'

  doRecover:->
    @loginScreen.animateToForm 'recover'

  doLogout:->
    KD.logout()
    KD.remote.api.JUser.logout (err, account, replacementToken)=>
      $.cookie 'clientId', replacementToken if replacementToken
      @accountChanged account
      new KDNotificationView
        cssClass  : "login"
        title     : "<span></span>Come back soon!"
        duration  : 2000
      # fixme: get rid of reload, clean up ui on account change
      # tightly related to application manager refactoring
      @utils.wait 2000, -> location.reload yes

  # goToPage:(pageInfo)=>
  #   console.log 'go to page'
  #   path = pageInfo.appPath
  #   if path is "Login"
  #     @loginScreen.showView()
  #   else
  #     KD.getSingleton("appManager").open path, yes

  putGlobalEventListeners:()->

    @on "NavigationLinkTitleClick", (pageInfo) =>
      if pageInfo.isWebTerm
        KD.getSingleton("appManager").open 'WebTerm'

    @on "ShowInstructionsBook", (index)=>
      book = @mainViewController.getView().addBook()
      book.fillPage index

  # some day we'll have this :)
  hashDidChange:(params,query)->

  setVisitor:(visitor)-> @visitor = visitor
  getVisitor: -> @visitor
  getAccount: -> KD.whoami()

  isUserLoggedIn: -> KD.whoami() instanceof KD.remote.api.JAccount

  unmarkUserAsTroll:(data)->

    kallback = (acc)=>
      acc.unflagAccount "exempt", (err, res)->
        if err then warn err
        else
          new KDNotificationView
            title : "@#{acc.profile.nickname} won't be treated as a troll anymore!"

    if data.originId
      KD.remote.cacheable "JAccount", data.originId, (err, account)->
        kallback account if account
    else if data.bongo_.constructorName is 'JAccount'
      kallback data

  markUserAsTroll:(data)->

    modal = new KDModalView
      title          : "MARK USER AS TROLL"
      content        : """
                        <div class='modalformline'>
                          This is what we call "Trolling the troll" mode.<br><br>
                          All of the troll's activity will disappear from the feeds, but the troll
                          himself will think that people still gets his posts/comments.<br><br>
                          Are you sure you want to mark him as a troll?
                        </div>
                       """
      height         : "auto"
      overlay        : yes
      buttons        :
        "YES, THIS USER IS DEFINITELY A TROLL" :
          style      : "modal-clean-red"
          loader     :
            color    : "#ffffff"
            diameter : 16
          callback   : =>
            kallback = (acc)=>
              acc.flagAccount "exempt", (err, res)->
                if err then warn err
                else
                  modal.destroy()
                  new KDNotificationView
                    title : "@#{acc.profile.nickname} marked as a troll!"

            if data.originId
              KD.remote.cacheable "JAccount", data.originId, (err, account)->
                kallback account if account
            else if data.bongo_.constructorName is 'JAccount'
              kallback data

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
            style     : "modal-clean-red"
            callback  : ()->
              modal.destroy()
              location.reload yes
      # if location.hostname is "localhost"
      #   KD.utils.wait 5000, -> location.reload yes

    checkConnectionState = ->
      fail() unless connectedState.connected
    ->
      @utils.wait @getOptions().failWait, checkConnectionState
      @on "AccountChanged", =>
        if modal
          modal.setTitle "Connection Established"
          modal.$('.modalformline').html "<b>It just connected</b>, don't worry about this warning."
          @utils.wait 2500, -> modal?.destroy()
