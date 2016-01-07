kd          = require 'kd'
KDSplitView = kd.SplitView


module.exports = class IDEBaseSplitView extends KDSplitView


  viewAppended: ->

    super

    @lastKnownFileTreeSize = @getOption('sizes').first or 250

    @on 'PanelDidResize', kd.utils.debounce 10, =>
      return  unless fileTree = @panels.first
      @lastKnownFileTreeSize = fileTree.size

    @resizer.on 'DragInAction', @bound 'resizeFirstSplitView'

    @on 'ResizeFirstSplitView', @bound 'resizeFirstSplitView'


  _resizePanels: ->

    first = @lastKnownFileTreeSize
    second = @size - @lastKnownFileTreeSize

    @sizes = [ first, second ]

    # last `yes` is to force render second pane
    # even if the first pane reaches the value.
    @resizePanel first, 0, kd.noop, yes


  resizeFirstSplitView: ->

    splitView = @getFirstSplitView()
    splitView._windowDidResize()  if splitView instanceof KDSplitView


  getFirstSplitView: ->

    { first } = @panels.last.getSubViews().first.getSubViews()

    return first
