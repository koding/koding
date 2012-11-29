class MainViewController extends KDViewController

  constructor:->
    super
    mainView = @getView()
    @registerSingleton 'mainView', mainView, yes

    mainView.on "SidebarCreated", (sidebar)=>
      @sidebarController = new SidebarController view : sidebar

    # mainView.on "BottomPanelCreated", (bottomPanel)=>
    #   @bottomPanelController = new BottomPanelController view : bottomPanel


    KDView.appendToDOMBody mainView

  loadView:(mainView)->
    mainView.mainTabView.registerListener
      KDEventTypes  : "MainTabPaneShown"
      listener      : @
      callback      : (pubInst,data)=>
        @mainTabPaneChanged mainView, data.pane

  mainTabPaneChanged:(mainView, pane)->
    {sidebarController} = @
    sidebar             = sidebarController.getView()
    paneType            = pane.options.type
    paneName            = pane.options.name
    navItemName         = paneName

    if appManager.isAppUnderDevelop pane.getData().getDelegate()
      @getSingleton('router').handleRoute '/Develop', suppressListeners: yes

    if paneType is 'application'
      mainView.setViewState 'application'
      navItemName = 'Develop'

    else if paneType is 'background'
      mainView.setViewState 'background'

    else if paneName is 'Environment'
      navItemName = 'Develop'
      mainView.setViewState 'application'

    else
      mainView.setViewState 'default'

    if sidebar.navController.selectItemByName navItemName
      # sidebar.accNavController.selectItem()
    else
      # sidebar.navController.selectItem()
      sidebar.accNavController.selectItemByName navItemName