kd = require 'kd'
KDSplitView = kd.SplitView


module.exports = class SplitViewWithOlderSiblings extends KDSplitView
  viewAppended: ->
    super
    siblings        = @parent.getSubViews()
    index           = siblings.indexOf this
    @_olderSiblings = siblings.slice 0, index

  _windowDidResize: ->
    super
    offset        = 0
    for olderSibling in @_olderSiblings
      # absolute positioned elements doesn't provide offset for relative elements
      siblingStyle = global.getComputedStyle olderSibling.getElement()
      unless siblingStyle.position is 'absolute'
        offset += olderSibling.getHeight()
    newH = @parent.getHeight() - offset
    @setHeight newH
