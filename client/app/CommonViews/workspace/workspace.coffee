class Workspace extends JView

  constructor: (options = {}, data) ->

    super options, data

    @container = new KDView
      cssClass : "workspace"

    @lastCreatedPanelIndex = 0

    @createPanel()

  createPanel: ->
    panelOptions = @getOptions().panels[@lastCreatedPanelIndex]
    @container.addSubView new Panel panelOptions

  next: ->
    @lastCreatedPanelIndex++
    @createPanel()

  prev: ->

  pistachio: ->
    """
      {{> @container}}
    """