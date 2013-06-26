class Pane extends JView

  constructor: (options = {}, data) ->

    super options, data

    hasButtons = options.buttons?.length
    title      = options.title or @getProperties().title or ""

    if title or hasButtons
      @header    = new KDHeaderView
        cssClass : "inner-header"
        partial  : title
    else
      @header    = new KDCustomHTMLView

    @createButtons()  if hasButtons

  createButtons: ->
    for buttonOptions in @getOptions().buttons
      @header.addSubView new KDButtonView buttonOptions

  getProperties: ->
    {properties} = @getOptions()
    return {}  unless properties
    return properties

  getProperty: (name) ->
    return @getProperties()[name]