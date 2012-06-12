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
        queue = []
  
  authorizeServices:(callback)->
    KD.whoami().fetchNonce (nonce)->
      $.ajax
        url       : KD.apiUri+"/1.0/login"
        data      :
          n       : nonce
          env     : if KD.env is 'dev' then 'vpn' else 'beta'
        dataType  : 'jsonp'

  deauthorizeServices:(callback)->
    KD.whoami().fetchNonce (nonce)->
      $.ajax
        url       : KD.apiUri+'https://api.koding.com/1.0/logout'
        data      :
          n       : nonce
        success	  : callback
        failure	  : callback
        dataType  : 'jsonp'
  
  initiateApplication:->
    KD.registerSingleton "kiteController", new KiteController
    @getVisitor().on 'change.login', (account)=> @accountChanged account
    @getVisitor().on 'change.logout', (account)=> @accountChanged account

  accountChanged:(account)->
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
          appManager.openApplication "Home"
          @mainViewController.getView().decorateLoginState no
    else
      @mainViewController.sidebarController.accountChanged account
      appManager.openApplication "Home"
      @mainViewController.getView().decorateLoginState no
      
  
  createLoggedInState:(account)->
    wasLoggedIn = yes
    mainView = @mainViewController.getView()
    @loginScreen.slideUp =>
      @mainViewController.sidebarController.accountChanged account
      # appManager.openApplication "Activity", yes
      appManager.openApplication "Demos", yes
      @mainViewController.getView().decorateLoginState yes

  goToPage:(publishingInstance,event)=>
    if event.appPath is "Login"
      @loginScreen.slideDown()
    else
      appManager.openApplication event.appPath,yes

  putGlobalEventListeners:()->

    @listenTo
      KDEventTypes : "KDBackendConnectedEvent"
      callback     : ()=> 
        @initiateApplication()

    # probably not necessary anymore but needs a fix on finder part
    @listenTo
      KDEventTypes : 'ContextMenuWantsToBeDisplayed'
      callback : (contextMenu, creatingEvent)=>
        @mainViewController.getView().addSubView contextMenu

    @listenTo "NavigationLinkTitleClick", (pubInst, event) =>
      if event.pageName is 'Logout'
        bongo.api.JUser.logout ->
          new KDNotificationView
            cssClass  : "login"
            title     : "<span></span>Come back soon!"
            # content   : "Successfully logged out."
            duration  : 2000
      else
        @goToPage pubInst, event

  # some day we'll have this :)
  hashDidChange:(params,query)->

  setVisitor:(visitor)-> @visitor = visitor
  getVisitor: -> @visitor
  getAccount: -> @getVisitor().currentDelegate

  isUserLoggedIn: -> @getVisitor().currentDelegate instanceof bongo.api.JAccount




class MainViewController extends KDViewController
  
  constructor:->
    super
    mainView = @getView()
    @registerSingleton 'mainView', mainView, yes
    
    mainView.registerListener
      KDEventTypes : "SidebarCreated"
      listener     : @ 
      callback     : (pubInst,sidebar)=> @createSidebarController sidebar

    KDView.appendToDOMBody mainView

  loadView:(mainView)->
    mainView.mainTabView.registerListener
      KDEventTypes  : "MainTabPaneShown"
      listener      : @
      callback      : (pubInst,data)=>
        @mainTabPaneChanged mainView, data.pane

  createSidebarController:(sidebar)->
    @sidebarController = new SidebarController view : sidebar
  
  mainTabPaneChanged:(mainView, pane)->
    sidebarController    = @sidebarController
    paneType      = pane.options.type
    paneName      = pane.options.name
    navItemName   = paneName
    
    if paneType is 'application'
      mainView.setViewState 'application'
      navItemName = 'Develop'
      
    else if paneType is 'background'
      mainView.setViewState 'background'
      
    else if paneName is 'Environment'
      mainView.setViewState 'application'
      navItemName = 'Develop'
      
    else
      mainView.setViewState 'default'
    
         
    if sidebarController.navController.selectItemByName navItemName
      sidebarController.accNavController.selectItem()
    else
      sidebarController.navController.selectItem()
      sidebarController.accNavController.selectItemByName navItemName

