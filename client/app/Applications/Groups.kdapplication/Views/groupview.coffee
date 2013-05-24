class GroupView extends ActivityContentDisplay

  constructor:->

    super

    data = @getData()
    @unsetClass "kdscrollview"

    {JGroup} = KD.remote.api

    @staleTabs = []
    @createTabs()
    @listenWindowResize()

  createLazyTab:(tabName, konstructor, options, initializer)->
    if 'function' is typeof options
      initializer = options
      options = {}

    pane = new KDTabPaneView name: tabName
    pane.once 'PaneDidShow', =>
      view = new konstructor options ? {}, @getData()
      pane.addSubView view
      initializer?.call? pane, pane, view

    @tabView.addPane pane, no

    return pane

  setStaleTab:(tabName)->
    @staleTabs.push tabName unless @staleTabs.indexOf(tabName) > -1

  unsetStaleTab:(tabName)->
    @staleTabs.splice @staleTabs.indexOf(tabName), 1

  isStaleTab:(tabName)->
    @staleTabs.indexOf(tabName) > -1

  createTabs:->
    data = @getData()
    @tabHandles = new KDCustomHTMLView
      tagName : 'nav'
    @tabView = new KDTabView
      cssClass             : 'group-content'
      hideHandleCloseIcons : yes
      maxHandleWidth       : 200
      tabHandleView        : GroupTabHandleView
      tabHandleContainer   : @tabHandles
    , data
    @utils.defer => @emit 'ReadmeSelected'

    @tabView.on "viewAppended", @bound "_windowDidResize"
    @on "viewAppended", @bound "_windowDidResize"

  privateGroupOpenHandler: GroupsAppController.privateGroupOpenHandler

  viewAppended: JView::viewAppended

  _windowDidResize:->
    @tabView.setHeight @getHeight() - @$('h2.sub-header').height()

  pistachio:->
    """
    <h2 class="sub-header kdmodal-content">
      {{> @back}}
      {{> @tabHandles}}
    </h2>
    {{> @tabView}}
    """
