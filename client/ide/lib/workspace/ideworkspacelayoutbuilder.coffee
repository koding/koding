kd                = require 'kd'
KDSplitComboView  = kd.SplitComboView
KDView            = kd.View
IDEBaseSplitView  = require '../views/idebasesplitview'


module.exports = class IDEWorkspaceLayoutBuilder extends KDSplitComboView

  init: ->
    @splitViews      = {}
    { splitOptions } = @getOptions()

    @addSubView @createSplitView splitOptions

  createSplitView: (options) ->
    views    = []

    options.views.forEach (config) =>
      if config.type is 'split'
        splitView = @createSplitView config.splitOptions
        @splitViews[config.name] = splitView
        views.push splitView
      else
        wrapper = new KDView { cssClass : 'pane-wrapper' }
        views.push wrapper
        wrapper.once 'viewAppended', =>
          wrapper.addSubView @getDelegate().createPane config

    SplitViewClass = options.splitViewClass or IDEBaseSplitView
    options.views  = views
    splitView      = new SplitViewClass options

    @splitViews[options.name] = splitView  if options.name

    return splitView

  getSplitViewByName: (name) ->
    return @splitViews[name] or null

### Example Usage also see IDEPanel::constructor

layoutOptions        =
  cssClass           : 'ide-workspace'
  splitOptions       :
    direction        : 'vertical'
    name             : 'BaseSplit'
    sizes            : [ '234px', null ]
    views            : [
      {
        type         : 'custom'
        name         : 'filesPane'
        paneClass    : IDEFilesTabView
      }
      {
        type         : 'split'
        splitOptions :
          direction  : 'horizontal'
          name       : 'InnerSplit'
          sizes      : [ '50%', '50%' ]
          views      : [
            {
              type   : 'drawing'
              name   : 'MainTerminal'
            }
            {
              type   : 'editor'
              name   : 'MainEditor'
            }
          ]
      }
    ]

layout = new WorkspaceLayoutBuilder layoutOptions

###
