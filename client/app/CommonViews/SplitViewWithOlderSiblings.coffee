class SplitViewWithOlderSiblings extends SplitView
  viewAppended:->
    super
    siblings        = @parent.getSubViews()
    index           = siblings.indexOf @
    @_olderSiblings = siblings.slice 0,index
    
  _windowDidResize:=>
    super
    offset        = 0
    for olderSibling in @_olderSiblings
      offset += olderSibling.getHeight()
    newH = @parent.getHeight() - offset
    @setHeight newH
