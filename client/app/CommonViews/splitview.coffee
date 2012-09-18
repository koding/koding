class SplitView extends KDSplitView

  _windowDidResize:(event)=>

    # because we have css animations on main contentpanel
    # resize lasts in 300ms
    # this is bad but we don't have any other way for now
    @utils.wait 300, =>
      @_setSize @_getParentSize()

      @_resizePanels()
      @_repositionPanels()
      @_setPanelPositions()

      # find a way to do that for when parent get resized and split reachs a min-width
      # if @getWidth() > @_getParentSize() then @setClass "min-width-reached" else @unsetClass "min-width-reached"
      if @getOptions().resizable
        @_repositionResizers()
