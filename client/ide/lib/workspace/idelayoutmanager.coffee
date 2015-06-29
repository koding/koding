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

    ## If don't have more sub views in data structe.
    if lastViews.length is 0 or (lastViews.length > 0 and lastViews.last.context)
      return items.last
    else
      @findLastSplitView lastViews  ## if have recall itself


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

      if last                     ## If have last view
      then last.views.push pane   ## add `pane` to last view of tree
      else @subViews.push pane    ## else add `pane` to plain array.


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

    if parentView                     ## If have last view
    then parentView.views.push item   ## add `item` to last view of tree
    else @subViews.push item          ## else add `item` to plain array.

    @getSubLevel panel


  ###*
   * Resurrect saved snapshot from server.
   *
   * @param {Array} snapshot
  ###
  resurrectSnapshot: (snapshot) ->

    ## The `ideApp` is an `IDEAppController`s instance
    ideApp = @getDelegate()

    # if has the fake view
    ideApp.mergeSplitView()  if ideApp.ideViews.length > 1

    ideApp.splitTabView snapshot[1].direction  if snapshot[1]

    for index, item of snapshot
      tabView = ideApp.ideViews[index]?.tabView
      @resurrectPanes_ item.views, tabView

    ideApp.isLocalSnapshotRestored = yes


  resurrectPanes_: (items, tabView) ->

    ## The `ideApp` is an `IDEAppController`s instane
    ideApp = @getDelegate()

    for own index, item of items

      ideApp.setActiveTabView tabView

      if item.type is 'split'

        if item.isFirst isnt yes
          ideApp.splitTabView item.direction
          tabView = ideApp.ideViews.last.tabView

        if item.views.length
          # since we are in a for loop to be able to preserve item and tabview
          # for the defer, we are creating a scope and passing them into there.
          do (item, tabView) =>
            kd.utils.defer => @resurrectPanes_ item.views, tabView

      else
        # Don't use `active tab view` logic for new pane creation.
        # Because `The Editors` (saved editors) are loading async.
        item.targetTabView = tabView  if item.context.paneType is 'editor'
        ideApp.createPaneFromChange item, yes


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
  @convertSnapshotToFlatArray: (snapshot) ->

    panes = []

    for item in snapshot when item.type is 'split'
      IDELayoutManager.findPanesFromArray panes, item.views

    return panes


  ###*
   * Find panes from array.
   *
   * @param {Array} panes  Referenced parameter
   * @param {Array} views
  ###
  @findPanesFromArray: (panes, views) ->

    return  unless views?.length

    if views.first.context # if items are a pane
      for pane in views    # collect panes
        panes.push pane
    else
      for subView in views
        IDELayoutManager.findPanesFromArray panes, subView # recall itself
