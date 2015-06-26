_                = require 'lodash'
kd               = require 'kd'
IDEView          = require '../views/tabview/ideview'
KDObject         = kd.Object
KDSplitView      = kd.SplitView
KDTabPaneView    = kd.TabPaneView
KDSplitViewPanel = kd.SplitViewPanel


## This class creates a layout data for remembering the tab layout.
## You can see `/client/ide/docs/idelayoutmanager.md` for more information
## about this.
module.exports = class IDELayoutManager extends KDObject


  ###*
   * Create layout data.
   *
   * @return {Array} @layout
  ###
  createLayoutData: ->

    @layout       = [] # Reset and create an array.

    workspaceView = @getDelegate().workspace.getView()
    baseSplitView = workspaceView.layout.getSplitViewByName 'BaseSplit'
    splitViews    = baseSplitView.panels.last.getSubViews().first.getSubViews().first

    if splitViews instanceof IDEView
      @createParentSplitViews splitViews
    else

      for panel in splitViews.panels when panel
        @createParentSplitViews panel

    return @layout


  ###*
   * Create first split panels.
   *
   * @param {KDSplitViewPanel} parent
  ###
  createParentSplitViews: (parent) ->

    @layout.push
      type      : 'split',
      direction : if parent.vertical is true then 'vertical' else 'horizontal'
      views     : @drillDown parent


  ###*
   * Seach in each dom structure.
   *
   * @param {KDSplitViewPanel} splitViewPanel
  ###
  drillDown: (splitViewPanel) ->

    @subViews = []
    @getSubLevel splitViewPanel
    return @subViews


  ###*
   * Get/find last split object in data structure.
   *
   * <Recursive>
   * @param {Object} items
  ###
  findLastSplitView: (items) ->

    return  if _.isEmpty(items) or items.last.context

    lastViews = items.last.views

    if lastViews.length is 0 or (lastViews.length > 0 and lastViews.last.context)
      return items.last
    else
      @findLastSplitView lastViews


  ###*
   * Search in views and create sub levels.
   *
   * <Recursive>
   * @param {(KDSplitViewPanel|KDSplitView|IDEView|KDTabPaneView|IDEApplicationTabView)} target
   * @return {Array} subViews
  ###
  getSubLevel: (target) ->

    if target instanceof KDSplitViewPanel
      @getSubLevel target.getSubViews().first

    else if target instanceof KDSplitView

      { panels } = target

      if panels.length is 2
        splitView = @findLastSplitView @subViews

        @createSplitView panels.first, splitView, yes
        @createSplitView panels.last,  splitView
      else
        @getSubLevel panels.first

    else if target instanceof IDEView

      for pane in target.tabView.panes
        @getSubLevel pane

    else if target instanceof KDTabPaneView
      return  unless target.view.serialize

      pane = context : target.view.serialize()
      last = @findLastSplitView @subViews

      if last
      then last.views.push pane
      else @subViews.push pane


  ###*
   * Create a split view object item.
   *
   * @param {string} direction
   * @param {Object} parentView
   * @param {boolean} isFirst
  ###
  createSplitView: (panel, parentView, isFirst = no) ->

    item =
      type      : 'split'
      direction : if panel.vertical then 'vertical' else 'horizontal'
      isFirst   : isFirst
      views     : []

    if parentView
    then parentView.views.push item
    else @subViews.push item

    @getSubLevel panel


  ###*
   * Resurrect saved snapshot from server.
   *
   * @param {Array} snapshot
  ###
  resurrectSnapshot: (snapshot) ->

    delegate = @getDelegate()

    # if has the fake view
    delegate.mergeSplitView()  if delegate.ideViews.length > 1

    delegate.splitTabView snapshot[1].direction  if snapshot[1]

    for key, value of snapshot
      tabView = delegate.ideViews[key]?.tabView
      @resurrectPanes_ value.views, tabView

    delegate.isLocalSnapshotRestored = yes


  resurrectPanes_: (items, tabView) ->

    delegate = @getDelegate()

    for key, value of items

      delegate.setActiveTabView tabView

      if value.type is 'split'

        if value.isFirst isnt yes
          delegate.splitTabView value.direction
          tabView = delegate.ideViews.last.tabView

        if value.views.length
          do (value, tabView) =>
            kd.utils.defer => @resurrectPanes_ value.views, tabView

      else
        # Don't use `active tab view` logic for new pane creation.
        # Because `The Editors` (saved editors) are loading async.
        value.targetTabView = tabView  if value.context.paneType is 'editor'
        delegate.createPaneFromChange value, yes


  ###*
   * With the current implementation we won't redraw host's layout on
   * participants when they joined a session. With latest changes host snapshot
   * became a structural data however participant snapshots should be a flat
   * array to make it backward compatible with  old collaboration code. So we
   * are converting structural snapshot to flat array here.
   *
   * @param {Object} snapshot
   * @return {Array} panes
  ###
  convertSnapshotToFlatArray: (snapshot) ->

    panes = []

    for item in snapshot when item.type is 'split'
      IDELayoutManager.findPanesFromArray panes, item

    return panes


  ###*
   * Find panes from array.
   *
   * @param {Array} panes  Referenced parameter
   * @param {Object} item
  ###
  @findPanesFromArray: (panes, item) ->

    return  unless item.views.length

    if item.views.first.context # if items are a pane
      for pane in item.views    # collect panes
        panes.push pane
    else
      for subView in item.views
        IDELayoutManager.findPanesFromArray panes, subView # recall itself
