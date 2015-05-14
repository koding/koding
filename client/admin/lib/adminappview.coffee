kd                   = require 'kd'
KDView               = kd.View
KDTabPaneView        = kd.TabPaneView

globals              = require 'globals'
AdminMainTabPaneView = require './views/adminmaintabpaneview'


module.exports = class AdminAppView extends kd.View

  constructor: (options = {}, data) ->

    options.testPath = 'groups-admin'
    data           or= kd.singletons.groupsController.getCurrentGroup()

    super options, data

    @addSubView @nav  = new kd.TabHandleContainer
      cssClass: 'AppModal-nav'

    @addSubView @tabs = new AdminMainTabPaneView
      tabHandleContainer: @nav
    , data

    @nav.unsetClass 'kdtabhandlecontainer'

    @setListeners()


  setListeners: ->

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

    data         = @getData()
    {tabData}    = @getOptions()
    currentGroup = kd.singletons.groupsController.getCurrentGroup()

    items = []

    for own sectionKey, section of tabData

      if sectionKey is 'koding' and currentGroup.slug isnt 'koding'
        continue

      items = items.concat section.items


    items.forEach (item, i) =>

      { viewClass, slug, title } = item

      pane = new KDTabPaneView name: slug
      pane.addSubView new viewClass
        cssClass : slug
        delegate : this
      , data

      @tabs.addPane pane, i is 0

    @emit 'ready'


  search: (searchValue) ->

    if @tabs.getActivePane().name is 'Invitations'
      pane = @tabs.getActivePane()
    else
      pane = @tabs.getPaneByName 'Members'
      @tabs.showPane pane

    pane?.mainView?.emit 'SearchInputChanged', searchValue
