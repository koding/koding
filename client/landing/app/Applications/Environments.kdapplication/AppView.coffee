class EnvironmentsMainView extends JView

  tabData = [
    name        : 'VMS'
    viewOptions :
      viewClass : VMMainView
  ,
    name        : 'Domains'
    viewOptions :
      viewClass : DomainMainView
  ]

  navData = 
    title : "Settings"
    items : ({title:item.name, hiddenHandle:'hidden'} for item in tabData)

  constructor:(options={}, data)->

    data or= {}
    super options, data

    @header = new HeaderViewSection type : "big", title : "Environments"
    @nav    = new KDView
      cssClass : "common-inner-nav"
    @tabs   = new KDTabView
      cssClass           : 'environment-content'
      tabHandleContainer : @nav
    , data

    @listenWindowResize()
    
    @once 'viewAppended', =>
      @createTabs()
      @_windowDidResize()

  createTabs:->
    for {name, viewOptions}, i in tabData
      @tabs.addPane new KDTabPaneView {name, viewOptions}, i is 0

    # @navController.selectItem @navController.itemsOrdered.first

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