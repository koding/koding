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

    mainView.mainTabView.on "MainTabPaneShown", (pane)=>
      @mainTabPaneChanged mainView, pane

  mainTabPaneChanged:(mainView, pane)->

    {sidebarController}    = @
    sidebar                = sidebarController.getView()
    {navController}        = sidebar
    {type, name, behavior} = pane.getOptions()
    {route}                = KD.getAppOptions name
    router                 = @getSingleton('router')
    cdController           = @getSingleton("contentDisplayController")
    appManager             = @getSingleton "appManager"
    appInstance            = appManager.getByView pane.mainView

    cdController.emit "ContentDisplaysShouldBeHidden"

    if route is 'Develop'
      router.handleRoute '/Develop', suppressListeners: yes

    mainView.setViewState behavior
    navController.selectItemByName route
    appManager.setFrontApp appInstance