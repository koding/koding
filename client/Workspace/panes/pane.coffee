class Pane extends JView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry "ws-pane", options.cssClass

    super options, data

    hasButtons     = options.buttons?.length
    @headerButtons = {}

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
    # TODO: c/p from panel, should refactor both of them.
    @getOptions().buttons.forEach (buttonOptions) =>
      if buttonOptions.itemClass
        Klass = buttonOptions.itemClass
        buttonOptions.callback = buttonOptions.callback?.bind this, this, @getDelegate()

        buttonView = new Klass buttonOptions
      else
        buttonOptions.callback = buttonOptions.callback?.bind this, this, @getDelegate()
        buttonView = new KDButtonView buttonOptions

      @headerButtons[buttonOptions.title] = buttonView
      @header.addSubView buttonView

  handlePaneResized: ->