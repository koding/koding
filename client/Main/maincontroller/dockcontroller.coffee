class DockController extends KDViewController

  defaultItems = [
    { title : "Activity",  path : "/Activity", order : 10, type :"" }
    { title : "Topics",    path : "/Topics",   order : 20, type :"" }
    { title : "Terminal",  path : "/Terminal", order : 30, type :"" }
    { title : "Editor",    path : "/Ace",      order : 40, type :"" }
    { title : "Apps",      path : "/Apps",     order : 50, type :"" }
    { title : "Teamwork",  path : "/Teamwork", order : 60, type :"" }
    # { title : "About",     path : "/About",    order : 70, type :"" }
  ]

  createHash = (arr)->

    hash = {}
    arr.forEach (item)-> hash[item.title] = item
    return hash


  constructor:(options = {}, data)->

    options.view or= new KDCustomHTMLView domId : 'dock'

    super options, data

    @storage = new AppStorage "Dock", "1.0"

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

    KD.setNavItems defaultItems
    @navController.reset()

    # Disabled until we figure out the flow of dock controller ~ GG
    #
    # @storage.fetchStorage (err, storage)=>

      # usersNavItems = @storage.getValue 'navItems'
      # ourNavItems   = defaultItems
      # ourNavObj     = createHash ourNavItems
      # KD.setNavItems ourNavItems

      # unless usersNavItems

      #   @navController.reset()
      #   log ourNavItems, 'ready'
      #   return @emit 'ready'

      # usersNavObj = createHash usersNavItems

      # # reset default items' orders if user has customized them
      # for ourItem in ourNavItems
      #   continue unless usersItem = usersNavObj[ourItem.title]
      #   log 'changing order for:', ourItem.title
      #   ourItem.order = usersItem.order

      # # add user's custom items in nav items
      # for usersItem in usersNavItems
      #   continue if ourNavObj[usersItem.title]
      #   KD.registerNavItem usersItem

      # # re-sort the navitems
      # KD.setNavItems KD.getNavItems()
      # @navController.reset()

      # @emit 'ready'

    mainController = KD.getSingleton 'mainController'
    mainController.ready @bound 'accountChanged'

    @emit 'ready'

  setItemOrder:(item, order = 0)->

    item.order = order
    KD.setNavItems KD.getNavItems()


  addItem:(item)->

    KD.registerNavItem item
    KD.setNavItems KD.getNavItems()


  removeItem:(item)->

    return unless index = KD.getNavItems().indexOf item > -1
    KD.getNavItems().splice index, 1


  accountChanged:->

    @navController.reset()

  setNavItemState:({name, navItem}, state)->
    navItem or={}
    for nav in @navController.itemsOrdered
      if nav.name is name or ///^#{navItem.path}///.test nav.data.path
        nav.setState state

  loadView:(dock)->

    @ready =>

      dock.addSubView @navController.getView()

      # Listen appManager to update dock items states
      {appManager, kodingAppsController} = KD.singletons

      kodingAppsController.on "LoadingAppScript", (name)=>
        @setNavItemState {name}, 'loading'

      appManager.on "AppRegistered", (name, {navItem}) =>
        @setNavItemState {name, navItem}, 'running'

      appManager.on "AppUnregistered", (name, {navItem}) =>
        @setNavItemState {name, navItem}, 'initial'


