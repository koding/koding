class MainView extends KDView

  viewAppended:->

    @bindPulsingRemove()
    @bindTransitionEnd()
    @createHeader()
    @createDock()
    @createAccountArea()
    @createMainPanels()
    @createMainTabView()
    @setStickyNotification()

    @utils.defer => @emit 'ready'

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
    # @addSubView new BookView delegate : this

  _logoutAnimation:->
    {body}        = document

    turnOffLine   = new KDCustomHTMLView
      cssClass    : "turn-off-line"
    turnOffDot    = new KDCustomHTMLView
      cssClass    : "turn-off-dot"

    turnOffLine.appendToDomBody()
    turnOffDot.appendToDomBody()

    body.style.background = "#000"
    @setClass               "logout-tv"


  createMainPanels:->

    @addSubView @panelWrapper = new KDView
      tagName  : "section"
      domId    : "main-panel-wrapper"

  createHeader:->

    {entryPoint} = KD.config

    @addSubView @header = new KDView
      tagName : "header"
      domId   : "main-header"

    @header.clear()

    @header.addSubView @innerContainer = new KDCustomHTMLView
      cssClass  : "inner-container"

    @logo = new KDCustomHTMLView
      tagName   : "a"
      domId     : "koding-logo"
      cssClass  : if entryPoint?.type is 'group' then 'group' else ''
      partial   : '<cite></cite>'
      click     : (event)=>
        KD.utils.stopDOMEvent event
        if KD.isLoggedIn()
        then KD.getSingleton('router').handleRoute "/Activity", {entryPoint}
        else location.replace '/'

    @innerContainer.addSubView @logo

    groupLogo = KD.currentGroup?.logo or ""
    @logo.setCss 'background-image', "url(#{groupLogo})"

    @logo.setClass KD.config.environment


    @innerContainer.addSubView @logotype = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "logotype"
      partial   : "Koding"
      click     : (event)=>
        KD.utils.stopDOMEvent event
        KD.getSingleton('router').handleRoute "/", {entryPoint}



    # REFACTOR NOTE: login link

    # wrapper.addSubView loginLink = new CustomLinkView
    #   title       : 'Login'
    #   cssClass    : 'header-sign-in'
    #   attributes  :
    #     href      : '/Login'
    #   click       : (event)->
    #     KD.utils.stopDOMEvent event
    #     KD.getSingleton('router').handleRoute "/Login"

    # REFACTOR NOTE: this put the group name next to logo

    # if entryPoint?.slug? and entryPoint.type is "group"
    #   KD.remote.cacheable entryPoint.slug, (err, models)=>
    #     if err then callback err
    #     else if models?
    #       [group] = models
    #       @logo.updatePartial "<cite></cite>#{group.title}"

  createDock:->

    @innerContainer.addSubView KD.singleton('dock').getView()


  createAccountArea:->

    @accountArea = new KDCustomHTMLView
      cssClass : 'account-area'

    @innerContainer.addSubView @accountArea

    unless KD.isLoggedIn()
      @loginLink = new CustomLinkView
        cssClass    : 'header-sign-in'
        title       : 'Login'
        attributes  :
          href      : '/Login'
        click       : (event)->
          KD.utils.stopDOMEvent event
          KD.getSingleton('router').handleRoute "/Login"
      @accountArea.addSubView @loginLink

      mc = KD.getSingleton "mainController"
      mc.on "accountChanged.to.loggedIn", =>
        @loginLink.destroy()
        @createLoggedInAccountArea()

      return

    @createLoggedInAccountArea()

  createLoggedInAccountArea:->
    @accountArea.destroySubViews()

    @accountArea.addSubView @accountMenu = new AvatarAreaIconMenu
    @accountMenu.accountChanged KD.whoami()

    @accountArea.addSubView @avatarArea  = new AvatarArea {}, KD.whoami()
    @accountArea.addSubView @searchIcon  = new KDCustomHTMLView
      domId      : 'fatih-launcher'
      cssClass   : 'search acc-dropdown-icon'
      tagName    : 'a'
      attributes :
        title    : 'Search'
        href     : '#'
      click      : (event)=>
        KD.utils.stopDOMEvent event
        # log 'run fatih'

        @accountArea.setClass "search-open"
        @searchInput.setFocus()

        KD.getSingleton("windowController").addLayer @searchInput

        @searchInput.once "ReceivedClickElsewhere", =>
          if not @searchInput.getValue()
            @accountArea.unsetClass "search-open"

      partial    : "<span class='icon'></span>"

    @accountArea.addSubView @searchForm = new KDCustomHTMLView
      cssClass   : "search-form-container"

    handleRoute = (searchRoute, text)->
      if group = KD.getSingleton("groupsController").getCurrentGroup()
        groupSlug = if group.slug is "koding" then "" else "/#{group.slug}"
      else
        groupSlug = ""

      toBeReplaced =  if text is "" then "?q=:text:" else ":text:"

      # inject search text
      searchRoute = searchRoute.replace toBeReplaced, text
      # add group slug
      searchRoute = "#{groupSlug}#{searchRoute}"

      KD.getSingleton("router").handleRoute searchRoute

    search = (text) ->
      currentApp  = KD.getSingleton("appManager").getFrontApp()
      if currentApp and searchRoute = currentApp.options.searchRoute
        return handleRoute searchRoute, text
      else
        return handleRoute "/Activity?q=:text:", text

    @searchForm.addSubView @searchInput = new KDInputView
      placeholder  : "Search here..."
      keyup      : (event)=>
        text = @searchInput.getValue()
        # if user deleted everything in textbox
        # clear the search result
        if text is "" and @searchInput.searched
          search("")
          @searchInput.searched = false

        # 13 is ENTER
        if event.keyCode is 13
          search text
          @searchInput.searched = true

        # 27 is ESC
        if event.keyCode is 27
          @accountArea.unsetClass "search-open"
          @searchInput.setValue ""
          @searchInput.searched = false


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

      return  unless appManager.getFrontApp()

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
    @panelWrapper.addSubView @appSettingsMenuButton

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
    @setClass "fullscreen no-anim"
    @emit "fullscreen", yes
    KD.getSingleton("windowController").notifyWindowResizeListeners()

  disableFullscreen: ->
    @unsetClass "fullscreen no-anim"
    @emit "fullscreen", no
    KD.getSingleton("windowController").notifyWindowResizeListeners()

  isFullscreen: -> @hasClass "fullscreen"

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

        cdc      = KD.singleton('display')
        mainView = KD.getSingleton 'mainView'

        return unless Object.keys(cdc.displays).length

        for own id, display of cdc.displays
          top      = display.$().offset().top
          duration = 400
          KDScrollView::scrollTo.call mainView, {top, duration}
          break
