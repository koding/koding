class Workspace extends JView

  constructor: (options = {}, data) ->

    super options, data

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

    callback()

  next: ->
    @lastCreatedPanelIndex++
    @createPanel =>
      @panels[@lastCreatedPanelIndex - 1].setClass "hidden"

  prev: ->

  ready: -> @createPanel()

  pistachio: ->
    """
      {{> @container}}
    """