class MainView extends KDView
  
  viewAppended:->
    # @putLoader()
    @addHeader()
    @createMainPanels()
    @createMainTabView()
    @createSideBar()
    @removeLoader()
    @windowController = @getSingleton("windowController")
    @listenWindowResize()

    setTimeout =>
      @putWhatYouShouldKnowLink()
    ,5000
  
  setViewState:(state)->
    if state is 'background'
      @contentPanel.setClass 'no-shadow'
      @mainTabView.hideHandleContainer()
    else
      @contentPanel.unsetClass 'no-shadow'
      @mainTabView.showHandleContainer()

    switch state
      when 'application'
        @sidebar.showFinderPanel()
      when 'environment'
        @sidebar.showEnvironmentPanel()
      else
        @sidebar.hideFinderPanel()

  putLoader:->

  removeLoader:->
    # mainController = @getSingleton("mainController")
    # mainController.loader.hide()
    # @loadingScreen.hide()
    $('body').removeClass 'loading'
  
  createMainPanels:->
    @addSubView @panelWrapper = new KDView tagName : "section"
    @panelWrapper.addSubView @sidebarPanel = new KDView domId: "sidebar-panel"
    @panelWrapper.addSubView @contentPanel = new KDView domId: "content-panel"

    @registerSingleton "contentPanel", @contentPanel, yes
    @registerSingleton "sidebarPanel", @sidebarPanel, yes
  
  addHeader:()->
    @addSubView @header = new KDView
      tagName : "header"

    @header.addSubView @logo = new KDCustomHTMLView
      tagName   : "a"
      domId     : "koding-logo"
      attributes: 
        href    : "#"
      click     : (pubInst,event)=>
        if @getSingleton('mainController').isUserLoggedIn()
          appManager.openApplication "Activity"
        else
          appManager.openApplication "Home"

    @addLoginButtons()
  
  addLoginButtons:->
    @header.addSubView @buttonHolder = new KDView
      cssClass  : "button-holder hidden"

    mainController = @getSingleton('mainController')
    
    # @buttonHolder.addSubView new KDButtonView
    #   title     : "About Koding"
    #   domId     : "about-button"
    #   callback  : =>
    #     mainController.propagateEvent KDEventType : "AboutButtonClicked", globalEvent : yes
    # 
    @buttonHolder.addSubView new KDButtonView
      title     : "Sign In"
      style     : "koding-blue"
      callback  : =>
        mainController.loginScreen.slideDown =>
          mainController.loginScreen.animateToForm "login"

    @buttonHolder.addSubView new KDButtonView
      title     : "Create an Account"
      style     : "koding-orange"
      callback  : =>
        mainController.loginScreen.slideDown =>
          mainController.loginScreen.animateToForm "register"

  createMainTabView:->
    @mainTabHandleHolder = new MainTabHandleHolder
      domId    : "main-tab-handle-holder"
      cssClass : "kdtabhandlecontainer"
      delegate : @
      
    @mainTabView = new MainTabView
      domId              : "main-tab-view"
      listenToFinder     : yes
      delegate           : @
      slidingPanes       : no
      tabHandleContainer : @mainTabHandleHolder
    ,null

    @contentPanel.addSubView @mainTabView
    @contentPanel.addSubView @mainTabHandleHolder

  createSideBar:->
    @sidebar = new Sidebar domId : "sidebar", delegate : @
    @propagateEvent KDEventType : "SidebarCreated", @sidebar
    @sidebarPanel.addSubView @sidebar
    
  changeHomeLayout:(isLoggedIn)->

  decorateLoginState:(isLoggedIn = no)->
    if isLoggedIn
      $('body').addClass "loggedIn"
      @mainTabView.showHandleContainer()
      @contentPanel.setClass "social"
      @buttonHolder.hide()
    else
      $('body').removeClass "loggedIn"
      @contentPanel.unsetClass "social"
      @mainTabView.hideHandleContainer()
      @buttonHolder.show()

    @changeHomeLayout isLoggedIn
    setTimeout =>
      @windowController.notifyWindowResizeListeners()
    , 300
  
  _windowDidResize:->
    {winWidth, winHeight} = @windowController

    if @getSingleton('mainController').isUserLoggedIn()
      @contentPanel.setWidth winWidth - 160
    else
      @contentPanel.setWidth winWidth

    contentHeight = winHeight - 51

    @panelWrapper.setHeight contentHeight

  putWhatYouShouldKnowLink:->
    
    @header.addSubView link = new KDCustomHTMLView
      tagName     : "a"
      domId       : "what-you-should-know-link"
      attributes  :
        href      : "#"
      partial     : "What you should know about this beta...<span></span>"
      click       : (pubInst, event)->
        if $(event.target).is 'span'
          link.hide()
        else
          new KDModalView
            title   : "Thanks for joining our beta."
            cssClass: "what-you-should-know-modal"
            height  : "auto"
            width   : 500
            content : 
              """
              <div class='modalformline'>There are a couple of things that you should know.</div>
              <div class='modalformline'>
                <ol>
                  <li>This is a work in progress, by no means a finished product.</li>
                  <li>We're working to deliver improvements to the system, but there are some known issues.</li>
                  <ul>
                    <li>The terminal may not come up for you.  We will be pushing a fix for this as soon as we can, but in this release, the terminal is not as stable as we would like it to be.</li>
                    <li>Databases don't work in this release.<br></li>
                  </ul>
                  <li>We have delivered some stability and performance improvements, which is still a work in progress.  In particular, we hope you notice improvements in the performance of the file system and terminal.</li>
                  <li>We will be iterating on the social features of the site over the next weeks, but we haven't released anything new on the social side of things in this release.</li>
                </ol>
              </div>
              """
              
