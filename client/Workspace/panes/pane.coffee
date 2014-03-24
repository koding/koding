class Pane extends JView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry "ws-pane", options.cssClass

    super options, data

    @headerButtons = {}

    @createHeader()
    @createButtons()  if options.buttons?.length

    @on "PaneResized", @bound "handlePaneResized"

  createHeader: ->
    options    = @getOptions()
    title      = options.title or ""

    @header    = new KDCustomHTMLView
      tagName  : "span"  if title is ''
      cssClass : "ws-header inner-header"

    @header.title = new KDCustomHTMLView
      partial : "#{title}"
      tagName : "h4"

    @header.addSubView @header.title

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