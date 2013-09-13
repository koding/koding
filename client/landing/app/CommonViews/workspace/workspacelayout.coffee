class WorkspaceLayout extends KDSplitComboView

  init: ->
    {layoutOptions} = @getOptions()
    @addSubView @createSplitView layoutOptions.direction, layoutOptions.sizes, layoutOptions.views

  createSplitView: (type, sizes, viewsConfig) ->
    views = []

    viewsConfig.forEach (config, index) =>
      if config.type is "split"
        {options} = config
        views.push @createSplitView options.direction, options.sizes, config.views
      else
        wrapper = new KDView
        wrapper.on "viewAppended", =>
          wrapper.addSubView @getDelegate().createPane config

        views.push wrapper

    splitView = new SplitViewWithOlderSiblings { type, sizes, views }
    splitView.on "ResizeDidStop", => @emitResizedEventToPanes()

    splitView.on "viewAppended", =>
      splitView.resizers[0].on "DragInAction", =>
        @emitResizedEventToPanes()

    return splitView

  emitResizedEventToPanes: ->
    pane.emit "PaneResized" for pane in @getDelegate().panes