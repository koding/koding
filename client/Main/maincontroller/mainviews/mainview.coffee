class MainView extends KDView


  constructor: (options = {}, data)->

    options.domId    = 'kdmaincontainer'
    options.cssClass = if KD.isLoggedInOnLoad then 'with-sidebar' else ''

    super options, data

    @notifications = []


  viewAppended: ->

    {mainController} = KD.singletons

    @bindPulsingRemove()
    @bindTransitionEnd()
    @createHeader()

    if KD.isLoggedInOnLoad
    then @createSidebar()
    else mainController.once 'accountChanged.to.loggedIn', @bound 'createSidebar'

    @createPanelWrapper()
    @createMainTabView()

    mainController.ready =>
      if KD.isLoggedInOnLoad
      then @createAccountArea()
      else mainController.once 'accountChanged.to.loggedIn', @bound 'createAccountArea'

      @setStickyNotification()
      @emit 'ready'


  createHeader:->

    {entryPoint} = KD.config

    @addSubView @header = new KDView
      tagName  : 'header'
      domId    : 'main-header'

    @header.addSubView new TopNavigation

    @header.addSubView @logo = new KDCustomHTMLView
      tagName   : "a"
      domId     : "koding-logo"
      cssClass  : if entryPoint?.type is 'group' then 'group' else ''
      partial   : '<cite></cite>'
      click     : (event)=>
        KD.utils.stopDOMEvent event
        {router} = KD.singletons
        if KD.isLoggedIn()
        then router.handleRoute '/Activity', {entryPoint}
        else router.handleRoute '/', {entryPoint}

    @logo.setClass KD.config.environment

    @header.addSubView @logotype = new CustomLinkView
      cssClass : 'logotype'
      title    : 'Koding'
      href     : '/Home'


  createSidebar: ->

    @setClass 'with-sidebar'

    @addSubView @aside = new KDCustomHTMLView
      tagName  : 'aside'
      domId    : 'main-sidebar'

    @aside.addSubView new KDCustomHTMLView
      cssClass  : if entryPoint?.type is 'group' then 'logo-wrapper group' else 'logo-wrapper'
      partial   : "<a href='/'><figure></figure></a>"

    @aside.addSubView @sidebar = new KDCustomScrollView
      offscreenIndicatorClassName: 'unread'

    @sidebar.addSubView moreItemsAbove = new KDView
      cssClass  : 'more-items above hidden'
      partial   : 'Unread items'

    @sidebar.addSubView moreItemsBelow = new KDView
      cssClass  : 'more-items below hidden'
      partial   : 'Unread items'

    @sidebar.wrapper.addSubView @activitySidebar = new ActivitySidebar

    @sidebar.on 'OffscreenItemsAbove', ->
      moreItemsAbove.show()

    @sidebar.on 'NoOffscreenItemsAbove', ->
      moreItemsAbove.hide()

    @sidebar.on 'OffscreenItemsBelow', ->
      moreItemsBelow.show()

    @sidebar.on 'NoOffscreenItemsBelow', ->
      moreItemsBelow.hide()

    KD.singletons.notificationController.on 'ParticipantUpdated', =>
      @sidebar.updateOffscreenIndicators()

  createPanelWrapper:->

    @addSubView @panelWrapper = new KDView
      tagName  : 'section'
      domId    : 'main-panel-wrapper'

    @panelWrapper.addSubView new KDCustomHTMLView
      tagName  : 'cite'
      domId    : 'sidebar-toggle'
      click    : => @toggleClass 'collapsed'


  createAccountArea:->

    @aside.addSubView @accountArea = new KDCustomHTMLView
      cssClass : 'account-area'

    if KD.isLoggedIn()
    then @createLoggedInAccountArea()
    else
      mc = KD.getSingleton "mainController"
      mc.once "accountChanged.to.loggedIn", @bound 'createLoggedInAccountArea'


  createLoggedInAccountArea:->

    KDView.setElementClass document.body, 'add', 'logged-in'

    @accountArea.destroySubViews()

    # KD.utils.defer => @accountMenu.accountChanged KD.whoami()

    @accountArea.addSubView @avatarArea  = new AvatarArea {}, KD.whoami()
    # @accountArea.addSubView @searchIcon  = new KDCustomHTMLView
    #   domId      : 'fatih-launcher'
    #   cssClass   : 'search acc-dropdown-icon'
    #   tagName    : 'a'
    #   attributes :
    #     title    : 'Search'
    #     href     : '#'
    #   click      : (event)=>
    #     KD.utils.stopDOMEvent event
    #     # log 'run fatih'

    #     @accountArea.setClass "search-open"
    #     @searchInput.setFocus()

    #     KD.getSingleton("windowController").addLayer @searchInput

    #     @searchInput.once "ReceivedClickElsewhere", =>
    #       @accountArea.unsetClass "search-open"

    #   partial    : "<span class='icon'></span>"

    # @accountArea.addSubView @searchForm = new KDCustomHTMLView
    #   cssClass   : "search-form-container"

    # handleRoute = (searchRoute, text)->
    #   if group = KD.getSingleton("groupsController").getCurrentGroup()
    #     groupSlug = if group.slug is "koding" then "" else "/#{group.slug}"
    #   else
    #     groupSlug = ""

    #   toBeReplaced =  if text is "" then "?q=:text:" else ":text:"

    #   # inject search text
    #   searchRoute = searchRoute.replace toBeReplaced, text
    #   # add group slug
    #   searchRoute = "#{groupSlug}#{searchRoute}"

    #   KD.getSingleton("router").handleRoute searchRoute

    # search = (text) ->
    #   currentApp  = KD.getSingleton("appManager").getFrontApp()
    #   if currentApp and searchRoute = currentApp.options.searchRoute
    #     return handleRoute searchRoute, text
    #   else
    #     return handleRoute "/Activity?q=:text:", text

    # @searchForm.addSubView @searchInput = new KDInputView
    #   placeholder  : "Search here..."
    #   keyup      : (event)=>
    #     text = @searchInput.getValue()
    #     # if user deleted everything in textbox
    #     # clear the search result
    #     if text is "" and @searchInput.searched
    #       search("")
    #       @searchInput.searched = false

    #     # 13 is ENTER
    #     if event.keyCode is 13
    #       search text
    #       @searchInput.searched = true

    #     # 27 is ESC
    #     if event.keyCode is 27
    #       @accountArea.unsetClass "search-open"
    #       @searchInput.setValue ""
    #       @searchInput.searched = false


  createMainTabView:->

    @appSettingsMenuButton = new AppSettingsMenuButton
    @appSettingsMenuButton.hide()

    @mainTabView = new MainTabView
      domId               : "main-tab-view"
      listenToFinder      : yes
      delegate            : this
      slidingPanes        : no
      hideHandleContainer : yes


    @mainTabView.on "PaneDidShow", (pane)=>
      appManager   = KD.getSingleton "appManager"

      return  unless appManager.getFrontApp()

      appManifest  = appManager.getFrontAppManifest()
      forntAppName = appManager.getFrontApp().getOptions().name
      menu         = appManifest?.menu or KD.getAppOptions(forntAppName)?.menu

      if Array.isArray menu
        menu = items: menu

      @appSettingsMenuButton.hide()
      if menu?.items?.length
        @appSettingsMenuButton.setData menu
        unless menu.hiddenOnStart
          @appSettingsMenuButton.show()

      @emit "MainTabPaneShown", pane


    @mainTabView.on "AllPanesClosed", ->
      KD.getSingleton('router').handleRoute "/Activity"

    @panelWrapper.addSubView @mainTabView
    @panelWrapper.addSubView @appSettingsMenuButton


  openMachineModal: (machine, item) ->

    bounds   = item.getBounds()
    position =
      top    : Math.max bounds.y - 38, 0
      left   : bounds.x + bounds.w + 16

    new MachineSettingsModal {position}, machine


  setStickyNotification:->

    return if not KD.isLoggedIn() # don't show it to guests

    {JSystemStatus} = KD.remote.api

    JSystemStatus.on 'restartScheduled', @bound 'handleSystemMessage'

    KD.utils.wait 2000, =>
      KD.remote.api.JSystemStatus.getCurrentSystemStatuses (err, statuses)=>
        if err then log 'current system status:',err
        else if statuses and Array.isArray statuses
          {daisy} = Bongo
          queue   = statuses.map (status)=>=>
            @createGlobalNotification status
            KD.utils.wait 500, -> queue.next()

          daisy queue.reverse()

  handleSystemMessage:(message)->

    @createGlobalNotification message  if message.status is 'active'

  hideAllNotifications:->

    notification.hide() for notification in @notifications


  # this only creates a notification
  # and keeps track of existing ones
  # it doesn't broadcast anything
  # a name change might be necessary here - SY
  createGlobalNotification:(message, options = {})->

    # will get rid of this map
    # once the admin panel counterpart
    # of this is renewed - SY
    typeMap =
      'restart' : 'warn'
      'reload'  : ''
      'info'    : ''
      'red'     : 'err'
      'yellow'  : 'warn'
      'green'   : ''

    options.type      or= typeMap[message.type]
    options.showTimer  ?= message.type isnt 'restart'  #change this option name creates confusion with the actual timer
    options.cssClass    = KD.utils.curry "header-notification", options.type
    options.cssClass    = KD.utils.curry options.cssClass, 'fx'  if options.animated

    @notifications.push notification = new GlobalNotificationView options, message

    container = message.container or @header
    container.addSubView notification
    @hideAllNotifications()

    # if a notification is destroyed
    # find the previous one
    # and show it if it exists - SY
    notification.once 'KDObjectWillBeDestroyed', =>
      for n, i in @notifications
        if n.getId() is notification.getId()
          @notifications[i-1]?.show()
          break

    KD.utils.wait 177, notification.bound 'show'

    return notification


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

    if @isFullscreen()
    then @disableFullscreen()
    else @enableFullscreen()


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


  _logoutAnimation: ->

    {body}      = document
    turnOffLine = new KDCustomHTMLView cssClass : "turn-off-line"
    turnOffDot  = new KDCustomHTMLView cssClass : "turn-off-dot"

    turnOffLine.appendToDomBody()
    turnOffDot.appendToDomBody()

    body.style.background = "#000"
    @setClass "logout-tv"


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

