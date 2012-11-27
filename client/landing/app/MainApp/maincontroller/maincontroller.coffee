class MainController extends KDController

  connectedState =
    connected   : no
    wasLoggedIn : no

  constructor:(options = {}, data)->

    options.failWait  = 5000            # duration in miliseconds to show a connection failed modal
    options.startPage = "Demos"         # start page path

    super options, data

    window.appManager = new ApplicationManager
    KD.registerSingleton "mainController", @
    KD.registerSingleton "kiteController", new KiteController
    KD.registerSingleton "contentDisplayController", new ContentDisplayController
    KD.registerSingleton "notificationController", new NotificationController

    @appReady ->

      KD.registerSingleton "activityController", new ActivityController
      KD.registerSingleton "kodingAppsController", new KodingAppsController
      KD.registerSingleton "bottomPanelController", new BottomPanelController

    @setFailTimer()
    @putGlobalEventListeners()

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
        @getSingleton('mainView').removeLoader()
        queue.length = 0

  getUserArea:-> @userArea

  setUserArea:(userArea)->
    @emit 'UserAreaChanged', userArea  if not _.isEqual(userArea, @userArea)
    @userArea = userArea

  getGroup:-> @userArea?.group

  setGroup:(group)->
    @emit 'GroupChanged', group
    @setUserArea {
      group, user: KD.whoami().getAt('profile.nickname')
    }

  resetUserArea:()->
    @setUserArea {
      group: 'koding', user: KD.whoami().profile.nickname
    }

  accountChanged:(account)->
    connectedState.connected = yes

    @emit "RemoveFailModal"
    @emit "AccountChanged", account

    @userAccount = account
    @resetUserArea()

    do => # router nonsense:
      oldRouter = @router ? KD.getSingleton 'router'            # take note of the old router
      oldRouter.stopListening()  if oldRouter?                  # disable the old router
      @router = new KodingRouter location.pathname              # instantiate the new router
      shouldOverride = oldRouter?                               # we need to "override" if the old router exists
      KD.registerSingleton 'router', @router, shouldOverride    # (re)register the singleton

    unless @mainViewController
      @loginScreen = new LoginView
      KDView.appendToDOMBody @loginScreen
      @mainViewController = new MainViewController
        view    : mainView = new MainView
          domId : "kdmaincontainer"
      @appReady()

    if KD.checkFlag 'super-admin'
      $('body').addClass 'super'
    else
      $('body').removeClass 'super'

    if @isUserLoggedIn()
      appManager.quitAll =>
        @createLoggedInState account
    else
      @createLoggedOutState account

  createLoggedOutState:(account)->

    if connectedState.wasLoggedIn
      @loginScreen.slideDown =>
        appManager.quitAll =>
          @mainViewController.sidebarController.accountChanged account
          # appManager.openApplication "Home"
          @mainViewController.getView().decorateLoginState no
    else
      @mainViewController.sidebarController.accountChanged account
      # appManager.openApplication "Home"
      @mainViewController.getView().decorateLoginState no
      @loginScreen.slideDown()


  createLoggedInState:(account)->

    connectedState.wasLoggedIn = yes
    mainView = @mainViewController.getView()
    @loginScreen.slideUp =>
      @mainViewController.sidebarController.accountChanged account
      #appManager.openApplication @getOptions().startPage, yes
      @mainViewController.getView().decorateLoginState yes

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
  #     @loginScreen.slideDown()
  #   else
  #     appManager.openApplication path, yes

  putGlobalEventListeners:()->

    @on "NavigationLinkTitleClick", (pageInfo) =>
      @router.handleRoute pageInfo.path

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
            # debugger
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

    checkConnectionState = ->
      fail() unless connectedState.connected
    ->
      @utils.wait @getOptions().failWait, checkConnectionState
      @on "RemoveFailModal", =>
        if modal
          modal.setTitle "Connection Established"
          modal.$('.modalformline').html "<b>It just connected</b>, don't worry about this warning."
          @utils.wait 2500, -> modal?.destroy()
