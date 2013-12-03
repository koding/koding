class Sidebar extends JView

  constructor: (options={}, data)->

    options.bind = "dragleave"
    super options, data

    account           = KD.whoami()
    {profile}         = account
    @_onDevelop       = no
    @_finderExpanded  = no
    @_popupIsActive   = no

    # Avatar area
    @avatar = new AvatarView
      tagName    : "div"
      cssClass   : "avatar-image-wrapper"
      attributes :
        title    : "View your public profile"
      size       :
        width    : 160
        height   : 76
    , account

    @avatarAreaIconMenu = new AvatarAreaIconMenu
      delegate     : @

    # Main Navigations
    @navController = new MainNavController
      view           : new KDListView
        type         : "navigation"
        itemClass    : NavigationLink
        testPath     : "navigation-list"
      wrapper        : no
      scrollView     : no
    ,
      title     : "navigation"
      items     : []

    navAdditions = [
      { type  : 'separator',            order : 65 }
      # { title : 'Invite Friends', order : 66,  type : 'account',   role : 'member' }
      { title : 'Up to 16GB free!',     order : 66,  type : 'account promote', promote: yes,   role : 'member' }
      { title : 'Docs / Jobs',          order : 67,  type : 'account docs', docs : yes }
      { type  : 'separator',            order : 99 }
      { title : 'Logout',               order : 100, path : '/Logout',   type : 'account', loggedIn : yes }
      { title : 'Login',                order : 101, path : '/Login',    type : 'account', loggedIn : no  }
      { title : 'Register',             order : 102, path : '/Register', type : 'account', loggedIn : no  }

    ]

    KD.registerNavItem navItem for navItem in navAdditions

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
      delegate          : this

    @dndUploadHolder = new KDView domId: "finder-dnduploader", cssClass: "hidden"
    @dndUploadHolder.addSubView @dnduploader = new DNDUploader hoverDetect: no

    _onDrag = =>
      unless @finderController.treeController.internalDragging
        @dndUploadHolder.show()
        @dnduploader.unsetClass "hover"

    @dnduploader.on "dragleave", => @dndUploadHolder.hide()
    @dnduploader.on "drop",      => @dndUploadHolder.hide()
    @dnduploader.on "cancel",    =>
      @dnduploader.setPath()
      @dndUploadHolder.hide()

    @finderController.treeController.on "dragEnter", _onDrag
    @finderController.treeController.on "dragOver",  _onDrag

    @finder = @finderController.getView()

    KD.registerSingleton "finderController", @finderController
    @finderController.on 'ShowEnvironments', => @finderBottomControlPin.click()

    @listenWindowResize()

  setListeners:->

    mainController                 = KD.getSingleton "mainController"
    mainViewController             = KD.getSingleton "mainViewController"
    mainView                       = KD.getSingleton "mainView"
    {@contentPanel, @sidebarPanel} = mainView
    $fp                            = @$('#finder-panel')
    cp                             = @contentPanel
    @wc                            = KD.getSingleton "windowController"
    fpLastWidth                    = null

    mainController.on "AvatarPopupIsActive",   => @_popupIsActive = yes
    mainController.on "AvatarPopupIsInactive", => @_popupIsActive = no

    # exception - Sinan, Jan 2013
    # we bind this with jquery directly bc #main-nav is no KDView but just HTML
    @$('#main-nav').on "mouseenter", @bound "animateLeftNavIn"
    @$('#main-nav').on "mouseleave", @bound "animateLeftNavOut"

    mainViewController.on "UILayoutNeedsToChange", @bound "changeLayout"
    @bindTransitionEnd()

  changeLayout:(options)->

    {type, hideTabs} = options
    windowController = KD.getSingleton 'windowController'

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

  dragLeave: ->
    super
    @dndUploadHolder.hide()

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
      {{> @nav}}
      {{> @footerMenu}}
    </div>
    <div id='finder-panel'>
      <div id='finder-header-holder'>
        {{> @finderHeader}}
      </div>

      {{> @dndUploadHolder}}

      <div id='finder-holder'>
        {{> @finder}}
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
    $fbc = @$('#finder-bottom-controls')
    $fbc.addClass 'in'
    @_windowDidResize()

  hideBottomControls:->
    $fbc = @$('#finder-bottom-controls')
    $fbc.css top : "100%"
    $fbc.removeClass 'in'
    @_windowDidResize()

  _resizeResourcesList:->
    $fbc     = @$('#finder-bottom-controls')
    $resList = $fbc.find('.resources-list')
    fbch     = $fbc.height()
    h        = @getHeight()

    $resList.css maxHeight : if fbch > h then h/2 else "none"

    return if $fbc.hasClass 'in'
      $fbc.css top : "#{100 - ((fbch = $fbc.height())-27) / h * 100}%"
      return fbch
    else 27

  _windowDidResize:->
    $fbc = @$('#finder-bottom-controls')
    h = @_resizeResourcesList()
    @$("#finder-holder").height @getHeight() - h - 26

  bottomControlsItems =
    id : "finder-bottom-controls"
    items : [
      {
        title   : "your servers",   icon : "resources",
        action  : "showEnvironments"
      }
    ]

  footerMenuItems =
    id    : "footer-menu"
    title : "footer-menu"
    items : [
      {
        title    : "Help",
        callback : ->
          KD.getSingleton('mainController').emit "ShowInstructionsBook"
      }
      {
        title    : "About",
        callback : -> @showAboutDisplay()
      }
      {
        title    : "Chat",
        callback : ->
          KD.getSingleton('mainController').emit "ToggleChatPanel"
      }
    ]
