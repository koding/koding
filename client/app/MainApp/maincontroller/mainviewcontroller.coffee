class MainViewController extends KDViewController

  constructor:->

    super

    mainView       = @getView()
    mainController = KD.getSingleton 'mainController'
    @registerSingleton 'mainViewController', @, yes
    @registerSingleton 'mainView', mainView, yes

    mainController.on 'accountChanged.to.loggedIn', (account)=>
      mainController.loginScreen.hide()

    mainController.on "ShowInstructionsBook", (index)=>
      book = mainView.addBook()
      book.fillPage index
      # passing book object to catch listeners
      KD.getSingleton("router").emit "InstructionsBookAdded",book

    mainController.on "ToggleChatPanel", =>
      mainView.chatPanel.toggle()

  loadView:(mainView)->

    mainView.mainTabView.on "MainTabPaneShown", (pane)=>
      @mainTabPaneChanged mainView, pane

  mainTabPaneChanged:(mainView, pane)->

    mainController  = KD.getSingleton 'mainController'
    {navController} = mainController.sidebarController.getView()
    {name}          = pane.getOptions()
    {route}         = KD.getAppOptions name
    router          = KD.getSingleton('router')
    cdController    = KD.getSingleton("contentDisplayController")

    cdController.emit "ContentDisplaysShouldBeHidden"

    @setViewState pane.getOptions()

    {slug} = route
    slug or= route
    slug   = slug.slice(1)
    slug   = if slug.slice(0,6) is "Develop" then "Develop" else slug
    navController.selectItemByName switch slug
      when 'Dashboard' then 'Group'
      else slug

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
