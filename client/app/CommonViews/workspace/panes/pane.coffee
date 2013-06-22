class Pane extends JView

  constructor: (options = {}, data) ->

    super options, data

  getProperties: ->
    {properties} = @getOptions()
    return {}  unless properties
    return properties

  getProperty: (name) ->
    return @getProperties()[name]