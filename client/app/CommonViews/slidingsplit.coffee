class SlidingSplit extends KDSplitView

  viewAppended:->

    @scrollContainer = @getOptions().scrollContainer or @parent
    super

  splitPanel:(index)->
    index or= @getPanelIndex @focusedPanel
    @setFocusedPanel super index
    @_resizePanels()
    @_repositionPanels()
    @_repositionResizers() if @getOptions().resizable

  removePanel:(index)->

    if super
      @_resizePanels()
      @_repositionPanels()
      @_repositionResizers() if @getOptions().resizable


  setFocusedPanel:(panel)->

    return unless panel
    @focusedPanel = panel
    p.unsetClass "focused" for p in @panels
    panel.setClass "focused"
    @scrollToFocusedPanel()
    @setKeyView()
    @emit "PanelIsFocused", panel

  focusNextPanel:->

    focusedIndex = @getPanelIndex @focusedPanel
    if focusedIndex < @panels.length - 1
      @setFocusedPanel @panels[focusedIndex+1]

  focusPrevPanel:->
    focusedIndex = @getPanelIndex @focusedPanel
    if 0 < focusedIndex
      @setFocusedPanel @panels[focusedIndex-1]

  focusByIndex:(index)->

    @setFocusedPanel @panels[i]    
  
  scrollToFocusedPanel:->
    panel      = @focusedPanel
    container  = @scrollContainer
    duration   = @getOptions().duration or 150
    offset1    = panel._getOffset()
    offset2    = panel._getOffset() + panel._getSize()
    if @isVertical()
      edge1    = container.getScrollLeft()
      edge2    = edge1 + container.getWidth() - 20
      options1 = {left : offset1 - 2 * panel._getSize(), duration}
      options2 = {left : offset1, duration}
    else
      edge1    = container.getScrollTop()
      edge2    = edge1 + container.getHeight() - 20
      options1 = {top : offset1 - 2 * panel._getSize(), duration}
      options2 = {top : offset1, duration}

    if edge1 < offset1 < edge2
      if offset2 > edge2 then container.scrollTo options1
    else
      if offset1 < edge1 then container.scrollTo options2
      if offset1 > edge2 then container.scrollTo options1

  #temp code
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
      switch e.which
        when 37 then do @focusPrevPanel
        when 39 then do @focusNextPanel
        # Focus Indexed Neighbor
        else
          @focusByIndex i if 0 <= (i = e.which - 49) < 10
          
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

    @sizes = sizeArr

  _resizePanels:->

    @_resizeUponPanelCount()
    @getOptions().sizes = @sizes.slice()
    super

  _windowDidResize:(event)=>

    @utils.wait 300, =>
      @_resizePanels()
      @_repositionPanels()
      @_repositionResizers() if @getOptions().resizable

