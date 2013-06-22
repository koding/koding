class Panel extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "panel"

    super options, data

    @headerButtons = {}
    @panes         = []

    @createHeader()
    @createHeaderButtons()  if options.buttons?.length
    # @createHeaderHint()     if options.hint

    @createLayout()

    @createPanes()

  createHeader: ->
    @header     = new KDView
      cssClass  : "inner-header"
      partial   : """<span class="title">#{@getOptions().title}</span>"""

  createHeaderButtons: ->
    for buttonOptions in @getOptions().buttons
      buttonView = new KDButtonView buttonOptions
      @headerButtons[buttonOptions.title] = buttonView
      @header.addSubView buttonView

  createHeaderHint: ->
    @header.addSubView new KDButtonView
      cssClass  : "hint"
      iconOnly  : yes
      iconClass : "exclamation"
      tooltip   :
        title   : @getOptions().hint

  createLayout: ->
    @container = new KDView
      cssClass : "panel-container"

    panesLength            = @getOptions().panes.length
    return  unless panesLength
    panelTypeByPaneLength  =
      "1"                  : "SingleLayout"
      "2"                  : "DoubleLayout"
      "3"                  : "TripleLayout"
      "4"                  : "QuadrupleLayout"
    methodName             = "create#{panelTypeByPaneLength[panesLength]}"
    do @[methodName]

  createPanes: ->
    for paneOptions, index in @getOptions().panes
      @createPane paneOptions, @getPaneByIndex index

  createPane: (paneOptions, targetContainer) ->
    paneTypesToPaneClass =
      "terminal"         : TerminalPane
      "editor"           : EditorPane
      "video"            : VideoPane
      "preview"          : PreviewPane
    PaneClass            = paneTypesToPaneClass[paneOptions.type]

    targetContainer.addSubView new PaneClass paneOptions

  # GETTERS #
  getPaneByIndex: (index) ->
    return @panes[index]

  # LAYOUT CREATOR HELPERS #
  createSplitView: (type, views) ->
    return new KDSplitView {
      resizable : yes
      sizes     : ["50%", "50%"]
      type
      views
    }

  createSingleLayout: ->
    view       = new KDView
      cssClass : "panel-container"

    @container.addSubView view
    @panes.push view

  createDoubleLayout: ->
    pane1     = new KDView
    pane2     = new KDView
    splitView = @createSplitView "vertical", [pane1, pane2]

    @container.addSubView splitView
    @panes.push pane1, pane2

  createTripleLayout: ->
    pane1           = new KDView
    pane2           = new KDView
    pane3           = new KDView
    rightInnerSplit = @createSplitView "horizontal", [pane2, pane3]
    baseSplit       = @createSplitView "vertical", [pane1, rightInnerSplit]

    @container.addSubView baseSplit

    @panes.push pane1, pane2, pane3

  createQuadrupleLayout: ->
    pane1           = new KDView
    pane2           = new KDView
    pane3           = new KDView
    pane4           = new KDView
    leftInnerSplit    = @createSplitView "horizontal", [pane1, pane2]
    rightInnerSplit   = @createSplitView "horizontal", [pane3, pane4]
    baseSplit         = @createSplitView "vertical", [leftInnerSplit, rightInnerSplit]

    @container.addSubView baseSplit

    @panes.push pane1, pane2, pane3, pane4

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """