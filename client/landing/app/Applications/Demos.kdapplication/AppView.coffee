class DemosMainView extends KDScrollView

  viewAppended:()->

    @addSubView split = new FocusableSplit
      cssClass : "chat-split"
      sizes    : [null]
      keydown  : (pubInst, e)->

        e.preventDefault()
        e.stopPropagation()

        focusedIndex = @getPanelIndex @focusedPanel
        log e.which
        if e.altKey and e.which in [37,39]
          log "splitPanel"
          split.splitPanel focusedIndex
          split._windowDidResize()
          return no

        if e.altKey and e.which is 87
          log "closePanel"
          return if @panels.length is 1
          split.removePanel focusedIndex
          if @panels[focusedIndex-1] then @setFocusedPanel @panels[focusedIndex-1] else @panels[0]
          return no

        if e.metaKey and e.which in [37,39]
          log "focusNeighbor"
          if e.which is 37
            @setFocusedPanel @panels[focusedIndex-1] if 0 < focusedIndex
          if e.which is 39
            @setFocusedPanel @panels[focusedIndex+1] if focusedIndex < @panels.length
        else
          @focusedPanel.setPartial "&##{event.which};"
        no


class FocusableSplit extends KDSplitView

  setFocusedPanel:(panel)->

    @focusedPanel = panel
    p.unsetClass "focused" for p in @panels
    panel.setClass "focused"
    @setKeyView()

  _createPanel:->

    panel = super

    @listenTo
      KDEventTypes       : 'click'
      listenedToInstance : panel
      callback           : @setFocusedPanel

    return panel

  _resizeUponPanelCount:->
    if (l = @panels.length) < 4
      @_setSize @_getParentSize()
    else
      @getOptions().sizes = new Array l
      @_setSize (w = @_getParentSize()) + (l - 3) / 3 * w

  _windowDidResize:(event)=>
    super
    # @utils.wait 300, =>
    #   @_resizeUponPanelCount()
    #   @_resetSizeValues()
    #   @sizes = @_sanitizeSizes()
    #   @_calculatePanelBounds()
    #   @_setPanelPositions()
    #   @_setResizerPositions() if @options.resizable

