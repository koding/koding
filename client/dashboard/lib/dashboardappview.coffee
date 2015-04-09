kd                            = require 'kd'
KDTabPaneView                 = kd.TabPaneView
KDTabView                     = kd.TabView
KDView                        = kd.View
globals                       = require 'globals'


module.exports = class DashboardAppView extends kd.ModalView

  constructor:(options={}, data)->

    options.cssClass = 'AppModal AppModal--dashboard'
    options.width    = 800
    options.height   = 600
    options.testPath = 'groups-dashboard'
    data             or= kd.singletons.groupsController.getCurrentGroup()

    super options, data

    @addSubView @tabs = new KDTabView
      cssClass    : 'dashboard-tabs'
      detachPanes : yes
    , data

    @tabs.tabHandleContainer.setClass 'AppModal-nav'

    @setListeners()


  setListeners:->

    @on 'groupSettingsUpdated', (group)->
      @setData group
      @createTabs()

    @tabs.on 'PaneAdded', (pane) ->
      # pane.unsetClass 'kdtabpaneview'
      pane.setClass 'AppModal-content'
      { tabHandle } = pane
      tabHandle.setClass 'AppModal-navItem'
      tabHandle.unsetClass 'kdtabhandle'


  viewAppended: ->

    group = kd.getSingleton("groupsController").getCurrentGroup()
    group?.canEditGroup (err, success)=>
      if err or not success
        {entryPoint} = globals.config
        kd.getSingleton('router').handleRoute "/Activity", { entryPoint }
      else
        @createTabs()


  createTabs:->

    data = @getData()
    kd.getSingleton('appManager').tell 'Dashboard', 'fetchTabData', (tabData)=>
      navItems = []
      for {name, hiddenHandle, viewOptions, kodingOnly}, i in tabData
        viewOptions.data    = data
        viewOptions.options = delegate : this  if name is 'Settings'
        hiddenHandle        = hiddenHandle? and data.privacy is 'public'
        @tabs.addPane (pane = new KDTabPaneView {name, viewOptions}), i is 0
        # # Push all items, however if it has 'kodingOnly' push only when the group is really 'koding'
        # if data.slug is 'koding'
        #   navItems.push {title : name, slug : "/Dashboard/#{name}", type : if hiddenHandle then 'hidden' else null}
        # if data.slug isnt 'koding' and not kodingOnly
        #   navItems.push {title : name, slug : "/#{data.slug}/Dashboard/#{name}", type : if hiddenHandle then 'hidden' else null}

      @emit 'ready'


  search: (searchValue)->
    if @tabs.getActivePane().name is 'Invitations'
      pane = @tabs.getActivePane()
    else
      pane = @tabs.getPaneByName "Members"
      @tabs.showPane pane
    {mainView} = pane
    return unless mainView
    mainView.emit 'SearchInputChanged', searchValue



