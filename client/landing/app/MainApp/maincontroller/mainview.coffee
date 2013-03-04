class MainView extends KDView

  viewAppended:->

    @addHeader()
    @createMainPanels()
    @createMainTabView()
    @createSideBar()
    @listenWindowResize()

  addBook:-> @addSubView new BookView

  setViewState:(state)->

    switch state
      when 'hideTabs'
        @contentPanel.setClass 'no-shadow'
        @mainTabView.hideHandleContainer()
        @sidebar.hideFinderPanel()
      when 'application'
        @contentPanel.unsetClass 'no-shadow'
        @mainTabView.showHandleContainer()
        @sidebar.showFinderPanel()
      else
        @contentPanel.unsetClass 'no-shadow'
        @mainTabView.showHandleContainer()
        @sidebar.hideFinderPanel()

  removeLoader:->
    $loadingScreen = $(".main-loading").eq(0)
    {winWidth,winHeight} = @getSingleton "windowController"
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
      bind     : "webkitTransitionEnd" #TODO: Cross browser support

    @contentPanel.on "ViewResized", (rest...)=> @emit "ContentPanelResized", rest...

    @registerSingleton "contentPanel", @contentPanel, yes
    @registerSingleton "sidebarPanel", @sidebarPanel, yes

    @contentPanel.on "webkitTransitionEnd", (e) =>
      @emit "mainViewTransitionEnd", e

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
        return if @groupsEnabled()

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

    getFrontAppManifest = ->
      appManager = KD.getSingleton "appManager"
      appController = KD.getSingleton "kodingAppsController"
      frontApp = appManager.getFrontApp()
      frontAppName = name for name, instances of appManager.appControllers when frontApp in instances
      appController.constructor.manifests?[frontAppName]

    @mainSettingsMenuButton = new KDButtonView
      domId    : "main-settings-menu"
      cssClass : "kdsettingsmenucontainer transparent"
      iconOnly : yes
      iconClass: "dot"
      callback : ->
        appManifest = getFrontAppManifest()
        if appManifest?.menu
          appManifest.menu.forEach (item, index)->
            item.callback = (contextmenu)->
              mainView = KD.getSingleton "mainView"
              view = mainView.mainTabView.activePane?.mainView
              item.eventName or= item.title
              view?.emit "menu.#{item.eventName}", item.eventName, item, contextmenu

          offset = @$().offset()
          contextMenu = new JContextMenu
              event       : event
              delegate    : @
              x           : offset.left - 150
              y           : offset.top + 20
              arrow       :
                placement : "top"
                margin    : -5
            , appManifest.menu
    @mainSettingsMenuButton.hide()

    @mainTabView = new MainTabView
      domId              : "main-tab-view"
      listenToFinder     : yes
      delegate           : @
      slidingPanes       : no
      tabHandleContainer : @mainTabHandleHolder
    ,null

    @mainTabView.on "PaneDidShow", => KD.utils.wait 10, =>
      appManifest = getFrontAppManifest()
      @mainSettingsMenuButton[if appManifest?.menu then "show" else "hide"]()

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
    @contentPanel.addSubView @mainSettingsMenuButton
    @contentPanel.addSubView @videoButton
    @contentPanel.addSubView @popupList

    getSticky = =>
      @getSingleton('windowController')?.stickyNotification
    getStatus = =>
      KD.remote.api.JSystemStatus.getCurrentSystemStatus (err,systemStatus)=>
        if err
          if err.message is 'none_scheduled'
            getSticky()?.emit 'restartCanceled'
          else
            log 'current system status:',err
        else
          systemStatus.on 'restartCanceled', =>
            getSticky()?.emit 'restartCanceled'
          new GlobalNotification
            targetDate  : systemStatus.scheduledAt
            title       : systemStatus.title
            content     : systemStatus.content
            type        : systemStatus.type

    # sticky = @getSingleton('windowController')?.stickyNotification
    @utils.defer => getStatus()

    KD.remote.api.JSystemStatus.on 'restartScheduled', (systemStatus)=>
      sticky = @getSingleton('windowController')?.stickyNotification

      if systemStatus.status isnt 'active'
        getSticky()?.emit 'restartCanceled'
      else
        systemStatus.on 'restartCanceled', =>
          getSticky()?.emit 'restartCanceled'
        new GlobalNotification
          targetDate : systemStatus.scheduledAt
          title      : systemStatus.title
          content    : systemStatus.content
          type       : systemStatus.type

  createSideBar:->

    @sidebar = new Sidebar domId : "sidebar", delegate : @
    @emit "SidebarCreated", @sidebar
    @sidebarPanel.addSubView @sidebar

  changeHomeLayout:(isLoggedIn)->

  groupsEnabled:->
    return $('.group-landing').length > 0

  switchGroupState:(state)->
    if $('.group-loader').length > 0
      $('.group-loader')[0].remove?()

    $('body').addClass "login"
    console.log "LOGGED IN WITH GROUPS"

    LoginLink = new KDCustomHTMLView
      partial: "Login"
      cssClass: "bigLink"

    if state
      LoginLink.click = ->
        $('.group-landing').css 'height', 0

      LoginLink.updatePartial 'Go to Group'
    else
      LoginLink.click = ->
        @getSingleton('mainController').loginScreen.show()
        @getSingleton('mainController').loginScreen.animateToForm 'login'
        $('.group-landing').css 'height', 0

    LoginLink.appendToSelector '.group-login-buttons'

    $('.group-landing').css 'height', window.innerHeight - 50

  decorateLoginState:(isLoggedIn = no)->

    groupLandingView = new KDView
      lazyDomId : 'group-landing'

    groupLandingView.listenWindowResize()
    groupLandingView._windowDidResize = =>
      groupLandingView.setHeight window.innerHeight - 50

    if isLoggedIn
      if @groupsEnabled() then @switchGroupState yes
      else $('body').addClass "loggedIn"

      @mainTabView.showHandleContainer()
      @contentPanel.setClass "social"  if "Develop" isnt @getSingleton("router")?.getCurrentPath()
      # @logo.show()
      # @buttonHolder.hide()

    else
      if @groupsEnabled() then @switchGroupState no
      else $('body').removeClass "loggedIn"

      @contentPanel.unsetClass "social"
      @mainTabView.hideHandleContainer()
      # @buttonHolder.show()
      # @logo.hide()

    @changeHomeLayout isLoggedIn
    @utils.wait 300, => @notifyResizeListeners()

  _windowDidResize:->

    {winHeight} = @getSingleton "windowController"
    @panelWrapper.setHeight winHeight - 51
