class Workspace extends KDView

  constructor: (options = {}, data) ->

    raw      = {}
    raw[key] = value for own key, value of options

    super options, data

    @rawOptions = raw

    @listenWindowResize()

    @container = new KDView
      cssClass : "workspace"

    @panels                = []
    @lastCreatedPanelIndex = 0
    @currentPanelIndex     = 0

    @on "PanelCreated", =>
      @doInternalResize()
      KD.getSingleton("windowController").notifyWindowResizeListeners()

    @init()

  init: -> @createPanel()

  createPanel: (callback = noop) ->
    panelOptions          = @getOptions().panels[@lastCreatedPanelIndex]
    panelOptions.delegate = @
    panelClass            = @getOptions().panelClass or Panel
    newPanel              = new panelClass panelOptions

    @container.addSubView newPanel
    @panels.push newPanel
    @activePanel = newPanel

    callback()
    @emit "PanelCreated", newPanel

  next: ->
    if @lastCreatedPanelIndex is @currentPanelIndex
      @lastCreatedPanelIndex++
      @createPanel =>
        @getPanelByIndex(@lastCreatedPanelIndex - 1).setClass "hidden"
        @currentPanelIndex = @lastCreatedPanelIndex
    else
      @getPanelByIndex(@currentPanelIndex).setClass "hidden"
      @getPanelByIndex(++@currentPanelIndex).unsetClass "hidden"

  prev: ->
    @getPanelByIndex(@currentPanelIndex).setClass "hidden"
    @getPanelByIndex(--@currentPanelIndex).unsetClass "hidden"

  getActivePanel: ->
    return @panels[@lastCreatedPanelIndex]

  getPanelByIndex: (index) ->
    return @panels[index] or null

  showHintModal: ->
    @getActivePanel().showHintModal()

  _windowDidResize: ->
    return unless @activePanel
    @doInternalResize()
    pane.emit "PaneResized" for pane in @activePanel.panes

  doInternalResize: ->
    panel               = @getActivePanel()
    {header, container} = panel
    container.setHeight panel.getHeight() - header.getHeight()  if header

  viewAppended: ->
    @addSubView @container
    @_windowDidResize()
