class MainViewController extends KDViewController

  lazyloadQueue = [
    'Topics', 'Members', 'Apps'
  ]

  constructor:->

    super

    {repeat, killRepeat} = KD.utils

    mainView       = @getView()
    mainController = KD.getSingleton 'mainController'
    appManager     = KD.getSingleton 'appManager'
    @registerSingleton 'mainViewController', @, yes
    @registerSingleton 'mainView', mainView, yes

    mainController.on 'accountChanged.to.loggedIn', (account)=>
      mainController.loginScreen.hide()

    mainController.on "ShowInstructionsBook", (index)=>
      book = mainView.addBook()
      book.fillPage index
      book.checkBoundaries()

    mainController.on "ToggleChatPanel", =>
      mainView.chatPanel.toggle()

    mainView.ready ->
      log "i am ready motherfucker"
      i = 0
      r = repeat 5000, ->
        appManager.open lazyloadQueue[i++],
          params       :
            background : yes
        log "i am opening #{lazyloadQueue[i-1]}"
        killRepeat r if i is lazyloadQueue.length



  loadView:(mainView)->

    mainView.mainTabView.on "MainTabPaneShown", (pane)=>
      @mainTabPaneChanged mainView, pane

  mainTabPaneChanged:(mainView, pane)->

    cdController    = KD.getSingleton("contentDisplayController")
    appManager      = KD.getSingleton('appManager')
    app             = appManager.getFrontApp()
    {navController} = KD.getSingleton('mainController').sidebarController.getView()
    cdController.emit "ContentDisplaysShouldBeHidden"
    @setViewState pane.getOptions()

    {title} = app.getOption('navItem')

    return unless title

    navController.selectItemByName title

  setViewState: do ->

    isEntryPointSet = null

    (options = {})->

      {behavior, name} = options
      isEntryPointSet  = yes if name isnt "Home"
      mainView         = @getView()
      {
       contentPanel
       mainTabView
       sidebar
       homeIntro
      }                = mainView
      o                = { isEntryPointSet, name }

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

      group = KD.getSingleton('groupsController').getCurrentGroup()

      if name is 'Home' and group.slug is 'koding'
      then @decorateHome()
      else @clearHome()

  decorateHome:->
    mainView = @getView()
    {homeIntro, logo, chatPanel, chatHandler} = mainView

    chatHandler.hide()
    chatPanel.hide()
    mainView.setClass 'home'
    logo.setClass 'large'
    homeIntro.show()


  clearHome:->
    mainView = @getView()
    {homeIntro, logo, chatPanel, chatHandler} = mainView

    KD.utils.wait 300, ->
      chatHandler.show()
      chatPanel.show()
    mainView.unsetClass 'home'
    logo.unsetClass 'large'
    homeIntro.hide()
