class Pane extends JView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry "ws-pane", options.cssClass

    super options, data

    hasButtons = options.buttons?.length

    @createHeader()
    @createButtons()  if hasButtons

    @on "PaneResized", @bound "handlePaneResized"

  createHeader: ->
    options    = @getOptions()
    hasButtons = options.buttons?.length
    title      = options.title or ""

    if title or hasButtons
      @header    = new KDHeaderView
        cssClass : "ws-header inner-header"
        partial  : title
    else
      @header    = new KDCustomHTMLView
        cssClass : "ws-header"

  createButtons: ->
    for buttonOptions in @getOptions().buttons
      @header.addSubView new KDButtonView buttonOptions

  handlePaneResized: ->