class DockController extends KDViewController

  isRunning = (item) -> item?.state is 'running'

  defaultItems = [
    # { title : 'Social',  path : '/Activity', order : 10, type :'persistent' }
    { title : 'IDE',       path : '/IDE',      order : 20, type :'persistent' }
    { title : 'Teamwork',  path : '/Teamwork', order : 30, type :'persistent' }
    # { title : '+',      path : '/Apps',     order : 40, type :'persistent' }
    # { title : 'DevTools',  path : '/DevTools', order : 50, type :'persistent' }
    # { title : 'Environments',  path : '/Environments', order : 60, type :'persistent' }
  ]


  constructor:(options = {}, data)->

    options.view or= new KDCustomHTMLView domId : 'dock'

    super options, data

    @storage = new AppStorage "Dock", "1.0.3"

    loaderOptions =
      spinnerOptions    :
        size            :
          width         : 16
        loaderOptions   :
          color         : '#B8B8B8'

    @navController = new MainNavController
      view                : new NavigationList
        domId             : 'main-nav'
        testPath          : 'navigation-list'
        type              : 'navigation'
        itemClass         : NavigationLink
        testPath          : 'navigation-list'
      wrapper             : no
      scrollView          : no
      startWithLazyLoader : yes
      lazyLoaderOptions   : loaderOptions
    ,
      id           : 'navigation'
      title        : 'navigation'
      items        : []


    @vmsList = new KDListViewController
      wrapper             : no
      scrollView          : no
      startWithLazyLoader : yes
      itemClass           : NavigationVMItem
      lazyLoaderOptions   : loaderOptions
    ,
      id           : 'vms'
      title        : 'vms'
      items        : []

    @vmsList.getListView().on 'VMCogClicked', (vm, item)->
      {mainView} = KD.singletons
      mainView.openVMModal vm, item

    # {mainController} = KD.singletons
    # mainController.ready @bound 'accountChanged'

    @trackStateTransitions()
    @bindKeyCombos()


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
    @storage.fetchValue 'navItems', (usersNavItems) =>

      unless usersNavItems
        @setNavItems defaultItems
        return @emit 'ready'

      @setNavItems @buildNavItems usersNavItems
      @emit 'ready'


  getItems:->

    @navController.getView().items


  setNavItemState:({name, route, options}, state)->

    @ready =>

      if state is 'active'
        state  = 'running'
        select = yes

      options  or= {}
      {dockPath} = options

      route   or= options.navItem?.path or '-'

      for nav, i in @getItems()
        if (///^#{route}///.test nav.data.path) or (dockPath is nav.data.path) \
        or (nav.data.path is "/#{name}") or ("/#{name}" is nav.data.path) \
        or (nav.name is name)
          nav.setState state
          @navController.selectItem nav  if select
          hasNav = yes
          @emit 'NavItemStateChanged', { item: nav, index: i, state }

      if not hasNav and state isnt 'initial'
        unless name in Object.keys(KD.config.apps)
          path = if dockPath then dockPath else "/#{name}"
          @addItem { title : name, path, \
                     order : 60 + KD.utils.uniqueId(), type :"" }

  listVMs: (vms) ->

    @vmsList.hideLazyLoader()

    @vmsList.addItem vm  for vm in vms


  loadView: (dock) ->

    dock.addSubView new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'sidebar-title'
      partial  : 'MY APPS'

    dock.addSubView @navController.getView()
    dock.addSubView new CustomLinkView
      icon     : no
      cssClass : 'add-vm'
      title    : '+ Add more apps'
      href     : '/Apps'

    dock.addSubView new KDCustomHTMLView
      tagName  : 'h3'
      cssClass : 'sidebar-title'
      partial  : 'MY VMs'

    dock.addSubView @vmsList.getView()
    dock.addSubView new CustomLinkView
      icon     : no
      cssClass : 'add-vm'
      title    : '+ Add another VM'
      click    : ->
        # fixme: this is a temp solution
        # this should change with the new environments
        KD.singletons.appManager.require 'Environments', ->
          env = new EnvironmentMachineContainer
          env.emit 'PlusButtonClicked'
          @fetchVMs @bound 'listVMs'


    # @navController.reset()
    # @setNavItems defaultItems
    @setNavItems defaultItems
    @emit 'ready'

    if KD.userVMs.length
    then @listVMs KD.userVMs
    else @fetchVMs @bound 'listVMs'


    @ready =>

      # Listen appManager to update dock items states
      {appManager, kodingAppsController} = KD.singletons

      for name of appManager.appControllers
        @setNavItemState {name}, 'active'

      @navController.hideLazyLoader()

      {appManager, kodingAppsController} = KD.singletons

      appManager.on 'AppRegistered', (name, options) =>
        @setNavItemState {name, options}, 'running'

      appManager.on 'AppUnregistered', (name, options) =>
        @setNavItemState {name, options}, 'initial'

      appManager.on 'AppIsBeingShown', (instance, view, options) =>
        @setNavItemState {name:options.name, options}, 'active'


  fetchVMs: (callback)->

    {vmController} = KD.singletons

    # force refetch from server everytime vms fetched.
    vmController.fetchVMs force = yes, (err, vms) =>
      if err
        ErrorLog.create 'terminal: Couldn\'t fetch vms', reason : err
        return new KDNotificationView title : 'Couldn\'t fetch your VMs'

      vms.sort (a,b) -> a.hostnameAlias > b.hostnameAlias

      callback vms


  getRelativeItem: (increment, predicate) ->

    i = @activeIndex
    len = @navController.itemsOrdered.length
    loop
      i += increment
      if i < 0
        i += len
      else if len <= i
        i -= len
      item = @itemStates[i]
      return item  if item is this or predicate item


  activatePreviousApp: (e) ->

    e.preventDefault()
    item = @getRelativeItem -1, isRunning
    @setActiveItem item.item


  activateNextApp: (e) ->

    e.preventDefault()
    item = @getRelativeItem 1, isRunning
    @setActiveItem item.item


  setActiveItem: (item) ->

    KD.singletons.router.handleRoute item.getData().path


  trackStateTransitions: ->

    @itemStates = []
    @activeIndex = null
    @on 'NavItemStateChanged', (info) ->
      { index, item, state } = info
      @itemStates[index] = info
      @activeIndex = index  if state is 'running'


  openApp: (index) ->

    len = @navController.itemsOrdered.length
    index += len  if index < 0
    item = @navController.itemsOrdered[index]
    return  unless item?
    { path } = item.getData()
    KD.singletons.router.handleRoute path


  bindKeyCombos: ->

    { globalKeyCombos } = KD.singletons

    globalKeyCombos
      .addCombo 'command+option+[', @bound 'activatePreviousApp'
      .addCombo 'command+option+]', @bound 'activateNextApp'
      .addCombo 'command+option+1', => @openApp 0
      .addCombo 'command+option+2', => @openApp 1
      .addCombo 'command+option+3', => @openApp 2
      .addCombo 'command+option+4', => @openApp 3
      .addCombo 'command+option+5', => @openApp 4
      .addCombo 'command+option+6', => @openApp 5
      .addCombo 'command+option+7', => @openApp 6
      .addCombo 'command+option+8', => @openApp 7
      .addCombo 'command+option+9', => @openApp -1
