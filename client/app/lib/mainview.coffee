kd                      = require 'kd'
async                   = require 'async'
globals                 = require 'globals'
remote                  = require('./remote')
isLoggedIn              = require './util/isLoggedIn'
whoami                  = require './util/whoami'
isKoding                = require './util/isKoding'
AvatarArea              = require './avatararea/avatararea'
CustomLinkView          = require './customlinkview'
GlobalNotificationView  = require './globalnotificationview'
MainTabView             = require './maintabview'
TopNavigation           = require './topnavigation'
environmentDataProvider = require 'app/userenvironmentdataprovider'
IntroVideoView          = require 'app/introvideoview'
isTeamReactSide         = require 'app/util/isTeamReactSide'
getGroup                = require 'app/util/getGroup'
isSoloProductLite       = require 'app/util/issoloproductlite'
TeamName                = require './activity/sidebar/teamname'
BannerNotificationView  = require 'app/commonviews/bannernotificationview'
doXhrRequest            = require 'app/util/doXhrRequest'
classnames              = require 'classnames'
DEAFULT_TEAM_LOGO       = '/a/images/logos/default_team_logo.svg'
HomeWelcomeSteps        = require 'home/welcome/homewelcomesteps'


module.exports = class MainView extends kd.View

  constructor: (options = {}, data) ->

    mobileDevices       = /Android|iPhone|iPod/i
    options.domId       = 'kdmaincontainer'
    options.cssClass    = if globals.isLoggedInOnLoad then 'with-sidebar' else ''

    super options, data

    @setClass options.deviceType

    @notifications = []


  viewAppended: ->

    @createSidebar()
    @createPanelWrapper()
    # @checkForIntroVideo()  unless isKoding()
    @showRegistrationsClosedWarning()  if isSoloProductLite() and isKoding()
    @checkVersion()
    kd.utils.repeat (5 * 60 * 1000), @bound 'checkVersion'
    @createMainTabView()

    kd.singletons.mainController.ready =>
      unless isKoding()
        @createTeamLogo()
        @createMiniWelcomeSteps()
      else
        @createAccountArea()

      @setStickyNotification()
      @emit 'ready'


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
        attributes : { href : '/' } # so that it shows base url on status bar of browser
        partial    : '<figure></figure>'
        click      : (event) -> kd.utils.stopDOMEvent event
    else
      { nickname } = whoami().profile
      @logoWrapper.addSubView @teamname = new TeamName { cssClass: 'no-logo' }, getGroup()
      @logoWrapper.addSubView @nickname = new kd.CustomHTMLView
        cssClass : 'nickname no-logo'
        partial : "@#{nickname}"

    @logoWrapper.addSubView closeHandle = new kd.CustomHTMLView
      cssClass : 'sidebar-close-handle'
      partial  : "<span class='icon'></span>"
      click    : @bound 'toggleSidebar'

    closeHandle.hide()

    @aside.addSubView @logoWrapper

    unless isKoding()
      @logoWrapper.addSubView @teamLogoWrapper = new kd.CustomHTMLView
        tagName : 'div'
        cssClass : 'team-logo-wrapper'
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


  createPanelWrapper: ->

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

    @isSidebarCollapsed = not @isSidebarCollapsed
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


  createTeamLogo: ->

    logo = ''

    { groupsController } = kd.singletons
    team = groupsController.getCurrentGroup()

    if team.customize
      logo = team.customize.logo

    @teamLogoWrapper.addSubView @teamLogo = new kd.CustomHTMLView
      tagName : 'img'
      cssClass : ''
      attributes :
        src : "#{logo}"

    unless logo
      @teamLogoWrapper.hide()
    else
      @teamLogo.setClass 'team-logo'
      @teamLogoWrapper.show()
      @teamname.unsetClass 'no-logo'
      @nickname.unsetClass 'no-logo'

    groupsController.on 'TEAM_LOGO_CHANGED', (logo) =>

      @teamLogo.setAttribute 'class', ''

      unless logo
        @teamLogo.setAttribute 'src', ''
        @teamname.setClass 'no-logo'
        @nickname.setClass 'no-logo'
        @teamLogoWrapper.hide()
      else
        @teamLogo.setAttribute 'src', logo
        @teamLogo.setClass 'team-logo'
        @teamLogoWrapper.show()
        @teamname.unsetClass 'no-logo'
        @nickname.unsetClass 'no-logo'

  createMiniWelcomeSteps: ->

    @logoWrapper.addSubView new HomeWelcomeSteps { mini : yes }


  createAccountArea: ->

    @accountArea = new kd.CustomHTMLView { cssClass: 'account-area' }

    if isKoding()
    then @aside.addSubView @accountArea
    else @logoWrapper.addSubView @accountArea

    @accountArea.destroySubViews()
    @accountArea.addSubView @avatarArea  = new AvatarArea {}, whoami()


  checkVersion: ->

    return  if @updateBanner

    # if current version only consists numerical characters JSON.stringify
    # casts it into a `Number`. But the result from backend is always string.
    # We are making sure that the compared version is a string. ~Umut
    currentVersion = String globals.config.version

    endPoint = '/-/version'
    type = 'GET'

    doXhrRequest { endPoint, type }, (err, res) =>

      return  if err
      return  if String(res.version) is currentVersion

      kd.utils.wait 2000, =>
        @updateBanner = new BannerNotificationView
          content  : 'Koding has been updated, please reload the page to get the latest features and bug fixes.'
          cssClass : 'success'

        @updateBanner.once 'KDObjectWillBeDestroyed', => @updateBanner = null


  showRegistrationsClosedWarning: ->

    return  unless isSoloProductLite()

    { appStorageController } = kd.singletons
    appStorage = appStorageController.storage 'Activity', '2.0'

    appStorage.fetchValue 'registrationsClosedDismissed', (isDismissed) ->

      return  if isDismissed

      notification = new BannerNotificationView
        timer   : 10
        title   : 'UPDATE:'
        content : 'We launched Koding for Teams and there are some important
                    updates to the solo product.
                    <a href="https://koding.com/blog/goodbye-koding-solo-welcome-koding-for-teams"
                    target="_blank">Read more...</a></p>'

      notification.once 'KDObjectWillBeDestroyed', ->
        appStorage.setValue 'registrationsClosedDismissed', yes


  createMainTabView: ->

    @mainTabView = new MainTabView
      domId               : 'main-tab-view'
      listenToFinder      : yes
      delegate            : this
      slidingPanes        : no
      hideHandleContainer : yes

    @mainTabView.on 'PaneDidShow', (pane) => @emit 'MainTabPaneShown', pane

    @mainTabView.on 'AllPanesClosed', ->
      kd.getSingleton('router').handleRoute '/Activity'

    @panelWrapper.addSubView @mainTabView


  checkForIntroVideo: ->

    { appStorageController } = kd.singletons
    appStorage = appStorageController.storage "WelcomeSteps-#{globals.currentGroup.slug}"

    appStorage.fetchValue 'finishedSteps', (finishedSteps = {}) =>

      return  if finishedSteps.watchVideo

      @showIntroVideo()


  showIntroVideo: ->

    return  if @introVideo

    @addSubView @introVideo = new IntroVideoView
    @introVideoViewIsShown = yes
    @emit 'IntroVideoViewIsShown'


  hideIntroVideo: ->

    return  unless @introVideo

    @introVideo.destroy()
    @introVideo = null
    @introVideoViewIsShown = no
    @emit 'IntroVideoViewIsHidden'


  setStickyNotification: ->

    return if not isLoggedIn() # don't show it to guests

    { JSystemStatus } = remote.api

    kd.utils.wait 2000, =>
      remote.api.JSystemStatus.getCurrentSystemStatuses (err, statuses) =>
        if err then kd.log 'current system status:', err
        else if statuses and Array.isArray statuses
          queue = statuses.map (status) => (next) =>
            @createGlobalNotification status
            kd.utils.wait 500, -> next()

          async.series queue.reverse()


  hideAllNotifications: ->

    notification.hide() for notification in @notifications


  # this only creates a notification
  # and keeps track of existing ones
  # it doesn't broadcast anything
  # a name change might be necessary here - SY
  createGlobalNotification: (message, options = {}) ->

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
    options.cssClass    = kd.utils.curry 'header-notification', options.type
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
          @notifications[i - 1]?.show()
          break

    kd.utils.wait 177, notification.bound 'show'

    return notification


  enableFullscreen: ->
    @setClass 'fullscreen no-anim'
    @emit 'fullscreen', yes
    kd.getSingleton('windowController').notifyWindowResizeListeners()


  disableFullscreen: ->
    @unsetClass 'fullscreen no-anim'
    @emit 'fullscreen', no
    kd.getSingleton('windowController').notifyWindowResizeListeners()


  isFullscreen: -> @hasClass 'fullscreen'


  toggleFullscreen: ->

    if @isFullscreen()
      @disableFullscreen()
    else
      @toggleSidebar()
      @enableFullscreen()


  _logoutAnimation: ->

    { body }    = global.document
    turnOffLine = new kd.CustomHTMLView { cssClass : 'turn-off-line' }
    turnOffDot  = new kd.CustomHTMLView { cssClass : 'turn-off-dot' }

    turnOffLine.appendToDomBody()
    turnOffDot.appendToDomBody()

    body.style.background = '#000'
    @setClass 'logout-tv'

getClassNames = (logo) -> classnames
  'team-logo' : yes
  'default' : logo is DEAFULT_TEAM_LOGO
