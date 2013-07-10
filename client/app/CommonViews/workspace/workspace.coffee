class Workspace extends JView

  constructor: (options = {}, data) ->

    super options, data

    @listenWindowResize()

    @container = new KDView
      cssClass : "workspace"

    @panels                = []
    @lastCreatedPanelIndex = 0

  createPanel: (callback = noop) ->
    panelOptions          = @getOptions().panels[@lastCreatedPanelIndex]
    panelOptions.delegate = @
    newPanel              = new Panel panelOptions

    @container.addSubView newPanel
    @panels.push newPanel
    @activePanel = newPanel

    callback()

  next: ->
    @lastCreatedPanelIndex++
    @createPanel =>
      @panels[@lastCreatedPanelIndex - 1].setClass "hidden"

  prev: ->

  _windowDidResize: ->
    return unless @activePanel
    pane.emit "PaneResized" for pane in @activePanel.panes

  ready: -> @createPanel()

  viewAppended: ->
    super
    @_windowDidResize()

  pistachio: ->
    """
      {{> @container}}
    """
