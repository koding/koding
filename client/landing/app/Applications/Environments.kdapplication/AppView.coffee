class EnvironmentsMainView extends JView

  tabData = [
    { name : 'VMs',              lazy : no,   itemClass : VMMainView }
    { name : 'Domains',          lazy : yes,  itemClass : DomainMainView }
  ]

  navData =
    title : "Settings"
    items : ({ title : name } for {name} in tabData)

  constructor:(options={}, data)->

    options.cssClass or= "content-page"
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

    for {name, lazy, itemClass} in tabData
      @tabs.addPane new KDTabPaneView {
        view : {itemClass, data}
        name
        lazy
      }

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