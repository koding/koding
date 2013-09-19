class Workspace extends JView

  constructor: (options = {}, data) ->

    super options, data

    @listenWindowResize()

    @container = new KDView
      cssClass : "workspace"

    @panels                = []
    @lastCreatedPanelIndex = 0
    @currentPanelIndex     = 0

    @init()

  init: -> @createPanel()

  createPanel: (callback = noop) ->
    panelOptions          = @getOptions().panels[@lastCreatedPanelIndex]
    panelOptions.delegate = @
    newPanel              = new Panel panelOptions

    @container.addSubView newPanel
    @panels.push newPanel
    @activePanel = newPanel

    callback()
    @emit "PanelCreated"

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

  _windowDidResize: ->
    return unless @activePanel
    pane.emit "PaneResized" for pane in @activePanel.panes

  viewAppended: ->
    super
    @_windowDidResize()

  pistachio: ->
    """
      {{> @container}}
    """
