class SidebarController extends KDViewController
  createAvatarArea:(sidebar)->
    # CREATE AVATAR AREA PLACEHOLDER
    @mainNav.addSubView @avatarAreaPlaceHolder = new KDView
      cssClass : "avatar-placeholder"
    sidebar.avatarAreaPlaceHolder = @avatarAreaPlaceHolder

  createAvatarAreaMenu:(sidebar)->
    @mainNav.addSubView @avatarAreaIconMenu = new AvatarAreaIconMenu
      delegate : sidebar
  
  createMainNav:()->
    # CREATE MAIN NAVIGATION
    nav = new NavigationList
      type         : "navigation"
      domId        : "navigation-menu"
      cssClass     : "navigation-menu"
      subItemClass : NavigationLink
    
    @navController = new NavigationController
      view          : nav
      wrapper       : no
      scrollView    : no
    
    @mainNav.addSubView @navController.getView()
    @mainNav.addSubView new KDView
      cssClass : "avatar-separator"

    @navController.registerListener 
      KDEventTypes : "ItemSelectedEvent"
      listener     : @
      callback     : =>
        @makeAccountNavigationItemsUnselected()

  createAccountNav:()->
    @accNav = new NavigationList
      type         : "acc-navigation"
      domId        : "acc-navigation-menu"
      cssClass     : "navigation-menu"
      subItemClass : NavigationLink

    @accNavController = new NavigationController
      view         : @accNav
      wrapper      : no
      scrollView   : no

    @mainNav.addSubView @accNavController.getView()
    
    @accNavController.registerListener
      KDEventTypes : "ItemSelectedEvent"
      listener     : @
      callback     : =>
        @makeNavigationItemsUnselected()
  
  createFinder:(sidebar)->
    # create Finder
    sidebar.addSubView @finderPanel = sidebar.finderPanel = new KDView
      domId : "finder-panel"

    @finderPanel.addSubView @finderHeaderHolder = new KDView
      domId : "finder-header-holder"
    sidebar.finderHeaderHolder = @finderHeaderHolder
    
    @finderPanel.addSubView @finderHolder = sidebar.finderHolder = new KDView
      domId : "finder-holder"

    @finderPanel.addSubView @finderBottomControlsHolder = new KDView
      domId : "finder-bottom-controls"
    sidebar.finderBottomControlsHolder = @finderBottomControlsHolder
    
    @finderBottomControlsHolder.addSubView finderSettingsBorder = new KDCustomHTMLView
      tagName : "div"
      cssClass : "finder-settings-border"
    
    # @finderPanel.hide()
  
  createEnvSidebar:->
    # envSettingsSideBar = new EnvironmentSideBar domId : "environment-sidebar"
    # envSettingsSideBar.setHeight "auto"
    # @envSettingsSideBarController = new EnvironmentSideBarController view : envSettingsSideBar
    
  loadView:(sidebar)->

    sidebar.addSubView @mainNav = new KDView 
      domId : "main-nav"
      bind  : "mouseenter mouseleave"
    
    @createAvatarArea sidebar
    @createAvatarAreaMenu sidebar
    @createMainNav()
    @createAccountNav()
    @createFinder sidebar
    @createEnvSidebar()
    
    sidebar.listenWindowResize()
    
    _mouseenterTimeout    = null
    _mouseleaveTimeout    = null
    @_avatarPopupIsActive = no

    sidebar.registerListener
      KDEventTypes        : "AvatarPopupIsActive"
      listener            : @
      callback            : => 
        @_avatarPopupIsActive = yes

    sidebar.registerListener
      KDEventTypes        : "AvatarPopupIsInactive"
      listener            : @
      callback            : =>
        @_avatarPopupIsActive = no

    # Mouseenter listener for sidebar
    controller = @
    @listenTo 
      KDEventTypes        : "mouseenter"
      listenedToInstance  : @mainNav
      callback            : ()->
        clearTimeout _mouseleaveTimeout if _mouseleaveTimeout
        _mouseenterTimeout = setTimeout ()->
          controller._mouseentered = yes
          sidebar.expandNavigationPanel() if sidebar._onDevelop
        ,200

    # Mouseleave listener for sidebar
    @listenTo 
      KDEventTypes        : "mouseleave"
      listenedToInstance  : @mainNav
      callback            : ()=>
        return if @_avatarPopupIsActive
        clearTimeout _mouseenterTimeout if _mouseenterTimeout
        _mouseleaveTimeout = setTimeout ()->
          if controller._mouseentered and sidebar._onDevelop
            sidebar.collapseNavigationPanel()
        ,200
        
  
  accountChanged:(account)->

    {profile} = account

    @navController.removeAllItems()
    @accNavController.removeAllItems()
    @avatarAreaIconMenu.accountChanged account

    if @getSingleton('mainController').isUserLoggedIn()
      accNavItems = @accNavItemsLoggedIn
      navItems = @navItemsLoggedIn
    else
      accNavItems = @accNavItemsLoggedOut
      navItems = @navItemsLoggedOut

    # log navItems.items,"here????"
    @navController.instantiateListItems navItems.items
    @accNavController.instantiateListItems accNavItems.items
    
    # @finderController?.destroy()
    @jFinderController?.destroy()

    # @finderController = new FinderController null, {items : []}
    @jFinderController = new NFinderController
      fsListeners : yes
      initialPath : "/Users/#{profile.nickname}/Sites/#{profile.nickname}.beta.koding.com/website"
    
    @finderHeaderHolder.destroySubViews()
    @finderHolder.destroySubViews()
    @finderBottomControlsHolder.destroySubViews()
    
    @finderHeaderHolder.addSubView finderHeader = new KDHeaderView
      type  : "medium"
      title :"#{profile?.nickname}.#{location.hostname}"

    @finderHeaderHolder.addSubView resizeHandle = new SidebarResizeHandle
      domId : "finder-resize-handle"

    mainView    = @getView().getDelegate()
    {contentPanel,sidebarPanel} = mainView
    
    resizeHandle.on "DragStarted", (e, dragState)=>
      contentPanel._left = parseInt(contentPanel.$().css("left"), 10)
      contentPanel.unsetClass "transition"

    resizeHandle.on "DragFinished", (e, dragState)=> 
      delete contentPanel._left
      contentPanel.setClass "transition"
    
    resizeHandle.on "DragInAction", (x, y)=>
      contentPanel.$().css "left", contentPanel._left - x

    # @finderHolder.addSubView @finderController.getView()
    @finderHolder.addSubView @jFinderController.getView()
    
    finderBottomControls = new FinderBottomControls
    finderBottomControlsController = new KDListViewController 
      view : finderBottomControls
    ,@bottomControlsListData

    @finderBottomControlsHolder.addSubView finderBottomControlsController.getView()

    @setAvatarArea account

  setAvatarArea:(account)->
    @avatarArea.destroy() if @avatarArea?
    @avatarArea = new AvatarArea {domId : "avatar-area", delegate : @}, {account}
    @avatarAreaPlaceHolder.addSubView @avatarArea

  navItemsLoggedIn :
      id    : "navigation"
      title : "navigation"
      items : [
        { title : "Activity", id : 11,  path : "Activity" }
        { title : "Topics",   id : 20,  path : "Topics"   }
        { title : "Members",  id : 30,  path : "Members"  }
        { title : "Develop",  id : 40,  path : "StartTab" }
        { title : "Apps",     id : 50,  path : "Apps"     }
        # { title : "Demos",    id : 60,  path : "Demos"    }
      ]                                               

  navItemsLoggedOut :
      id    : "navigation"
      title : "navigation"
      items : [
        { title : "Home",     id : 10,  path : "Home"     }
        { title : "Activity", id : 11,  path : "Activity" }
        { title : "Topics",   id : 20,  path : "Topics"   }
        { title : "Members",  id : 30,  path : "Members"  }
        # { title : "Develop",  id : 40,  path : "Ace"      }
        { title : "Apps",     id : 50,  path : "Apps"     }
        # { title : "Demos",    id : 60,  path : "Demos"    }
      ]                                               

  # appItems :
  #   id    : "applications"
  #   items : [
  #     { title : "Ace",                id : 10,  appName : 'ace'}
  #     { title : "Shell",              id : 20,  appName : 'shell'}
  #     { title : "Aviary Phoenix",     id : 30,  appName : 'phoenix'}
  #     { title : "Pacman Forever",     id : 40,  appName : 'pacman'}
  #   ]


  accNavItemsLoggedIn :
      id    : "acc-navigation"
      title : "acc-navigation"
      items : [
        { title : "Invite Friends", id : 10 }
        { title : "Beta Feedback",  id : 20, path : "Tender.kdapplication" }
        { title : "Account",        id : 30, path : "Account" }
        { title : "Logout",         id : 40 }
      ]


  accNavItemsLoggedOut :
      id    : "acc-navigation"
      title : "acc-navigation"
      items : [
        # { title : "Account", id : 10, path : "Account" }
        { title : "Login",   id : 20, path : "Login" }
      ]

  bottomControlsListData :
    id : "finder-bottom-controls"
    items : [
      { title : "Launch Terminal",    icon : "terminal", path : "Shell"}
      { title : "Add Resources",      icon : "resources" }
      { title : "Settings",           icon : "cog" }#      , path : "Environment" }
      { title : "Keyboard Shortcuts", icon : "shortcuts", action: "showShortcuts" }
    ]


