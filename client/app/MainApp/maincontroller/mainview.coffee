class MainView extends KDView

  viewAppended:->

    @addHeader()
    @createMainPanels()
    @createMainTabView()
    @createSideBar()
    @windowController = @getSingleton("windowController")
    @listenWindowResize()

  addBook:->
    @addSubView new BookView

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

  removeLoader:->

    $loadingScreen = $(".main-loading").eq(0)
    {winWidth,winHeight} = @windowController
    $loadingScreen.css
      marginTop : -winHeight
      opacity   : 0
    @utils.wait 601, =>
      $loadingScreen.remove()
      $('body').removeClass 'loading'

  createMainPanels:->

    @addSubView @panelWrapper = new KDView
      tagName  : "section"


    @panelWrapper.addSubView @sidebarPanel = new KDView
      domId    : "sidebar-panel"
      bind     : 'mouseenter mouseleave'

    @panelWrapper.addSubView @contentPanel = new KDView
      domId    : "content-panel"
      cssClass : "transition"

    @registerSingleton "contentPanel", @contentPanel, yes
    @registerSingleton "sidebarPanel", @sidebarPanel, yes

  addHeader:()->

    @addSubView @header = new KDView
      tagName : "header"

    @header.addSubView @logo = new KDCustomHTMLView
      tagName   : "a"
      domId     : "koding-logo"
      # cssClass  : "hidden"
      attributes:
        href    : "#"
      click     : (event)=>
        event.stopPropagation()
        event.preventDefault()
        KD.getSingleton('router').handleRoute null

    @addLoginButtons()

  addLoginButtons:->

    @header.addSubView @buttonHolder = new KDView
      cssClass  : "button-holder hidden"

    mainController = @getSingleton('mainController')

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

    mainController = @getSingleton('mainController')
    mainController.popupController = new VideoPopupController

    mainController.monitorController = new MonitorController

    @videoButton = new KDButtonView
      cssClass : "video-popup-button"
      icon : yes
      title : "Video"
      callback :=>
        unless @popupList.$().hasClass "hidden"
          @videoButton.unsetClass "active"
          @popupList.hide()
        else
          @videoButton.setClass "active"
          @popupList.show()

    @videoButton.hide()

    @popupList = new VideoPopupList
      cssClass      : "hidden"
      type          : "videos"
      itemClass     : VideoPopupListItem
      delegate      : @
    , {}

    @mainTabView.on "AllPanesClosed", ->
      @getSingleton('router').handleRoute "/Activity"

    @contentPanel.addSubView @mainTabView
    @contentPanel.addSubView @mainTabHandleHolder
    @contentPanel.addSubView @videoButton
    @contentPanel.addSubView @popupList

  createSideBar:->

    @sidebar = new Sidebar domId : "sidebar", delegate : @
    @emit "SidebarCreated", @sidebar
    @sidebarPanel.addSubView @sidebar
    @sidebarPanel.on 'mouseenter', (event)=>
      @sidebar.statusLEDs.show()
    @sidebarPanel.on 'mouseleave', (event)=>
      unless $(event.target).is @sidebar.getDomElement()
        @sidebar.statusLEDs.hideIfAllServicesOnline()

  changeHomeLayout:(isLoggedIn)->

  decorateLoginState:(isLoggedIn = no)->

    if isLoggedIn
      $('body').addClass "loggedIn"
      @mainTabView.showHandleContainer()
      @contentPanel.setClass "social"  if "Develop" isnt @getSingleton("router")?.getCurrentPath()
      # @logo.show()
      # @buttonHolder.hide()
    else
      $('body').removeClass "loggedIn"
      @contentPanel.unsetClass "social"
      @mainTabView.hideHandleContainer()
      # @buttonHolder.show()
      # @logo.hide()

    @changeHomeLayout isLoggedIn
    @utils.wait 300, => @notifyResizeListeners()

  _windowDidResize:->

    {winHeight} = @windowController
    @panelWrapper.setHeight winHeight - 51
