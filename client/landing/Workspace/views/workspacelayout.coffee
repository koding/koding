class WorkspaceLayout extends KDSplitComboView

  init: ->
    @splitViews    = {}
    {direction, sizes, views, splitName} = @getOptions().layoutOptions
    @baseSplitName = splitName

    @addSubView @createSplitView direction, sizes, views, splitName

  createSplitView: (type, sizes, viewsConfig, splitName) ->
    views = []

    viewsConfig.forEach (config, index) =>
      if config.type is "split"
        {options}   = config
        {splitName} = options

        splitView = @createSplitView options.direction, options.sizes, config.views
        @splitViews[splitName] = splitView  if splitName
        views.push splitView
      else
        wrapper = new KDView
        wrapper.on "viewAppended", =>
          wrapper.addSubView @getDelegate().createPane config

        views.push wrapper

    splitView = new SplitViewWithOlderSiblings { type, sizes, views }
    @splitViews[@baseSplitName] = splitView  if @baseSplitName
    splitView.on "ResizeDidStop", => @emitResizedEventToPanes()

    splitView.on "viewAppended", =>
      splitView.resizers.first?.on "DragInAction", =>
        @emitResizedEventToPanes()

    return splitView

  getSplitByName: (name) ->
    return @splitViews[name] or null

  emitResizedEventToPanes: ->
    pane.emit "PaneResized" for pane in @getDelegate().panes