class Sidebar extends KDView
  constructor:->
    super
    @_onDevelop       = no
    @_finderExpanded  = no

  viewAppended:->
    mainView    = @getDelegate()
    {@contentPanel,@sidebarPanel} = mainView
    super

  expandNavigationPanel:(newSize,callback)->
    # @avatarAreaPlaceHolder.$().animate marginLeft : 0,300
    @avatarAreaPlaceHolder.unsetClass "collapsed"
    @finderPanel.unsetClass "expanded"
    setTimeout =>
      callback?()
    , 300

  collapseNavigationPanel:(callback)->
    # @avatarAreaPlaceHolder.$().animate marginLeft : -80,300
    @avatarAreaPlaceHolder.setClass "collapsed"
    @finderPanel.setClass "expanded"
    setTimeout =>
      callback?()
      @handleEvent type : "NavigationPanelWillCollapse"
    , 300
    
  expandEnvironmentSplit:(newSize,callback)->
    newSize          = 260
    @_finderExpanded = yes
    # @finderPanel.show()
    @contentPanel.setClass "with-finder"
    @contentPanel.unsetClass "social"
    setTimeout =>
      callback?()
      @_windowDidResize()
    , 300
      # @triggerResize()

  collapseEnvironmentSplit:(callback)->
    @contentPanel.unsetClass "with-finder"
    @contentPanel.setClass "social"
    setTimeout =>
      @_finderExpanded = no
      callback?()
      # @triggerResize()
      # @finderPanel.hide()
    , 300

  showEnvironmentPanel:->
    @showFinderPanel()
    
  showFinderPanel:->
    sidebar = @
    unless @_finderExpanded
      @collapseNavigationPanel()
      @expandEnvironmentSplit null, ()->
        sidebar._onDevelop = yes
  
  hideFinderPanel:->
    sidebar = @
    if @_finderExpanded
      @expandNavigationPanel 160,()->
        sidebar._onDevelop = no
      @collapseEnvironmentSplit()

  triggerResize:()-> 
    # this needs to be smoother
    # @getSingleton("windowController").notifyWindowResizeListeners()
  
  _windowDidResize:->
    bottomListHeight = @finderBottomControlsHolder.getHeight() or 109
    # when finderpanel is hidden we cant get the height thats why this is hardcoded
    # should be fixed
    @finderHolder.setHeight @getHeight() - @finderHeaderHolder.getHeight() - bottomListHeight



# BADGE NOTIFICATION UPDATE LISTENER
# navController.listenTo
#   KDEventTypes : "BadgeNotificationUpdate"
#   callback : (pubInst,event)=>
#     {itemName} = event
#     navItem = null
#     for item in navController.itemsOrdered
#       if item.getData().title is itemName
#         navItem = item
#         break
#     navItem.newItemsBadge.update 1


class SidebarResizeHandle extends KDView
  
  constructor:(options, data)->
    
    options.bind = "mousemove"
    
    super options, data

    @setDraggable
      axis : "x"
