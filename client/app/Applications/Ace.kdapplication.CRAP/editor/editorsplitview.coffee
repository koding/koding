class EditorSplitView extends KDSplitView
  viewAppended: ->
    super

    # @listenTo
    #   KDEventTypes: 'ResizeDidStop'
    #   listenedToInstance: @
    #   callback: (pubInst, event) =>
    #     @_resizeEditors()

  _windowDidResize: ->
    super
    @resizeEditors()

  _createPanel:(index)->
    panel = new EditorSplitViewPanel 
      cssClass : "kdsplitview-panel panel-#{index}"
      index    : index
      type     : @options.type
      size     : @_sanitizeSize @sizes[index]
      minimum  : @_sanitizeSize @options.minimums[index] if @options.minimums
      maximum  : @_sanitizeSize @options.maximums[index] if @options.maximums
    panel.parent ?= @
    panel

  resizeEditors: ->
    @sizes = @_sanitizeSizes()
    @_calculatePanelBounds()
    @_setPanelPositions()
    @_setResizerPositions()
    @_resizeEditors()

  _putViews:->
    @rawItems = []
    @options.views ?= []
    for view,i in @options.views
      if view instanceof KDView
        @rawItems.push view
        panel = @panels[i]
        panel.addSubView view
        panel.setDelegate view
        view.parent = panel

  _resizeEditors: ->
    for panel, index in @panels
      if panel.getDelegate() instanceof Editor_CodeField
        panel.getDelegate().doResize()

  getPanelByDelegate: (delegate) ->
    for panel, index in @panels
      if panel.getDelegate() is delegate
        return panel

  removePanel: (index) ->
    panel = @panels[index]
    @panels.splice index, 1
    panel.destroy()

    size = 100 / (@panels.length)
    @options.sizes = []
    for i in [0...@panels.length]
      # console.log 'setting size', size
      @options.sizes.push size + '%'

    @resizeEditors()


class EditorSplitViewPanel extends KDSplitViewPanel
  addSubView: (view) ->
    super 
    if view instanceof KDSplitView
      view.listenTo
        KDEventTypes : "PanelDidResize"
        listenedToInstance : @
        callback : view._windowDidResize
    else if view instanceof Editor_CodeField
      view.listenTo
        KDEventTypes : "PanelDidResize"
        listenedToInstance : @
        callback : ->
          view.doResize()
