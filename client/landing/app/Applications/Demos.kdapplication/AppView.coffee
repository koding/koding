class DemosMainView extends KDScrollView

  viewAppended:()->

    @addSubView split = new FocusableSplit
      cssClass        : "chat-split"
      sizes           : [null]
      scrollContainer : @

class FocusableSplit extends KDSplitView

  constructor:->

    super

  viewAppended:->

    @scrollContainer = @getOptions().scrollContainer or @parent
    super

  splitPanel:->

    super
    @_windowDidResize()

  removePanel:(index)->

    if super
      @_windowDidResize()


  setFocusedPanel:(panel)->

    return unless panel
    log "panel :", @getPanelIndex panel
    @focusedPanel = panel
    p.unsetClass "focused" for p in @panels
    panel.setClass "focused"
    @emit "PanelIsFocused", panel
    @scrollToFocusedPanel()
    @setKeyView()

  scrollToFocusedPanel:->
    panel     = @focusedPanel
    container = @scrollContainer
    left      = panel._getOffset()
    right     = panel._getOffset() + panel._getSize()
    duration  = 150
    leftEdge  = container.getScrollLeft()
    rightEdge = leftEdge + container.getWidth() - 20

    if leftEdge < left < rightEdge
      if right > rightEdge
        container.scrollTo {left : left - 2 * panel._getSize(), duration}
    else
      if leftEdge > left
        container.scrollTo {left, duration}
      if left > rightEdge
        container.scrollTo {left : left - 2 * panel._getSize(), duration}

  keyDown:(e)->

    e.preventDefault()
    e.stopPropagation()

    focusedIndex = @getPanelIndex @focusedPanel

    # log e.which

    # Split Panel
    if e.altKey and e.which in [37,39]
      @splitPanel focusedIndex
      return no

    # Close Panel
    if e.which is 27 and @panels.length > 1
      @removePanel focusedIndex
      if @panels[focusedIndex-1]
        @setFocusedPanel @panels[focusedIndex-1]
      else
        @setFocusedPanel @panels[0]
      return no

    if e.metaKey
      @setFocusedPanel switch e.which
        # Focus Prev Neighbor
        when 37
          @panels[focusedIndex-1] if 0 < focusedIndex
        # Focus Next Neighbor
        when 39
          @panels[focusedIndex+1] if focusedIndex < @panels.length - 1
        # Focus Indexed Neighbor
        else
          if 0 <= (i = e.which - 49) < 10
            @panels[i] if @panels[i]
    no


  _createPanel:->

    panel = super

    @listenTo
      KDEventTypes       : 'click'
      listenedToInstance : panel
      callback           : @setFocusedPanel

    return panel

  _resizeUponPanelCount:->

    i = 0
    sizeArr = []
    parentSize = @_getParentSize()
    switch (l = @panels.length)
      when 1,2,3
        while i < l
          sizeArr.push parentSize/l
          i++
        @_setSize parentSize
      else
        while i < l
          sizeArr.push parentSize/3
          i++
        @_setSize parentSize + (l - 3) / 3 * parentSize

    @getOptions().sizes = sizeArr
    # log @getOptions().sizes

  _windowDidResize:(event)=>
    super

    # @utils.wait 300, =>
    #   @_resizeUponPanelCount()
    #   # @_resetSizeValues()
    #   @sizes = @_sanitizeSizes()
    #   @_calculatePanelBounds()
    #   @_setPanelPositions()
    #   @_setResizerPositions() if @options.resizable

