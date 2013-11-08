class MainView extends KDView

  viewAppended:->

    @bindPulsingRemove()
    @bindTransitionEnd()
    @addHeader()
    @createMainPanels()
    @createMainTabView()
    @setStickyNotification()

    @utils.defer => @emit 'ready'

    mainController = KD.getSingleton 'mainController'
    mainController.ready @bound 'accountChanged'


  accountChanged:->

    @navController.reset()


  bindPulsingRemove:->

    router     = KD.getSingleton 'router'
    appManager = KD.getSingleton 'appManager'

    appManager.once 'AppCouldntBeCreated', removePulsing

    appManager.on 'AppCreated', (appInstance)->
      options = appInstance.getOptions()
      {title, name, appEmitsReady} = options
      routeArr = location.pathname.split('/')
      routeArr.shift()
      checkedRoute = if routeArr.first is "Develop" \
                     then routeArr.last else routeArr.first

      if checkedRoute is name or checkedRoute is title
        if appEmitsReady
          appView = appInstance.getView()
          appView.ready removePulsing
        else removePulsing()

  addBook:->
    @addSubView new BookView delegate : this

  createMainPanels:->

    @addSubView @panelWrapper = new KDView
      tagName  : "section"
      domId    : "main-panel-wrapper"

  addHeader:->

    {entryPoint} = KD.config

    @addSubView @header = new KDView
      tagName : "header"
      domId   : "main-header"

    @header.clear()

    @header.addSubView wrapper = new KDView
    @header.wrapper = wrapper
    wrapper.addSubView @logo = new KDCustomHTMLView
      tagName   : "a"
      domId     : "koding-logo"
      cssClass  : if entryPoint?.type is 'group' then 'group' else ''
      partial   : '<cite></cite>'
      click     : (event)=>
        KD.utils.stopDOMEvent event
        if KD.isLoggedIn()
        then KD.getSingleton('router').handleRoute "/Activity", {entryPoint}
        else location.replace '/'

    @createMainNavigation()

    wrapper.addSubView loginLink = new CustomLinkView
      domId       : 'header-sign-in'
      title       : 'Login'
      attributes  :
        href      : '/Login'
      click       : (event)->
        KD.utils.stopDOMEvent event
        KD.getSingleton('router').handleRoute "/Login"

    # REFACTOR NOTE: this put the group name next to logo

    # if entryPoint?.slug? and entryPoint.type is "group"
    #   KD.remote.cacheable entryPoint.slug, (err, models)=>
    #     if err then callback err
    #     else if models?
    #       [group] = models
    #       @logo.updatePartial "<cite></cite>#{group.title}"

  createMainNavigation:->

    @navController = new MainNavController
      view           : new NavigationList
        domId        : 'main-nav'
        testPath     : 'navigation-list'
        type         : 'navigation'
        itemClass    : NavigationLink
        testPath     : 'navigation-list'
      wrapper        : no
      scrollView     : no
    ,
      id        : "navigation"
      title     : "navigation"
      items     : []

    @header.wrapper.addSubView @navController.getView()

  createMainTabView:->

    @appSettingsMenuButton = new AppSettingsMenuButton
    @appSettingsMenuButton.hide()

    @mainTabView = new MainTabView
      domId               : "main-tab-view"
      listenToFinder      : yes
      delegate            : this
      slidingPanes        : no
      hideHandleContainer : yes

    @mainTabView.on "PaneDidShow", =>
      appManager   = KD.getSingleton "appManager"
      appManifest  = appManager.getFrontAppManifest()
      forntAppName = appManager.getFrontApp().getOptions().name
      menu         = appManifest?.menu or KD.getAppOptions(forntAppName)?.menu
      if Array.isArray menu
        menu = items: menu
      if menu?.items?.length
        @appSettingsMenuButton.setData menu
        @appSettingsMenuButton.show()
      else
        @appSettingsMenuButton.hide()

    @mainTabView.on "AllPanesClosed", ->
      KD.getSingleton('router').handleRoute "/Activity"

    @panelWrapper.addSubView @mainTabView
    # @contentPanel.addSubView @appSettingsMenuButton

  createSideBar:->

    @sidebar             = new Sidebar domId : "sidebar", delegate : this
    mc                   = KD.getSingleton 'mainController'
    mc.sidebarController = new SidebarController view : @sidebar
    @sidebarPanel.addSubView @sidebar




  createChatPanel:->
    @addSubView @chatPanel   = new MainChatPanel
    # @addSubView @chatHandler = new MainChatHandler
    @chatHandler = new MainChatHandler

  setStickyNotification:->
    # sticky = KD.getSingleton('windowController')?.stickyNotification
    return if not KD.isLoggedIn() # don't show it to guests

    @utils.defer => getStatus()

    {JSystemStatus} = KD.remote.api

    JSystemStatus.on 'restartScheduled', (systemStatus)=>
      sticky = KD.getSingleton('windowController')?.stickyNotification

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

  enableFullscreen: ->
    @contentPanel.$().addClass "fullscreen no-anim"
    @emit "fullscreen", yes
    KD.getSingleton("windowController").notifyWindowResizeListeners()

  disableFullscreen: ->
    @contentPanel.$().removeClass "fullscreen no-anim"
    @emit "fullscreen", no
    KD.getSingleton("windowController").notifyWindowResizeListeners()

  isFullscreen: ->
    @contentPanel.$().is ".fullscreen"

  toggleFullscreen: ->
    if @isFullscreen() then @disableFullscreen() else @enableFullscreen()

  getSticky = =>
    KD.getSingleton('windowController')?.stickyNotification

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

  removePulsing = ->

    loadingScreen = document.getElementById 'main-loading'

    return unless loadingScreen

    logo = loadingScreen.children[0]
    logo.classList.add 'out'

    KD.utils.wait 750, ->

      loadingScreen.classList.add 'out'

      KD.utils.wait 750, ->

        loadingScreen.parentElement.removeChild loadingScreen

        return if KD.isLoggedIn()

        cdc      = KD.getSingleton 'contentDisplayController'
        mainView = KD.getSingleton 'mainView'

        return unless Object.keys(cdc.displays).length

        for own id, display of cdc.displays
          top      = display.$().offset().top
          duration = 400
          KDScrollView::scrollTo.call mainView, {top, duration}
          break

