class AceTabHandleView extends KDCustomHTMLView
  constructor: (options, data) ->
    options or= {}
    options.tagName = 'span'
    super
    
  viewAppended: ->
    @setPartial @partial()
    
  partial: ->
    @title = $ "<b>Default Title</b>"
    
  setTitle: (title) ->
    @title.html title
