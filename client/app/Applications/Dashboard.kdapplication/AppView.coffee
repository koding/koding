class DashboardAppView extends JView

  constructor:(options={}, data)->

    options.cssClass or= "content-page"
    data or= @getSingleton("groupsController").getCurrentGroup()
    super options, data

    @header = new HeaderViewSection type : "big", title : "Dashboard"
    @nav    = new CommonInnerNavigation
    @tabs   = new KDTabView
      cssClass            : 'group-content'
      hideHandleContainer : yes
    , data

    @setListeners()
    @once 'viewAppended', =>
      @createTabs()
      @_windowDidResize()


    @myView = new KDInputView
      focus: => @setKeyView()

  setListeners:->

    @listenWindowResize()
    @nav.on "viewAppended", =>
      @navController = @nav.setListController
        itemClass : ListGroupShowMeItem
      ,
        title     : "SHOW ME"
        items     : []

      @nav.addSubView @navController.getView()

    @nav.on "NavItemReceivedClick", ({title})=> @tabs.showPaneByName title

  createTabs:->

    data = @getData()
    @getSingleton('appManager').tell 'Dashboard', 'fetchTabData', (tabData)=>
      navItems = []
      for {name, viewOptions}, i in tabData
        viewOptions.data = data
        @tabs.addPane (pane = new KDTabPaneView {name, viewOptions}), !(~i+1) # making 0 true the rest false
        navItems.push { title : name }

      @navController.instantiateListItems navItems
      @navController.selectItem @navController.itemsOrdered.first




  _windowDidResize:->
    contentHeight = @getHeight() - @header.getHeight()
    @$('>section, >aside').height contentHeight

  pistachio:->
    """
      {{> @header}}
      <aside class='fl'>
        {{> @nav}}
      </aside>
      <section class='right-overflow'>
        {{> @tabs}}
      </section>
    """