class DashboardAppView extends JView

  tabData = [
    { name : 'Readme',            lazy : no,  itemClass : GroupReadmeView }
    { name : 'Settings',          lazy : yes, itemClass : GroupGeneralSettingsView }
    { name : 'Permissions',       lazy : yes, itemClass : GroupPermissionsView }
    { name : 'Members',           lazy : yes, itemClass : GroupsMemberPermissionsView }
    { name : 'Membership policy', lazy : yes, itemClass : GroupsMembershipPolicyView }
    { name : 'Invitations',       lazy : yes, itemClass : GroupsInvitationRequestsView }
  ]

  navData =
    title : "SHOW ME"
    items : ({ title : name } for {name} in tabData)

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