class Account12345 extends AppController
  constructor:(options={},data)->
    options.view = new KDView {cssClass : "content-page" }
    super options, data
    @itemsOrdered = []
  
  bringToFront:()->
    super name : 'Account', type : 'background'
    
  loadView:(mainView)->
    items = @items
    
    # SET UP VIEWS
    @navController = new AccountSideBarController
      domId : "account-nav"
    navView = @navController.getView()

    @wrapperController = new AccountContentWrapperController
      domId     : "account-content-wrapper"
    wrapperView = @wrapperController.getView()
    
    
    #ADD CONTENT SECTIONS
    @navController.sectionControllers = []
    @wrapperController.sectionLists = []
    for own sectionKey, section of items
      navView.addSubView navSection = new KDTreeView
        type        : sectionKey
        cssClass    : "settings-menu"
      navView.addSubView new KDCustomHTMLView "hr"
      @navController.sectionControllers.push new AccountNavigationController
        view : navSection
        subItemClass : AccountNavigationLink
      , section
      
      navSection.registerListener
        KDEventTypes  : "AccountNavLinkTitleClick"
        listener      : @
        callback      : (sectionController, navItem)=>
          @wrapperController.scrollTo @indexOfItem navItem.getData()
      
      
      for own itemKey,item of section.items
        @itemsOrdered.push item
        section.id = sectionKey
        wrapperView.addSubView wrapper = new AccountListWrapper
          cssClass : "settings-list-wrapper #{__utils.slugify(item.title)}"
        ,{item,section}
        @wrapperController.sectionLists.push wrapper
    

    # SET UP SPLIT VIEW AND TOGGLERS
    @split = split = new KDSplitView
      domId     : "account-split-view"
      sizes     : [188,null]
      views     : [navView,wrapperView]
      minimums  : [null,null]
      resizable : yes
    mainView.addSubView split
    
    split.panels[1].registerListener
      KDEventTypes : "scroll"
      listener     : @
      callback     : @contentScrolled
    
    split.panels[0].addSubView @leftToggler = new KDView 
      cssClass : "account-sidebar-toggler left"

    @listenTo 
      KDEventTypes        : "click"
      listenedToInstance  : @leftToggler
      callback            : -> @toggleSidebar show:no
    
    split.addSubView @rightToggler = new KDView 
      cssClass : "account-sidebar-toggler right"

    @listenTo
      KDEventTypes        : "click"
      listenedToInstance  : @rightToggler
      callback            : -> @toggleSidebar show:yes

    @rightToggler.hide()

    @_windowDidResize()
    @getSingleton("windowController").registerWindowResizeListener @
  
  contentScrolled:(pubInst,event)->
    @__lastScrollTop or= 0
    newScrollTop = pubInst.$().scrollTop()
    return if @__lastScrollTop is newScrollTop

    topIndex = @wrapperController.getSectionIndexForScrollOffset newScrollTop
    @navController.setActiveNavItem topIndex
    
    @__lastScrollTop = newScrollTop
  
  _windowDidResize:()->
    lastWrapper = @wrapperController.sectionLists[@wrapperController.sectionLists.length-1]
    lastWrapper.setHeight @navController.getView().getHeight()

  toggleSidebar:(options)->
    {show} = options
    controller = @
    
    split = @split
    if show
      split.showPanel 0, ->
        controller.rightToggler.hide()
        controller.leftToggler.show()
    else
      split.hidePanel 0, ->
        controller.rightToggler.show()
        controller.leftToggler.hide()
  
  indexOfItem:(item)->
    @itemsOrdered.indexOf item

  items :
    personal :
      title : "Personal"
      items : [
        { title : "Login & Email",        listHeader: "Email & username",           listType: "username",       id : 10,      parentId : null }
        { title : "Password & Security",  listHeader: "Password & Security",        listType: "security",       id : 20,      parentId : null }
        { title : "Linked accounts",      listHeader: "Your Linked Accounts",       listType: "linkedAccounts", id : 30,      parentId : null }
      ]                                                                                    
    develop :                                                                                                   
      title : "Develop"                                                                                         
      items : [                                                                                                 
        { title : "Database settings",    listHeader: "Database Settings",          listType: "databases",      id : 15,      parentId : null }
        { title : "Repository settings",  listHeader: "Repository Settings",        listType: "repos",          id : 20,      parentId : null }
        { title : "Manage mounts",        listHeader: "Registered Mounts",          listType: "mounts",         id : 30,      parentId : null }
        { title : "Editor settings",      listHeader: "Editor Settings",            listType: "editors",        id : 10,      parentId : null }
        { title : "SSH Keys",             listHeader: "SSH Keys",                   listType: "keys",           id : 40,      parentId : null }
      ]
    billing :
      title : "Billing"                                                                    
      items : [                                                                            
        { title : "Payment methods",      listHeader: "Your Payment Methods",       listType: "methods",        id : 10,      parentId : null }
        { title : "Your subscriptions",   listHeader: "Your Active Subscriptions",  listType: "subscriptions",  id : 20,      parentId : null }
        { title : "Billing history",      listHeader: "Billing History",            listType: "history",        id : 30,      parentId : null }
      ]                                                                                                         


class AccountSideBarController extends KDViewController
  constructor:(options, data)->
    options.view = new KDView domId : options.domId
    super options, data

  loadView:(mainView)->
    allNavItems = []
    for controller in @sectionControllers
      allNavItems = allNavItems.concat controller.itemsOrdered
    
    @allNavItems = allNavItems
       
    @setActiveNavItem 0
  
  setActiveNavItem:(index)->    
    sectionControllers = @sectionControllers
    totalIndex    = 0
    controllerIndex = 0
    while index >= totalIndex
      activeNavController = sectionControllers[controllerIndex]
      controllerIndex++
      totalIndex += activeNavController.itemsOrdered.length
    
    activeNavItem = @allNavItems[index]
    
    @unselectAllNavItems activeNavController
    activeNavController.makeItemSelected activeNavItem
  
  unselectAllNavItems:(clickedController)->
    for controller in @sectionControllers
      controller.makeAllItemsUnselected() unless clickedController is controller


class AccountContentWrapperController extends KDViewController
  constructor:(options,data)->
    options.view = new KDView domId : options.domId
    super options, data
    
  loadView:(mainView)->
    items = @getData()
  
  getSectionIndexForScrollOffset:(offset)->
    sectionIndex = 0
    while @sectionLists[sectionIndex + 1]?.$().position().top <= offset
      sectionIndex++
    sectionIndex
  
  scrollTo:(index)->
    itemToBeScrolled = @sectionLists[index]
    
    scrollToValue = itemToBeScrolled.$().position().top
    
    @getView().parent.$().animate scrollTop : scrollToValue, 300


class AccountNavigationController extends KDTreeViewController
  loadView:(mainView)->
    mainView.setPartial "<h3>#{@getData().title}</h3>"
    super
  #overriden to make items selected only by scroll
  itemMouseUp: (publishingInstance,event) ->