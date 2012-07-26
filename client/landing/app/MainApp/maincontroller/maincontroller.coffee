class MainController extends KDController

  wasLoggedIn = no

  constructor:()->
    
    super

    window.appManager = new ApplicationManager
    KD.registerSingleton "docManager", new DocumentManager
    KD.registerSingleton "windowController", new KDWindowController
    KD.registerSingleton "contentDisplayController", new ContentDisplayController
    KD.registerSingleton "mainController", @
    KD.registerSingleton "kodingAppsController", new KodingAppsController
    KD.registerSingleton "notificationController", new NotificationController
    @appReady ->
      KD.registerSingleton "activityController", new ActivityController

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
        queue = []

  authorizeServices:(callback)->
    KD.whoami().fetchNonce (nonce)->
      $.ajax
        url       : KD.apiUri+"/1.0/login"
        data      :
          n       : nonce
          env     : KD.env
        xhrFields :
          withCredentials: yes

  deauthorizeServices:(callback)->
    KD.whoami().fetchNonce (nonce)->
      $.ajax
        url       : KD.apiUri+'/1.0/logout'
        data      :
          n       : nonce
          env     : KD.env
        xhrFields :
          withCredentials: yes
  
  initiateApplication:do->
    fail =->
      modal = new KDBlockingModalView
        title   : "Couldn't connect to the backend!"
        content : "<div class='modalformline'>
                     We don't know why, but your browser couldn't reach our server.<br><br>Please try again.</div>"
        height  : "auto"
        overlay : yes
        buttons :
          "Refresh Now" :
            style     : "modal-clean-red"
            callback  : ()->
              modal.destroy()
              location.reload yes
    
    connectionFails =(connectedState)->
      fail() unless connectedState.connected
    ->
      KD.registerSingleton "kiteController", new KiteController
      connectedState = connected: no
      setTimeout connectionFails.bind(null, connectedState), 5000
      @getVisitor().on 'change.login', (account)=> @accountChanged account, connectedState
      @getVisitor().on 'change.logout', (account)=> @accountChanged account, connectedState

  accountChanged:(account, connectedState)->
    
    connectedState.connected = yes
    
    @emit "AccountChanged", account

    KDRouter.init()
    unless @mainViewController
      @loginScreen = new LoginView
      KDView.appendToDOMBody @loginScreen
      @mainViewController = new MainViewController
        view    : mainView = new MainView
          domId : "kdmaincontainer"
      @appReady()

    if @isUserLoggedIn()
      appManager.quitAll =>
        @createLoggedInState account
      @authorizeServices =>
        account = KD.whoami()
        unless account.getAt('isEnvironmentCreated')
          @getSingleton('kiteController').createSystemUser (err)=>
            if err
              new KDNotificationView
                title   : 'Fail!'
                duration: 1000
            else
              account.update $set: isEnvironmentCreated: yes, (err)->
                if err
                  console.log err
                else
                  console.log "environment is created for #{account.getAt('profile.nickname')}"

    else
      @createLoggedOutState account
      @deauthorizeServices()
    # @getView().removeLoader()

  createLoggedOutState:(account)->

    if wasLoggedIn
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
    wasLoggedIn = yes
    mainView = @mainViewController.getView()
    @loginScreen.slideUp =>
      @mainViewController.sidebarController.accountChanged account
      # appManager.openApplication "Activity", yes
      appManager.openApplication "Demos", yes
      @mainViewController.getView().decorateLoginState yes

  goToPage:(pageInfo)=>

    path = pageInfo.appPath
    if path is "Login"
      @loginScreen.slideDown()
    else
      appManager.openApplication path, yes

  putGlobalEventListeners:()->

    @listenTo
      KDEventTypes : "KDBackendConnectedEvent"
      callback     : ()=>
        @initiateApplication()

    @on "NavigationLinkTitleClick", (pageInfo) =>
      if pageInfo.pageName is 'Logout'
        bongo.api.JUser.logout ->
          new KDNotificationView
            cssClass  : "login"
            title     : "<span></span>Come back soon!"
            duration  : 2000
      else
        @goToPage pageInfo

    @on "ShowInstructionsBook", (index)=>
      book = @mainViewController.getView().addBook()
      book.fillPage index


  # some day we'll have this :)
  hashDidChange:(params,query)->

  setVisitor:(visitor)-> @visitor = visitor
  getVisitor: -> @visitor
  getAccount: -> @getVisitor().currentDelegate

  isUserLoggedIn: -> @getVisitor().currentDelegate instanceof bongo.api.JAccount
