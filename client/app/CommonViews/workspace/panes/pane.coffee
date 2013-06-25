class Pane extends JView

  constructor: (options = {}, data) ->

    super options, data

    title      = options.title or @getProperties().title
    if title
      @header    = new KDHeaderView
        cssClass : "header"
        partial  : title
    else title = new KDCustomHTMLView { tagName: "span" }

  getProperties: ->
    {properties} = @getOptions()
    return {}  unless properties
    return properties

  getProperty: (name) ->
    return @getProperties()[name]