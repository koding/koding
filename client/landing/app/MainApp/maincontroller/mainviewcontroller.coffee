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
    
         
    if sidebarController.getView().navController.selectItemByName navItemName
      sidebarController.getView().accNavController.selectItem()
    else
      sidebarController.getView().navController.selectItem()
      sidebarController.getView().accNavController.selectItemByName navItemName