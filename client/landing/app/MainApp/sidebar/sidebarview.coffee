class Sidebar extends JView

  constructor:->

    super

    account           = KD.whoami()
    {profile}         = account
    @_onDevelop       = no
    @_finderExpanded  = no
    @_popupIsActive   = no

    currentGroupData = @getSingleton('groupsController').getCurrentGroupData()

    @avatar = new AvatarView
      tagName    : "div"
      cssClass   : "avatar-image-wrapper"
      size       :
        width    : 160
        height   : 76
    , account

    @avatarAreaIconMenu = new AvatarAreaIconMenu
      delegate     : @

    @groupAvatar = new KDView
      cssClass   : 'group-avatar-image-wrapper hidden'
      tagName : 'div'
    ,currentGroupData

    @currentGroup = new KDCustomHTMLView
      cssClass    : 'current-group-indicator'
      pistachio   : "{{#(title)}}"
      click       : ->
        #KD.getSingleton('router').handleRoute
        console.log @getData()
    , currentGroupData

    @avatarHeader = new KDView
      cssClass : 'avatar-header hidden'
      pistachio : '{{#(title)}}'
      click :=>
        # KD.getSingleton('router').handleRoute "/#{currentGroupData.slug}/Activity"

    , currentGroupData

    # handle group related decisions
    groupsController = @getSingleton 'groupsController'
    groupsController.on 'GroupChanged', =>
      currentGroupData = groupsController.getCurrentGroupData()
      unless currentGroupData?.data?.slug is 'koding'
        @avatar.setClass 'shared-avatar'
        @avatar.setWidth 80

        # group avatar should be either a URL or a dataURL

        @groupAvatar.$().css backgroundImage :  "url(#{currentGroupData?.data?.avatar or 'http://lorempixel.com/100/100/?' + @utils.getRandomNumber()})"
        @groupAvatar.show()
        @groupAvatar.setClass 'flash'
        @avatarHeader.setData currentGroupData
        @avatarHeader.show()
      else
        @avatar.unsetClass 'shared-avatar'
        @avatar.setWidth 160
        @groupAvatar.hide()
        @groupAvatar.unsetClass 'flash'
        @avatarHeader.setData currentGroupData
        @avatarHeader.hide()
      @render()

    @navController = new NavigationController
      view           : new NavigationList
        type         : "navigation"
        itemClass    : NavigationLink
      wrapper        : no
      scrollView     : no
    , navItems

    @nav = @navController.getView()

    @accNavController = new NavigationController
      view           : new NavigationList
        type         : "navigation"
        cssClass     : "account"
        itemClass    : NavigationLink
      wrapper        : no
      scrollView     : no
    , accNavItems

    @accNav = @accNavController.getView()

    @adminNavController = new NavigationController
      view           : new NavigationList
        type         : "navigation"
        cssClass     : "account admin"
        itemClass    : AdminNavigationLink
      wrapper        : no
      scrollView     : no

    @adminNav = @adminNavController.getView()

    @footerMenuController = new NavigationController
      view           : new NavigationList
        type         : "footer-menu"
        itemClass    : FooterMenuItem
      wrapper        : no
      scrollView     : no
    , footerMenuItems

    @footerMenu = @footerMenuController.getView()

    @finderHeader = new KDCustomHTMLView
      tagName   : "h2"
      pistachio : "{{#(profile.nickname)}}.#{location.hostname}"
    , account

    @finderResizeHandle = new SidebarResizeHandle
      cssClass  : "finder-resize-handle"

    @finderController = new NFinderController
      fsListeners       : yes
      initDelay         : 5000
      useStorage        : yes
      addOrphansToRoot  : no

    @finder = @finderController.getView()

    @finderBottomControlsController = new KDListViewController
      view        : new FinderBottomControls
      wrapper     : no
      scrollView  : no
    , bottomControlsItems

    @finderBottomControls = @finderBottomControlsController.getView()

    KD.registerSingleton "finderController", @finderController
    @listenWindowResize()

    # @statusLEDs = new StatusLEDView
    @statusLEDs = new KDView
      cssClass : 'status-leds'

  resetAdminNavController:->
    @utils.wait 1000, =>
      @adminNavController.removeAllItems()
      if KD.isLoggedIn()
        KD.whoami().fetchRole? (err, role)=>
          if role is "super-admin"
            @adminNavController.instantiateListItems adminNavItems.items

  setListeners:->

    mainView = @getDelegate()
    {@contentPanel, @sidebarPanel} = mainView

    @getSingleton('mainController').on "AvatarPopupIsActive", =>
      @_popupIsActive = yes

    @getSingleton('mainController').on "AvatarPopupIsInactive", =>
      @_popupIsActive = no

    $fp = @$('#finder-panel')
    cp  = @contentPanel
    @wc = @getSingleton "windowController"
    fpLastWidth = null

    @finderResizeHandle.on "ClickedButNotDragged", =>
      unless fpLastWidth
        fpLastWidth = parseInt $fp.css("width"), 10
        cp.$().css left : 65, width : @wc.winWidth - 65
        @utils.wait 300, -> $fp.css "width", 13
      else
        fpLastWidth = 208 if fpLastWidth < 100
        $fp.css "width", fpLastWidth
        cp.$().css left : 52 + fpLastWidth, width : @wc.winWidth - 52 - fpLastWidth
        fpLastWidth = null

    @finderResizeHandle.on "DragStarted", (e, dragState)=>
      cp._left  = parseInt cp.$().css("left"), 10
      cp._left  = parseInt cp.$().css("left"), 10
      @_fpWidth = parseInt $fp.css("width"), 10
      cp._width = parseInt @wc.winWidth - 52 - @_fpWidth, 10
      cp.unsetClass "transition"

    @finderResizeHandle.on "DragFinished", (e, dragState)=>
      delete cp._left
      delete cp._width
      delete @_fpWidth
      unless @finderResizeHandle._dragged
        @finderResizeHandle.emit "ClickedButNotDragged"
      else
        fpLastWidth = null
      delete @finderResizeHandle._dragged
      cp.setClass "transition"

    @finderResizeHandle.on "DragInAction", (x, y)=>
      @finderResizeHandle._dragged = yes
      newFpWidth = @_fpWidth - x
      return if newFpWidth < 13
      cp.$().css left : cp._left - x, width : cp._width + x
      $fp.css "width", newFpWidth

    # exception - Sinan, Jan 2013
    # we bind this with jquery directly bc #main-nav is no KDView but just HTML
    @$('#main-nav').on "mouseenter", @animateLeftNavIn.bind @
    @$('#main-nav').on "mouseleave", @animateLeftNavOut.bind @

  viewAppended:->

    super

    @setListeners()

  pistachio:->

    """
    <div id="main-nav">
      <div class="avatar-placeholder">
        <div id="avatar-area">
          {{> @groupAvatar}}
          {{> @avatar}}
          {{> @avatarHeader}}
        </div>
      </div>
      {{> @avatarAreaIconMenu}}
      {{> @statusLEDs}}
      {{> @nav}}
      <hr />
      {{> @accNav}}
      {{> @adminNav}}
      <hr />
      {{> @footerMenu}}
    </div>
    <div id='finder-panel'>
      {{> @finderResizeHandle}}
      <div id='finder-header-holder'>
        {{> @finderHeader}}
      </div>
      <div id='finder-holder'>
        {{> @finder}}
      </div>
      <div id='finder-bottom-controls'>
        {{> @finderBottomControls}}
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

  expandNavigationPanel:(newSize, callback)->

    @$('.avatar-placeholder').removeClass "collapsed"
    @$('#finder-panel').removeClass "expanded"
    @avatarHeader.show() unless @avatarHeader.getData().slug is 'koding'
    if parseInt(@contentPanel.$().css("left"), 10) < 174
      @contentPanel.setClass "mouse-on-nav"
    @utils.wait 300, => callback?()

  collapseNavigationPanel:(callback)->

    @$('.avatar-placeholder').addClass "collapsed"
    @$('#finder-panel').addClass "expanded"
    @contentPanel.unsetClass "mouse-on-nav"
    @avatarHeader.hide()
    @utils.wait 300, =>
      callback?()
      @emit "NavigationPanelWillCollapse"

  expandEnvironmentSplit:(newSize, callback)->

    newSize          = 260
    @_finderExpanded = yes

    @contentPanel.setClass "with-finder"
    @contentPanel.unsetClass "social"
    @contentPanel.setWidth @wc.winWidth - @$('#finder-panel').width() - 52
    @utils.wait 300, =>
      callback?()
      @_windowDidResize()

  collapseEnvironmentSplit:(callback)->

    @contentPanel.unsetClass "with-finder"
    @contentPanel.setClass "social"
    @contentPanel.setWidth @wc.winWidth - 160
    @utils.wait 300, =>
      @_finderExpanded = no
      callback?()

  showEnvironmentPanel:->

    @showFinderPanel()

  showFinderPanel:->

    unless @_finderExpanded
      @collapseNavigationPanel()
      @expandEnvironmentSplit null, ()=> @_onDevelop = yes

  hideFinderPanel:->

    if @_finderExpanded
      @expandNavigationPanel 160, ()=> @_onDevelop = no
      @collapseEnvironmentSplit =>
        @utils.wait 300, => @notifyResizeListeners()

  _windowDidResize:->

    {winWidth} = @getSingleton('windowController')
    if KD.isLoggedIn()
      if @contentPanel.$().hasClass "with-finder"
        @contentPanel.setWidth winWidth - parseInt(@$('#finder-panel').css("width"), 10) - 52
      else
        @contentPanel.setWidth winWidth - 160
    else
      @contentPanel.setWidth winWidth

    bottomListHeight = @$("#finder-bottom-controls").height() or 109
    @$("#finder-holder").height @getHeight() - @$("#finder-header-holder").height() - bottomListHeight

  navItems =
    # temp until groups are implemented
    do ->
      if location.hostname is "koding.com"
        id    : "navigation"
        title : "navigation"
        items : [
          { title : "Activity",   path: "/Activity" }
          { title : "Topics",     path: "/Topics" }
          { title : "Members",    path: "/Members" }
          { title : "Develop",    path: "/Develop", loggedIn: yes }
          { title : "Apps",       path: "/Apps" }
        ]
      else
        id    : "navigation"
        title : "navigation"
        items : [
          { title : "Activity",   path: "/Activity" }
          { title : "Topics",     path: "/Topics" }
          { title : "Members",    path: "/Members" }
          { title : "Groups",     path: "/Groups" }
          { title : "Develop",    path: "/Develop",  loggedIn: yes }
          { title : "Apps",       path: "/Apps" }
        ]

  accNavItems =
    id    : "acc-navigation"
    title : "acc-navigation"
    items : [
      { title : "Invite Friends", loggedIn  : yes }
      { title : "Account",        loggedIn  : yes, path   : '/Account' }
      { title : "Logout",         loggedIn  : yes, action : "logout", path: "/Logout" }
      { title : "Login",          loggedOut : yes, action : "login",  path: "/Login" }
    ]

  bottomControlsItems =
    id : "finder-bottom-controls"
    items : [
      { title : "Launch Terminal",    icon : "terminal", appPath: 'WebTerm', isWebTerm : yes }
      { title : "Manage Remotes",     icon : "remotes", action: 'manageRemotes'}
      { title : "Add Resources",      icon : "resources" }
      { title : "Settings",           icon : "cog" }
      { title : "Keyboard Shortcuts", icon : "shortcuts", action: "showShortcuts" }
    ]

  adminNavItems =
    id    : "admin-navigation"
    title : "admin-navigation"
    items : [
      # { title : "Kite selector", loggedIn : yes, callback : -> new KiteSelectorModal }
      { title : "Admin Panel",     loggedIn : yes, callback : -> new AdminModal }
    ]

  footerMenuItems =
    id    : "footer-menu"
    title : "footer-menu"
    items : [
      { title : "Help",  callback : -> @getSingleton('mainController').emit "ShowInstructionsBook" }
      { title : "About", callback : -> @showAboutDisplay() }
      { title : "Chat",  loggedIn : yes, callback : ->
        # @getSingleton('bottomPanelController').emit "TogglePanel", "chat"
        # unless location.hostname is "localhost"
        new KDNotificationView title : "Coming soon..."
      }
    ]
