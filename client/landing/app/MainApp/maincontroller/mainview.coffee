class MainView extends KDView

  viewAppended:->

    @addHeader()
    @createMainPanels()
    @createMainTabView()
    @createSideBar()
    @windowController = @getSingleton("windowController")
    @listenWindowResize()

    setTimeout =>
      @putWhatYouShouldKnowLink()
    ,5000

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
      click     : (pubInst,event)=>
        if KD.isLoggedIn()
          appManager.openApplication "Activity"
        else
          appManager.openApplication "Home"

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

    @contentPanel.addSubView @mainTabView
    @contentPanel.addSubView @mainTabHandleHolder

  createSideBar:->

    @sidebar = new Sidebar domId : "sidebar", delegate : @
    @emit "SidebarCreated", @sidebar
    @sidebarPanel.addSubView @sidebar

  changeHomeLayout:(isLoggedIn)->

  decorateLoginState:(isLoggedIn = no)->

    if isLoggedIn
      $('body').addClass "loggedIn"
      @mainTabView.showHandleContainer()
      @contentPanel.setClass "social"
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

  putWhatYouShouldKnowLink:->

    @header.addSubView link = new KDCustomHTMLView
      tagName     : "a"
      domId       : "what-you-should-know-link"
      attributes  :
        href      : "#"
      partial     : "What you should know about this beta...<span></span>"
      click       : (pubInst, event)=>
        if $(event.target).is 'span'
          link.hide()
        else
          $.ajax
            # url       : KD.config.apiUri+'https://api.koding.com/1.0/logout'
            url       : "/beta.txt"
            success	  : (response)=>

              modal = new KDModalView
                title       : "Thanks for joining our beta."
                cssClass    : "what-you-should-know-modal"
                height      : "auto"
                width       : 500
                content     : response
                buttons     :
                  Close     :
                    title   : 'Close'
                    style   : 'modal-clean-gray'
                    callback: -> modal.destroy()