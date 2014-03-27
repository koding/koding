class DockController extends KDViewController

  defaultItems = [
    { title : "Activity",  path : "/Activity", order : 10, type :"persistent" }
    # { title : "Topics",    path : "/Topics",   order : 20, type :"persistent" }
    { title : "Teamwork",  path : "/Teamwork", order : 20, type :"persistent" }
    { title : "Terminal",  path : "/Terminal", order : 30, type :"persistent" }
    { title : "Editor",    path : "/Ace",      order : 40, type :"persistent" }
    { title : "Apps",      path : "/Apps",     order : 50, type :"persistent" }
    # { title : "About",     path : "/About",    order : 70, type :"persistent" }
    { title : "DevTools",  path : "/DevTools", order : 60, type :"persistent" }
  ]

  constructor:(options = {}, data)->

    options.view or= new KDCustomHTMLView domId : 'dock'

    super options, data

    @storage = new AppStorage "Dock", "1.0.3"

    @navController = new MainNavController
      view         : new NavigationList
        domId      : 'main-nav'
        testPath   : 'navigation-list'
        type       : 'navigation'
        itemClass  : NavigationLink
        testPath   : 'navigation-list'
      wrapper      : no
      scrollView   : no
    ,
      id           : 'navigation'
      title        : 'navigation'
      items        : []

    mainController = KD.getSingleton 'mainController'
    mainController.ready @bound 'accountChanged'

    @storage.fetchValue 'navItems', (usersNavItems)=>

      unless usersNavItems
        @setNavItems defaultItems
        return @emit 'ready'

      @setNavItems @buildNavItems usersNavItems
      @emit 'ready'

  buildNavItems:(sourceItems)->

    finalItems = []

    _sources = KD.utils.arrayToObject sourceItems, 'title'
    for defaultItem in defaultItems
      sourceItem = _sources[defaultItem.title]
      if sourceItem
        continue  if sourceItem.deleted
        sourceItem.type = defaultItem.type
        finalItems.push sourceItem
      else
        finalItems.push defaultItem

    _defaults = KD.utils.arrayToObject defaultItems, 'title'
    for sourceItem in sourceItems
      defaultItem = _defaults[sourceItem.title]
      unless defaultItem
        finalItems.push sourceItem

    return finalItems

  saveItemOrders:(items)->

    items or= @getItems()

    navItems = []
    for own index, item of items
      {data} = item
      data.order = index
      navItems.push data

    @storage.setValue 'navItems', navItems, (err)->
      warn "Failed to save navItems order", err  if err

  resetItemSettings:->
    item.order = index  for own index, item of defaultItems

    @storage.unsetKey 'navItems', (err)=>
      warn "Failed to reset navItems", err  if err

      KD.resetNavItems defaultItems
      @navController.reset()
      "Navigation items has been reset."

  setNavItems:(items)->
    KD.setNavItems items
    @navController.reset()

  addItem:(item)->

    if item not in @getItems()
      KD.registerNavItem item
      @navController.addItem item
      @saveItemOrders()

  removeItem:(item)->

    return  if item.data.type is 'persistent'

    {appManager, router} = KD.singletons
    appManager.quitByName item.name

    if (item.hasClass 'running') and (item.hasClass 'selected')
      if router.visitedRoutes.length > 1
      then router.back()
      else router.handleRoute '/Activity'

    @navController.removeItem item
    @saveItemOrders()

  accountChanged:->
    @navController.reset()

  getItems:->
    @navController.getView().items

  setNavItemState:({name, route, options}, state)->

    if state is 'active'
      state  = 'running'
      select = yes

    options  or= {}
    {dockPath} = options

    route   or= options.navItem?.path or '-'

    for nav in @getItems()
      if (///^#{route}///.test nav.data.path) or (dockPath is nav.data.path) \
      or (nav.data.path is "/#{name}") or ("/#{name}" is nav.data.path)
        nav.setState state
        @navController.selectItem nav  if select
        hasNav = yes

    if not hasNav and state isnt 'initial'
      unless name in Object.keys(KD.config.apps)
        path = if dockPath then dockPath else "/#{name}"
        @addItem { title : name, path, \
                   order : 60 + KD.utils.uniqueId(), type :"" }

  loadView:(dock)->

    @ready =>

      @scrollView = new KDCustomScrollView

      dock.addSubView @scrollView
      @scrollView.wrapper.addSubView @navController.getView()

      # Listen appManager to update dock items states
      {appManager, kodingAppsController} = KD.singletons

      for name of appManager.appControllers
        @setNavItemState {name}, 'active'

      {appManager, kodingAppsController} = KD.singletons

      appManager.on "AppRegistered", (name, options) =>
        @setNavItemState {name, options}, 'running'

      appManager.on "AppUnregistered", (name, options) =>
        @setNavItemState {name, options}, 'initial'

      appManager.on "AppIsBeingShown", (instance, view, options) =>
        @setNavItemState {name:options.name, options}, 'active'
