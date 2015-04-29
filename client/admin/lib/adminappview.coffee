kd            = require 'kd'
KDTabPaneView = kd.TabPaneView
KDTabView     = kd.TabView
KDView        = kd.View
globals       = require 'globals'


module.exports = class AdminAppView extends kd.ModalView

  constructor:(options={}, data)->

    options.cssClass = 'AppModal AppModal--admin'
    options.width    = 1000
    options.height   = 600
    options.testPath = 'groups-admin'
    data           or= kd.singletons.groupsController.getCurrentGroup()

    super options, data

    @addSubView @nav  = new kd.TabHandleContainer cssClass : 'AppModal-nav'
    @addSubView @tabs = new KDTabView
      cssClass             : 'AppModal--admin-tabs AppModal-content'
      detachPanes          : yes
      maxHandleWidth       : Infinity
      minHandleWidth       : 0
      hideHandleCloseIcons : yes
      tabHandleContainer   : @nav
    , data
    @nav.unsetClass 'kdtabhandlecontainer'

    @setListeners()


  setListeners:->

    @on 'groupSettingsUpdated', (group)->
      @setData group
      @createTabs()

    @tabs.on 'PaneAdded', (pane) ->
      { tabHandle } = pane
      tabHandle.setClass 'AppModal-navItem'
      tabHandle.unsetClass 'kdtabhandle'


  viewAppended: ->

    group = kd.getSingleton("groupsController").getCurrentGroup()
    group?.canEditGroup (err, success) =>
      if err or not success
        {entryPoint} = globals.config
        kd.singletons.router.handleRoute "/Activity", { entryPoint }
      else
        @createTabs()


  createTabs: ->

    data = @getData()

    kd.singletons.appManager.tell 'Admin', 'fetchTabData', (tabData) =>

      for {name, hiddenHandle, viewOptions, kodingOnly}, i in tabData

        viewOptions.data    = data
        viewOptions.options = delegate : this  if name is 'Settings'
        hiddenHandle        = hiddenHandle? and data.privacy is 'public'
        pane                = new KDTabPaneView {name, viewOptions}

        @tabs.addPane pane, i is 0

      @emit 'ready'

      # borrow invitations tab styling
      # should be implemented by refactoring stylus
      @tabs.getPaneByName('Members').setClass 'invitations'


  search: (searchValue)->
    if @tabs.getActivePane().name is 'Invitations'
      pane = @tabs.getActivePane()
    else
      pane = @tabs.getPaneByName "Members"
      @tabs.showPane pane
    {mainView} = pane
    return unless mainView
    mainView.emit 'SearchInputChanged', searchValue



