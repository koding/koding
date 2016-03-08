kd                      = require 'kd'
async                   = require 'async'
globals                 = require 'globals'
remote                  = require('./remote').getInstance()
isLoggedIn              = require './util/isLoggedIn'
whoami                  = require './util/whoami'
isKoding                = require './util/isKoding'
AvatarArea              = require './avatararea/avatararea'
CustomLinkView          = require './customlinkview'
GlobalNotificationView  = require './globalnotificationview'
MainTabView             = require './maintabview'
TopNavigation           = require './topnavigation'
environmentDataProvider = require 'app/userenvironmentdataprovider'
actionTypes             = require 'activity/flux/actions/actiontypes'
isTeamReactSide         = require 'app/util/isTeamReactSide'
getGroup                = require 'app/util/getGroup'
isSoloProductLite       = require 'app/util/issoloproductlite'
kookies                 = require 'kookies'
TeamName                = require './activity/sidebar/teamname'

module.exports = class MainView extends kd.View

  constructor: (options = {}, data)->

    mobileDevices       = /Android|iPhone|iPod/i
    options.domId       = 'kdmaincontainer'
    options.cssClass    = if globals.isLoggedInOnLoad then 'with-sidebar' else ''
    options.deviceType  = if mobileDevices.test navigator.userAgent then 'mobile' else 'desktop'

    super options, data

    @setClass options.deviceType

    @notifications = []


  viewAppended: ->

    @createSidebar()
    @createHeader()
    @createPanelWrapper()
    @showRegistrationsClosedWarning()  if isSoloProductLite() and isKoding()
    @createMainTabView()

    kd.singletons.mainController.ready =>
      @createAccountArea()
      @setStickyNotification()
      @emit 'ready'


  createMobileHeader:->

    @addSubView @header = new kd.View
      tagName    : 'header'
      domId      : 'main-header'
      attributes :
        testpath : 'main-header'

    @header.addSubView @hamburgerMenu = new kd.ButtonView
      cssClass  : 'hamburger-menu'
      iconOnly  : yes
      callback  : =>
        @toggleClass 'mobile-menu-active'

        @once 'click', =>
          @toggleClass 'mobile-menu-active'

    {router} = kd.singletons
    router.on 'RouteInfoHandled', =>
      @unsetClass 'mobile-menu-active'

    logoWrapper = new kd.CustomHTMLView
      cssClass  : if entryPoint?.type is 'group' then 'logo-wrapper group' else 'logo-wrapper'

    logoWrapper.addSubView new kd.CustomHTMLView
      tagName    : 'a'
      attributes : href : '/' # so that it shows 'koding.com' on status bar of browser
      partial    : '<figure></figure>'
      click      : (event) -> kd.utils.stopDOMEvent event

    @header.addSubView logoWrapper


  createHeader:->

    entryPoint = globals.config.entryPoint

    if @getOption('deviceType') is 'mobile'
      return @createMobileHeader()

    @addSubView @header = new kd.View
      tagName    : 'header'
      domId      : 'main-header'
      attributes :
        testpath : 'main-header'

    @header.addSubView new TopNavigation

    @header.addSubView @logo = new kd.CustomHTMLView
      tagName    : "a"
      attributes : href : '/'
      domId      : "koding-logo"
      cssClass   : if entryPoint?.type is 'group' then 'group' else ''
      partial    : '<cite></cite>'
      click     : (event)=>
        kd.utils.stopDOMEvent event
        {router} = kd.singletons
        router.handleRoute router.getDefaultRoute()

    @logo.setClass globals.config.environment

    @header.addSubView @logotype = new CustomLinkView
      cssClass : 'logotype'
      title    : 'Koding'
      href     : '/'
      click    : (event)=>
        kd.utils.stopDOMEvent event
        {router} = kd.singletons
        router.handleRoute router.getDefaultRoute()


  createSidebar: ->

    timer = null
    @setClass 'with-sidebar'

    @addSubView @aside = new kd.CustomHTMLView
      bind       : 'mouseenter mouseleave'
      tagName    : 'aside'
      cssClass   : unless isKoding() then 'team' else ''
      domId      : 'main-sidebar'
      attributes :
        testpath : 'main-sidebar'
      mouseenter : =>
        if @isSidebarCollapsed
          timer = kd.utils.wait 200, => @toggleHoverSidebar()
      mouseleave : =>
        kd.utils.killWait timer  if timer
        @toggleHoverSidebar()  if @hasClass 'hover'

    entryPoint = globals.config.entryPoint

    @logoWrapper = new kd.CustomHTMLView
      cssClass  : unless isKoding() then 'logo-wrapper group' else 'logo-wrapper'

    if isKoding()
      @logoWrapper.addSubView new kd.CustomHTMLView
        tagName    : 'a'
        attributes : href : '/' # so that it shows 'koding.com' on status bar of browser
        partial    : '<figure></figure>'
        click      : (event) -> kd.utils.stopDOMEvent event
    else
      kd.singletons.groupsController.ready =>
        @logoWrapper.addSubView new TeamName {}, getGroup()

    @logoWrapper.addSubView closeHandle = new kd.CustomHTMLView
      cssClass : "sidebar-close-handle"
      partial  : "<span class='icon'></span>"
      click    : @bound 'toggleSidebar'

    closeHandle.hide()

    @aside.addSubView @logoWrapper

    if isTeamReactSide()
      SidebarView = require './components/sidebar/view'
      @aside.addSubView @sidebar = new SidebarView
      return

    @aside.addSubView @sidebar = new kd.CustomScrollView
      offscreenIndicatorClassName: 'unread'
      # FW should be checked
      # this works weird somehow - SY
      # offscreenIndicatorClassName: if isKoding() then 'unread' else 'SidebarListItem-unreadCount'

    @sidebar.addSubView moreItemsAbove = new kd.View
      cssClass  : 'more-items above hidden'
      partial   : 'Unread items'

    @sidebar.addSubView moreItemsBelow = new kd.View
      cssClass  : 'more-items below hidden'
      partial   : 'Unread items'

    @sidebar.on 'OffscreenItemsAbove', -> moreItemsAbove.show()
    @sidebar.on 'NoOffscreenItemsAbove', -> moreItemsAbove.hide()
    @sidebar.on 'OffscreenItemsBelow', -> moreItemsBelow.show()
    @sidebar.on 'NoOffscreenItemsBelow', -> moreItemsBelow.hide()
    kd.singletons.notificationController.on 'ParticipantUpdated', =>
      @sidebar.updateOffscreenIndicators()

    ActivitySidebar = require './activity/sidebar/activitysidebar'
    @sidebar.wrapper.addSubView @activitySidebar = new ActivitySidebar

    @activitySidebar.on 'MachinesUpdated', =>
      hasRunning = environmentDataProvider.getRunningMachines().length > 0
      if hasRunning
      then @aside.setClass 'has-runningMachine'
      else @aside.unsetClass 'has-runningMachine'

    @sidebar.on 'ShowCloseHandle', => @aside.setClass 'has-runningMachine'


  createPanelWrapper:->

    @addSubView @panelWrapper = new kd.View
      tagName  : 'section'
      domId    : 'main-panel-wrapper'

    @panelWrapper.addSubView new kd.CustomHTMLView
      tagName  : 'cite'
      domId    : 'sidebar-toggle'
      click    : @bound 'toggleSidebar'


  toggleSidebar: ->

    if @hasClass 'hover'
    then @unsetClass 'hover'
    else @toggleClass 'collapsed'

    @isSidebarCollapsed = !@isSidebarCollapsed
    { frontApp }        = kd.singletons.appManager

    if frontApp.getOption('name') is 'IDE'
      kd.singletons.windowController.notifyWindowResizeListeners()
      frontApp.emit 'CloseFullScreen'  unless @isSidebarCollapsed


  toggleHoverSidebar: ->

    # Just toggle it and don't change the 'isSidebarCollapsed' variable
    @toggleClass 'collapsed'
    @toggleClass 'hover'


  resetSidebar: ->

    @toggleHoverSidebar()
    @toggleSidebar()


  createAccountArea:->

    @accountArea = new kd.CustomHTMLView { cssClass: 'account-area' }

    if isKoding()
    then @aside.addSubView @accountArea
    else @logoWrapper.addSubView @accountArea

    @accountArea.destroySubViews()
    @accountArea.addSubView @avatarArea  = new AvatarArea {}, whoami()


  showRegistrationsClosedWarning: ->

    return  unless isSoloProductLite()

    { appStorageController } = kd.singletons
    appStorage = appStorageController.storage 'Activity', '2.0'

    appStorage.fetchValue 'registrationsClosedDismissed', (isDismissed) =>

      return  if isDismissed

      @panelWrapper.addSubView warning = new kd.CustomHTMLView
        cssClass : 'system-notification'
        partial  : '<p><b>UPDATE: </b>We launched Koding for Teams and there are some important
                    updates to the solo product.
                    <a href="https://koding.com/blog/goodbye-koding-solo-welcome-koding-for-teams"
                    target="_blank">Read more...</a></p><a href="#" class="close"></a>'

        click : (event) ->

          return  unless event.target.classList.contains 'close'

          appStorage.setValue 'registrationsClosedDismissed', yes
          @unsetClass 'in'
          kd.utils.wait 1000, -> warning.destroy()

      kd.utils.wait 2000, -> warning.setClass 'in'


  createMainTabView:->

    @mainTabView = new MainTabView
      domId               : 'main-tab-view'
      listenToFinder      : yes
      delegate            : this
      slidingPanes        : no
      hideHandleContainer : yes

    @mainTabView.on 'PaneDidShow', (pane) => @emit 'MainTabPaneShown', pane

    @mainTabView.on "AllPanesClosed", ->
      kd.getSingleton('router').handleRoute "/Activity"

    @panelWrapper.addSubView @mainTabView


  setStickyNotification:->

    return if not isLoggedIn() # don't show it to guests

    {JSystemStatus} = remote.api

    JSystemStatus.on 'restartScheduled', @bound 'handleSystemMessage'

    kd.utils.wait 2000, =>
      remote.api.JSystemStatus.getCurrentSystemStatuses (err, statuses)=>
        if err then kd.log 'current system status:',err
        else if statuses and Array.isArray statuses
          queue = statuses.map (status) => (next) =>
            @createGlobalNotification status
            kd.utils.wait 500, -> next()

          async.series queue.reverse()

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
    options.cssClass    = kd.utils.curry "header-notification", options.type
    options.cssClass    = kd.utils.curry options.cssClass, 'fx'  if options.animated

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

    kd.utils.wait 177, notification.bound 'show'

    return notification


  enableFullscreen: ->
    @setClass "fullscreen no-anim"
    @emit "fullscreen", yes
    kd.getSingleton("windowController").notifyWindowResizeListeners()


  disableFullscreen: ->
    @unsetClass "fullscreen no-anim"
    @emit "fullscreen", no
    kd.getSingleton("windowController").notifyWindowResizeListeners()


  isFullscreen: -> @hasClass "fullscreen"


  toggleFullscreen: ->

    if @isFullscreen()
      @disableFullscreen()
    else
      @toggleSidebar()
      @enableFullscreen()


  _logoutAnimation: ->

    {body}      = global.document
    turnOffLine = new kd.CustomHTMLView cssClass : "turn-off-line"
    turnOffDot  = new kd.CustomHTMLView cssClass : "turn-off-dot"

    turnOffLine.appendToDomBody()
    turnOffDot.appendToDomBody()

    body.style.background = "#000"
    @setClass "logout-tv"
