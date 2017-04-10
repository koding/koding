kd                      = require 'kd'
async                   = require 'async'
globals                 = require 'globals'
remote                  = require('./remote')
isLoggedIn              = require './util/isLoggedIn'
whoami                  = require './util/whoami'
CustomLinkView          = require './customlinkview'
GlobalNotificationView  = require './globalnotificationview'
MainTabView             = require './maintabview'
cdnize                  = require 'app/util/cdnize'
getGroup                = require 'app/util/getGroup'
TeamName                = require './activity/sidebar/teamname'
BannerNotificationView  = require 'app/commonviews/bannernotificationview'
doXhrRequest            = require 'app/util/doXhrRequest'
classnames              = require 'classnames'
DEAFULT_TEAM_LOGO       = '/a/images/logos/default_team_logo.svg'
HomeWelcomeSteps        = require 'home/welcome/homewelcomesteps'

HeaderMessageView = require 'app/components/headermessage/headermessageview'


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
    @checkVersion()
    kd.utils.repeat (5 * 60 * 1000), @bound 'checkVersion'
    @createMainTabView()

    kd.singletons.mainController.ready =>
      @createTeamLogo()
      @createMiniWelcomeSteps()

      @emit 'ready'


  createSidebar: ->

    timer = null
    @setClass 'with-sidebar'

    @addSubView @aside = new kd.CustomHTMLView
      bind       : 'mouseenter mouseleave'
      tagName    : 'aside'
      cssClass   : 'team'
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
      cssClass  : 'logo-wrapper group'

    { nickname } = whoami().profile
    @logoWrapper.addSubView @teamname = new TeamName {}, getGroup()
    @logoWrapper.addSubView @nickname = new kd.CustomHTMLView
      cssClass : 'nickname'
      partial : "@#{nickname}"

    @logoWrapper.addSubView closeHandle = new kd.CustomHTMLView
      cssClass : 'sidebar-close-handle'
      partial  : "<span class='icon'></span>"
      click    : @bound 'toggleSidebar'

    closeHandle.hide()

    @aside.addSubView @logoWrapper

    @logoWrapper.addSubView @teamLogoWrapper = new kd.CustomHTMLView
      cssClass : 'team-logo-wrapper'

    # SidebarView = require './components/sidebar/view'
    #
    SidebarView = require './sidebar/view'

    @aside.addSubView @sidebar = new SidebarView


  createPanelWrapper: ->

    @addSubView @panelWrapper = new kd.View
      tagName  : 'section'
      domId    : 'main-panel-wrapper'

    @panelWrapper.addSubView new HeaderMessageView


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

    { groupsController } = kd.singletons
    team = groupsController.getCurrentGroup()

    logo = cdnize team.customize?.logo
    @teamLogoWrapper.addSubView teamLogo = new kd.CustomHTMLView
      cssClass: 'team-logo'
    teamLogo.setPartial "<img src=#{logo} />"  if logo
    teamLogo.setClass 'default' unless logo

    groupsController.on 'TEAM_LOGO_CHANGED', (newLogo) ->
      unless newLogo
        teamLogo.updatePartial ''
        teamLogo.setClass 'default'
      else
        teamLogo.unsetClass 'default'
        teamLogo.updatePartial "<img src=#{cdnize newLogo} />"


  createMiniWelcomeSteps: ->

    @logoWrapper.addSubView new HomeWelcomeSteps { mini : yes }


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
      return  if String(res.client_version) is currentVersion

      kd.utils.wait 2000, =>
        @updateBanner = new BannerNotificationView
          content  : 'Koding has been updated, please reload the page to get the latest features and bug fixes.'
          cssClass : 'success'

        @updateBanner.once 'KDObjectWillBeDestroyed', => @updateBanner = null


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
