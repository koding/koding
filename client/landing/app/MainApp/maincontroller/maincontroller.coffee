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

  # authorizeServices:(callback)->
  #   KD.whoami().fetchNonce (nonce)->
  #     $.ajax
  #       url       : KD.apiUri+"/1.0/login"
  #       data      :
  #         n       : nonce
  #         env     : KD.env
  #       xhrFields :
  #         withCredentials: yes

  # deauthorizeServices:(callback)->
  #   KD.whoami().fetchNonce (nonce)->
  #     $.ajax
  #       url       : KD.apiUri+'/1.0/logout'
  #       data      :
  #         n       : nonce
  #         env     : KD.env
  #       xhrFields :
  #         withCredentials: yes

  initiateApplication:do->
    modal = null
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
      @on "RemoveModal", =>
        if modal instanceof KDBlockingModalView
          modal.setTitle "Connection Established"
          modal.$('.modalformline').html "<b>It just connected</b>, don't worry about this warning."
          @utils.wait 2500, -> modal?.destroy()
      @getVisitor().on 'change.login', (account)=> @accountChanged account, connectedState
      @getVisitor().on 'change.logout', (account)=> @accountChanged account, connectedState

  accountChanged:(account, connectedState)->

    connectedState.connected = yes
    @emit "RemoveModal"

    @emit "AccountChanged", account

    KDRouter.init()
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

      # account = KD.whoami()
      # unless account.getAt('isEnvironmentCreated')
      #   @getSingleton('kiteController').createSystemUser (err)=>
      #     if err
      #       new KDNotificationView
      #         title   : 'Fail!'
      #         duration: 1000
      #     else
      #       account.modify isEnvironmentCreated: yes, (err)->
      #         if err
      #           console.log err
      #         else
      #           console.log "environment is created for #{account.getAt('profile.nickname')}"

    else
      @createLoggedOutState account
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
      appManager.openApplication "Activity", yes
      #appManager.openApplication "Chat", yes
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
        koding.api.JUser.logout ->
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

  isUserLoggedIn: -> @getVisitor().currentDelegate instanceof koding.api.JAccount

  unmarkUserAsTroll:(data)->

    kallback = (acc)=>
      acc.unflagAccount "exempt", (err, res)->
        if err then warn err
        else
          new KDNotificationView
            title : "@#{acc.profile.nickname} won't be treated as a troll anymore!"

    if data.originId
      Bongo.cacheable "JAccount", data.originId, (err, account)->
        kallback account if account
    else if data._bongo.constructorName is 'JAccount'
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
              Bongo.cacheable "JAccount", data.originId, (err, account)->
                kallback account if account
            else if data._bongo.constructorName is 'JAccount'
              kallback data
