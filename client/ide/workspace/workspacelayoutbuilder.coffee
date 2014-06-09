class WorkspaceLayoutBuilder extends KDSplitComboView

  init: ->
    @splitViews = {}
    {direction, sizes, views, cssClass, splitName} = @getOption 'layoutOptions'

    @baseSplitName = splitName
    splitOptions   = {
      type         : direction
      viewsConfig  : views
      sizes
      cssClass
    }

    @addSubView @createSplitView splitOptions, splitName

  createSplitView: (splitOptions, splitName) ->
    {type, sizes, viewsConfig, cssClass} = splitOptions
    views = []

    viewsConfig.forEach (config) =>
      if config.type is 'split'
        {options}     = config
        {splitName}   = options
        splitView     = @createSplitView
          type        : options.direction
          sizes       : options.sizes
          cssClass    : options.cssClass
          viewsConfig : config.views

        @splitViews[splitName] = splitView  if splitName
        views.push splitView
      else
        wrapper = new KDView cssClass: 'pane-wrapper'
        wrapper.on 'viewAppended', =>
          wrapper.addSubView @getDelegate().createPane config

        views.push wrapper

    SplitViewClass = @getOptions().splitViewClass or KDSplitView
    splitView      = new SplitViewClass { type, sizes, views, cssClass }
    @splitViews[@baseSplitName] = splitView  if @baseSplitName

    return splitView

  getSplitViewByName: (name) ->
    return @splitViews[name] or null
