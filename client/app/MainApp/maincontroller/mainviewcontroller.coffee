class MainViewController extends KDViewController

  constructor:->

    super

    mainView       = @getView()
    mainController = @getSingleton 'mainController'
    @registerSingleton 'mainViewController', @, yes
    @registerSingleton 'mainView', mainView, yes

    mainController.on 'accountChanged.to.loggedIn', (account)=>
      mainController.loginScreen.hide()

    mainController.on "ShowInstructionsBook", (index)=>
      book = mainView.addBook()
      book.fillPage index

    mainController.on "ToggleChatPanel", =>
      mainView.chatPanel.toggle()

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

    @setViewState pane.getOptions()
    navController.selectItemByName route.slice(1)

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
