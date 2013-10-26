class MainView extends KDView

  viewAppended:->

    @bindPulsingRemove()
    @bindTransitionEnd()
    @addHeader()
    @createMainPanels()
    @createMainTabView()
    @setStickyNotification()
    @createSideBar()
    @createChatPanel()
    @listenWindowResize()

    @utils.defer => @_windowDidResize()

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

  putAbout:->

    KDView.appendToDOMBody overlay = new KDView
      cssClass : 'about-overlay'
    overlay.bindTransitionEnd()

    logo = new KDCustomHTMLView
      cssClass : 'main-loading'
      partial  : '<ul><li/><li/><li/><li/><li/><li/></ul>'

    overlay.once 'transitionend', ->
      overlay.addSubView logo
      KD.utils.defer -> logo.$('>ul').addClass 'in'
      KD.utils.wait 4000, -> about.setClass 'in'

    @utils.defer -> overlay.setClass 'in'

    {winHeight} = KD.getSingleton('windowController')

    offset = if winHeight > 400 then (winHeight - 400) / 2 else 0

    KDView.appendToDOMBody about = new AboutView
      domId   : 'about-text'
      click   : =>
        about.once 'transitionend', ->
          about.destroy()
          overlay.once 'transitionend', ->
            overlay.destroy()
          overlay.unsetClass 'in'
        about.unsetClass 'in'

    about.setY offset
    about.bindTransitionEnd()

  addBook:->
    @addSubView new BookView delegate : this

  _windowDidResize:->

    {winHeight} = KD.getSingleton "windowController"
    @panelWrapper.setHeight winHeight - 51

  createMainPanels:->

    @addSubView @panelWrapper = new KDView
      tagName  : "section"
      domId    : "main-panel-wrapper"

    @panelWrapper.addSubView @sidebarPanel = new KDView
      domId    : "sidebar-panel"
    @registerSingleton "sidebarPanel", @sidebarPanel, yes

    @panelWrapper.addSubView @contentPanel = new ContentPanel
      domId    : "content-panel"
      cssClass : "transition"

    @contentPanel.on "ViewResized", (rest...)=>
      @emit "ContentPanelResized", rest...

  addHeader:->

    {entryPoint} = KD.config

    @addSubView @header = new KDView
      tagName : "header"
      domId   : "main-header"

    @header.getElement().innerHTML = ''

    @header.addSubView wrapper = new KDView
    wrapper.addSubView @logo = new KDCustomHTMLView
      tagName   : "a"
      domId     : "koding-logo"
      cssClass  : if entryPoint?.type is 'group' then 'group' else ''
      partial   : "<span></span>"
      click     : (event)=>
        KD.utils.stopDOMEvent event
        homeRoute = if KD.isLoggedIn() then "/Activity" else "/"
        KD.getSingleton('router').handleRoute homeRoute, {entryPoint}

    wrapper.addSubView loginLink = new CustomLinkView
      domId       : 'header-sign-in'
      title       : 'Login'
      attributes  :
        href      : '/Login'
      click       : (event)->
        KD.utils.stopDOMEvent event
        KD.getSingleton('router').handleRoute "/Login"

    if entryPoint?.slug? and entryPoint.type is "group"
      KD.remote.cacheable entryPoint.slug, (err, models)=>
        if err then callback err
        else if models?
          [group] = models
          @logo.updatePartial "<span></span>#{group.title}"


  createMainTabView:->

    @mainTabHandleHolder = new MainTabHandleHolder
      domId    : "main-tab-handle-holder"
      cssClass : "kdtabhandlecontainer"
      delegate : this

    @appSettingsMenuButton = new AppSettingsMenuButton
    @appSettingsMenuButton.hide()

    @mainTabView = new MainTabView
      domId              : "main-tab-view"
      listenToFinder     : yes
      delegate           : this
      slidingPanes       : no
      tabHandleContainer : @mainTabHandleHolder
    ,null

    @mainTabView.on "PaneDidShow", =>
      appManager  = KD.getSingleton "appManager"
      appManifest = appManager.getFrontAppManifest()
      menu = appManifest?.menu or \
             KD.getAppOptions(appManager.getFrontApp().getOptions().name)?.menu
      if Array.isArray menu
        menu = items: menu
      if menu?.items?.length
        @appSettingsMenuButton.setData menu
        @appSettingsMenuButton.show()
      else
        @appSettingsMenuButton.hide()

    @mainTabView.on "AllPanesClosed", ->
      KD.getSingleton('router').handleRoute "/Activity"

    @contentPanel.addSubView @mainTabView
    @contentPanel.addSubView @mainTabHandleHolder
    @contentPanel.addSubView @appSettingsMenuButton

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

