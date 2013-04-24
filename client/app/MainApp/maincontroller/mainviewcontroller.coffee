class MainViewController extends KDViewController

  constructor:->

    super

    mainView       = @getView()
    mainController = @getSingleton 'mainController'
    @registerSingleton 'mainViewController', @, yes
    @registerSingleton 'mainView', mainView, yes

    mainView.on "SidebarCreated", (sidebar)=>
      mainController.sidebarController = new SidebarController view : sidebar

      mainController.on '(pageLoaded|accountChanged).(as|to).loggedOut', (account)=>
        mainController.sidebarController.accountChanged account

      mainController.on '(pageLoaded|accountChanged).(as|to).loggedIn', (account)=>
        mainController.loginScreen.hide =>
          mainController.sidebarController.accountChanged account
    # mainView.on "BottomPanelCreated", (bottomPanel)=>
    #   @bottomPanelController = new BottomPanelController view : bottomPanel

    mainController.on "ShowInstructionsBook", (index)=>
      book = mainView.addBook()
      book.fillPage index

    mainController.on "ShowChatPanel", =>
      mainView.chatPanel.toggleClass 'visible'

  loadView:(mainView)->

    mainView.mainTabView.on "MainTabPaneShown", (pane)=>
      @mainTabPaneChanged mainView, pane

  mainTabPaneChanged:(mainView, pane)->

    mainController  = @getSingleton 'mainController'
    {navController} = mainController.sidebarController.getView()
    {name}          = pane.getOptions()
    {route}         = KD.getAppOptions name
    router          = @getSingleton('router')
    cdController    = @getSingleton("contentDisplayController")

    cdController.emit "ContentDisplaysShouldBeHidden"

    if route is 'Develop'
      router.handleRoute '/Develop', suppressListeners: yes

    @setViewState pane.getOptions()
    navController.selectItemByName route

  isEntryPointSet = null

  setViewState:(options)->

    {behavior, name} = options

    isEntryPointSet = yes if name isnt "Home"

    {contentPanel, mainTabView, sidebar} = @getView()

    o = {isEntryPointSet, name}

    switch behavior
      when 'hideTabs'
        o.hideTabs = yes
        o.type     = 'social'
      when 'application'
        o.hideTabs = no
        o.type     = 'develop'
      else
        o.hideTabs = no
        o.type     = 'social'

    @emit "UILayoutNeedsToChange", o

    isEntryPointSet = yes
