class Sidebar extends JView

  constructor:->

    super

    account           = KD.whoami()
    {profile}         = account
    @_onDevelop       = no
    @_finderExpanded  = no
    @_popupIsActive   = no

    # Avatar area
    @avatar = new AvatarView
      tagName    : "div"
      cssClass   : "avatar-image-wrapper"
      size       :
        width    : 160
        height   : 76
    , account

    @avatarAreaIconMenu = new AvatarAreaIconMenu
      delegate     : @

    @statusLEDs = new KDView
      cssClass : 'status-leds'

    # Main Navigations
    @navController = new NavigationController
      view           : new NavigationList
        type         : "navigation"
        itemClass    : NavigationLink
      wrapper        : no
      scrollView     : no
    , navItems

    @nav = @navController.getView()

    # Main Navigations Footer Menu
    @footerMenuController = new NavigationController
      view           : new NavigationList
        type         : "footer-menu"
        itemClass    : FooterMenuItem
      wrapper        : no
      scrollView     : no
    , footerMenuItems

    @footerMenu = @footerMenuController.getView()

    # Finder Header
    @finderHeader = new KDCustomHTMLView
      tagName   : "h2"
      pistachio : "{{#(profile.nickname)}}.#{KD.config.userSitesDomain}"
    , account

    # File Tree
    @finderController = new NFinderController
      useStorage        : yes
      addOrphansToRoot  : no

    @finder = @finderController.getView()
    KD.registerSingleton "finderController", @finderController
    @finderController.on 'ShowEnvironments', => @finderBottomControlPin.click()

    # Finder Bottom Controls
    @finderBottomControlsController = new KDListViewController
      view        : new FinderBottomControls
      wrapper     : no
      scrollView  : no
    , bottomControlsItems

    @finderBottomControls = @finderBottomControlsController.getView()

    @finderBottomControlPin = new KDToggleButton
      cssClass     : "finder-bottom-pin"
      iconOnly     : yes
      defaultState : "show"
      states       : [
        title      : "show"
        iconClass  : "up"
        callback   : (callback)=>
          @showBottomControls()
          callback?()
      ,
        title      : "hide"
        iconClass  : "down"
        callback   : (callback)=>
          @hideBottomControls()
          callback?()
      ]

    @resourcesController = new ResourcesController
    @resourcesWidget     = @resourcesController.getView()

    @createNewVMButton   = new KDButtonView
      title     : "Create New VM"
      icon      : yes
      iconClass : "plus-orange"
      cssClass  : "clean-gray create-vm"
      callback  : KD.singletons.vmController.createNewVM

    @listenWindowResize()

  resetAdminNavController:->
    @utils.wait 1000, =>
      @adminNavController.removeAllItems()
      if KD.isLoggedIn()
        KD.whoami().fetchRole? (err, role)=>
          if role is "super-admin"
            @adminNavController.instantiateListItems adminNavItems.items

  setListeners:->

    mainController                 = @getSingleton "mainController"
    mainViewController             = @getSingleton "mainViewController"
    mainView                       = @getSingleton "mainView"
    {@contentPanel, @sidebarPanel} = mainView
    $fp                            = @$('#finder-panel')
    cp                             = @contentPanel
    @wc                            = @getSingleton "windowController"
    fpLastWidth                    = null

    mainController.on "AvatarPopupIsActive",   => @_popupIsActive = yes
    mainController.on "AvatarPopupIsInactive", => @_popupIsActive = no

    # exception - Sinan, Jan 2013
    # we bind this with jquery directly bc #main-nav is no KDView but just HTML
    @$('#main-nav').on "mouseenter", @bound "animateLeftNavIn"
    @$('#main-nav').on "mouseleave", @bound "animateLeftNavOut"

    mainViewController.on "UILayoutNeedsToChange", @bound "changeLayout"

  changeLayout:(options)->

    {type, hideTabs} = options
    windowController = @getSingleton 'windowController'

    @$finderPanel       or= @$('#finder-panel')
    @$avatarPlaceholder or= @$('.avatar-placeholder')
    @_onDevelop           = type is 'develop'

    width = switch type
      when 'full', 'social'
        @$finderPanel.removeClass "expanded"
        @$avatarPlaceholder.removeClass "collapsed"
      when 'develop'
        @$finderPanel.addClass "expanded"
        @$avatarPlaceholder.addClass "collapsed"

    @utils.wait 300, => @emit "NavigationPanelWillCollapse"

  viewAppended:->
    super
    @setListeners()

  pistachio:->
    """
    <div id="main-nav">
      <div class="avatar-placeholder">
        <div id="avatar-area">
          {{> @avatar}}
        </div>
      </div>
      {{> @avatarAreaIconMenu}}
      {{> @statusLEDs}}
      {{> @nav}}
      {{> @footerMenu}}
    </div>
    <div id='finder-panel'>
      <div id='finder-header-holder'>
        {{> @finderHeader}}
      </div>
      <div id='finder-holder'>
        {{> @finder}}
      </div>
      <div id='finder-bottom-controls'>
        {{> @finderBottomControls}}
        {{> @finderBottomControlPin}}
        {{> @resourcesWidget}}
        {{> @createNewVMButton}}
      </div>
    </div>
    """
  _mouseenterTimeout = null
  _mouseleaveTimeout = null

  animateLeftNavIn:->
    return if $('body').hasClass("dragInAction")
    @utils.killWait _mouseleaveTimeout if _mouseleaveTimeout
    _mouseenterTimeout = @utils.wait 200, =>
      @_mouseentered = yes
      @expandNavigationPanel() if @_onDevelop

  animateLeftNavOut:->
    return if @_popupIsActive or $('body').hasClass("dragInAction")
    @utils.killWait _mouseenterTimeout if _mouseenterTimeout
    _mouseleaveTimeout = @utils.wait 200, =>
      if @_mouseentered and @_onDevelop
        @collapseNavigationPanel()

  expandNavigationPanel:->

    @$('.avatar-placeholder').removeClass "collapsed"
    @$('#finder-panel').removeClass "expanded"
    if parseInt(@contentPanel.$().css("left"), 10) < 174
      @contentPanel.setClass "mouse-on-nav"
    @utils.wait 300, => callback?()

  collapseNavigationPanel:(callback)->

    @$('.avatar-placeholder').addClass "collapsed"
    @$('#finder-panel').addClass "expanded"
    @contentPanel.unsetClass "mouse-on-nav"
    @utils.wait 300, =>
      callback?()
      @emit "NavigationPanelWillCollapse"

  showBottomControls:->
    @$('#finder-bottom-controls').addClass 'show-environments'
    @utils.wait 400, @bound '_windowDidResize'

  hideBottomControls:->
    @$('#finder-bottom-controls').removeClass 'show-environments'
    @utils.wait 300, @bound '_windowDidResize'

  _windowDidResize:->
    @$("#finder-holder").height @getHeight() - @$("#finder-bottom-controls").height() - 50

  navItems =
    # temp until groups are implemented
    do ->
      if location.hostname is "koding.com"
        id        : "navigation"
        title     : "navigation"
        items     : [
          { title : "Home",           path : "/Activity" }
          { title : "Activity",       path : "/Activity" }
          { title : "Topics",         path : "/Topics" }
          { title : "Members",        path : "/Members" }
          { title : "Develop",        path : "/Develop", loggedIn: yes }
          { title : "Apps",           path : "/Apps" }
          { type  : "separator" }
          { title : "Invite Friends", type : "account", loggedIn: yes }
          { title : "Account",        path : "/Account", type : "account", loggedIn  : yes }
          { title : "Logout",         path : "/Logout",  type : "account", loggedIn  : yes }
          { title : "Login",          path : "/Login",   type : "account", loggedOut : yes }
        ]
      else
        id        : "navigation"
        title     : "navigation"
        items     : [
          { title : "Home",           path : "/Activity" }
          { title : "Activity",       path : "/Activity" }
          { title : "Topics",         path : "/Topics" }
          { title : "Members",        path : "/Members" }
          { title : "Groups",         path : "/Groups" }
          { title : "Develop",        path : "/Develop",  loggedIn: yes }
          { title : "Apps",           path : "/Apps" }
          { type  : "separator" }
          { title : "Invite Friends", type : "account", loggedIn: yes }
          { title : "Account",        path : "/Account", type : "account", loggedIn  : yes }
          { title : "Logout",         path : "/Logout",  type : "account", loggedIn  : yes }
          { title : "Login",          path : "/Login",   type : "account", loggedOut : yes }
        ]

  bottomControlsItems =
    id : "finder-bottom-controls"
    items : [
      # {
      #   title   : "Launch Terminal", icon : "terminal",
      #   appPath : "WebTerm", isWebTerm : yes
      # }
      # { title   : "Settings",           icon : "cog" }
      # {
      #   title   : "Keyboard Shortcuts", icon : "shortcuts",
      #   action  : "showShortcuts"
      # }
      {
        title   : "your environments",   icon : "resources",
        action  : "showEnvironments"
      }
      # {
      #   title   : "Create a new VM",      icon : "plus",
      #   action  : "createNewVM"
      # }
    ]

  adminNavItems =
    id    : "admin-navigation"
    title : "admin-navigation"
    items : [
      {
        title    : "Admin Panel",
        loggedIn : yes,
        callback : -> new AdminModal
      }
    ]

  footerMenuItems =
    id    : "footer-menu"
    title : "footer-menu"
    items : [
      {
        title    : "Help",
        callback : ->
          @getSingleton('mainController').emit "ShowInstructionsBook"
      }
      {
        title    : "About",
        callback : -> @showAboutDisplay()
      }
      {
        title    : "Chat",
        callback : ->
          @getSingleton('mainController').emit "ToggleChatPanel"
      }
    ]
