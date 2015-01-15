class BaseSplitView extends KDSplitView

  viewAppended: ->

    super

    @lastKnownFileTreeSize = @getOption('sizes').first or 250

    @on 'PanelDidResize', KD.utils.debounce 10, =>

      fileTree = @panels.first
      @lastKnownFileTreeSize = fileTree.size


  _resizePanels: ->

    first = @lastKnownFileTreeSize
    second = @size - @lastKnownFileTreeSize

    @sizes = [ first, second ]

    # last `yes` is to force render second pane
    # even if the first pane reaches the value.
    @resizePanel first, 0, noop, yes



module.exports = BaseSplitView
