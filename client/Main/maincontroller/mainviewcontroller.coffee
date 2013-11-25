class MainViewController extends KDViewController

  constructor:->

    super

    {repeat, killRepeat} = KD.utils

    mainView         = @getView()
    mainController   = KD.getSingleton 'mainController'
    appManager       = KD.getSingleton 'appManager'
    @registerSingleton 'mainViewController', this, yes
    @registerSingleton 'mainView', mainView, yes

    warn "FIXME Add tell to Login app ~ GG @ kodingrouter (if needed)"
    # mainController.on 'accountChanged.to.loggedIn', (account)->
    #   mainController.loginScreen.hide()

    mainController.on "ShowInstructionsBook", (index)->
      book = mainView.addBook()
      book.fillPage index
      book.checkBoundaries()

    mainController.on "ToggleChatPanel", -> mainView.chatPanel.toggle()

    if KD.checkFlag 'super-admin'
    then $('body').addClass 'super'
    else $('body').removeClass 'super'

    mainViewController = this
    window.onscroll = do ->
      lastRatio = 0
      threshold = 50
      (event)->
        el = document.body
        {scrollHeight, scrollTop} = el

        dynamicThreshold = if threshold > 1
        then (scrollHeight - threshold) / scrollHeight
        else threshold

        ratio = (scrollTop + window.innerHeight) / scrollHeight

        if dynamicThreshold < ratio > lastRatio
          appManager.getFrontApp()?.emit "LazyLoadThresholdReached"

        lastRatio = ratio

  loadView:(mainView)->

    mainView.mainTabView.on "MainTabPaneShown", (pane)=>
      @mainTabPaneChanged mainView, pane

  mainTabPaneChanged:(mainView, pane)->

    cdController    = KD.getSingleton 'contentDisplayController'
    dockController  = KD.getSingleton 'dockController'
    appManager      = KD.getSingleton 'appManager'
    app             = appManager.getFrontApp()
    {mainTabView}   = mainView
    {navController} = dockController

    cdController.emit "ContentDisplaysShouldBeHidden"
    # temp fix
    # until fixing the original issue w/ the dnd this should be kept here
    if pane
    then @setViewState pane.getOptions()
    else mainTabView.getActivePane().show()

    {title} = app.getOption('navItem')

    if title
    then navController.selectItemByName title
    else navController.deselectAllItems()


  setViewState: do ->

    (options = {})->

      {behavior, name} = options
      html             = document.getElementsByTagName('html')[0]
      body             = document.body
      mainView         = @getView()
      { mainTabView
        sidebar }      = mainView
      o                = {name}

      KDView.setElementClass html, 'remove', 'app'
      switch behavior
        when 'hideTabs'
          o.hideTabs = yes
          o.type     = 'social'
        when 'application'
          o.hideTabs = no
          o.type     = 'develop'
          KDView.setElementClass html, 'add', 'app'
        else
          o.hideTabs = no
          o.type     = 'social'

      @emit "UILayoutNeedsToChange", o

      # if options.name is 'Activity'
      # if KD.introView

      KDView.setElementClass body, 'remove', 'intro'
      mainView.unsetClass 'home'
      KD.introView?.unsetClass 'in'
      KD.introView?.setClass 'out'

  #     group = KD.getSingleton('groupsController').getCurrentGroup()

  #     if group.slug is 'koding'
  #     then @decorateHome()
  #     else @clearHome()

  # decorateHome:->
  #   mainView = @getView()
  #   {logo, chatPanel, chatHandler} = mainView

  #   chatHandler.hide()
  #   chatPanel.hide()
  #   mainView.setClass 'home'
  #   logo.setClass 'large'
  #   KD.introView?.show()

  # clearHome:->
  #   mainView = @getView()
  #   {homeIntro, logo, chatPanel, chatHandler} = mainView

  #   KD.introView.hide()
  #   KD.utils.wait 300, ->
  #     chatHandler.show()
  #     chatPanel.show()
  #   mainView.unsetClass 'home'
  #   logo.unsetClass 'large'
  #   KD.introView?.hide()
