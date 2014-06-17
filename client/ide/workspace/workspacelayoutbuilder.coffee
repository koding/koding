class IDE.WorkspaceLayoutBuilder extends KDSplitComboView

  init: ->
    @splitViews    = {}
    {splitOptions} = @getOptions()

    @addSubView @createSplitView splitOptions

  createSplitView: (options) ->
    views    = []

    options.views.forEach (config) =>
      if config.type is 'split'
        splitView = @createSplitView config.splitOptions
        @splitViews[config.name] = splitView
        views.push splitView
      else
        wrapper = new KDView cssClass : 'pane-wrapper'
        views.push wrapper
        wrapper.once 'viewAppended', =>
          wrapper.addSubView @getDelegate().createPane config

    SplitViewClass = options.splitViewClass or KDSplitView
    options.views  = views
    splitView      = new SplitViewClass options

    @splitViews[options.name] = splitView  if options.name

    return splitView

  getSplitViewByName: (name) ->
    return @splitViews[name] or null
