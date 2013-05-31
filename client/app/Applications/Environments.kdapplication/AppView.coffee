class EnvironmentsMainView extends JView

  tabData = [
    name        : 'VMS'
    viewOptions :
      lazy      : no
      viewClass : VMMainView
  ,
    name        : 'Domains'
    viewOptions :
      lazy      : yes
      viewClass : DomainMainView
  ]

  navData =
    title : "Settings"
    items : ({ title : name } for {name} in tabData)

  constructor:(options={}, data)->

    data or= {}
    super options, data

    @header = new HeaderViewSection type : "big", title : "Environments"
    @nav    = new CommonInnerNavigation
    @tabs   = new KDTabView
      cssClass            : 'environment-content'
      hideHandleContainer : yes
    , data

    @setListeners()
    @createTabs()
    @once 'viewAppended', @bound "_windowDidResize"

  setListeners:->

    @listenWindowResize()
    @nav.on "viewAppended", =>
      navController = @nav.setListController
        itemClass : ListGroupShowMeItem
      , navData

      @nav.addSubView navController.getView()
      navController.selectItem navController.itemsOrdered.first

    @nav.on "NavItemReceivedClick", ({title})=> @tabs.showPaneByName title

  createTabs:->

    data = @getData()

    for {name, viewOptions} in tabData
      @tabs.addPane new KDTabPaneView {name, viewOptions}

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