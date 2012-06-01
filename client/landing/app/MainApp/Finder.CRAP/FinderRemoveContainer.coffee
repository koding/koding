class FinderRemoveContainer extends KDCustomHTMLView
  keyDown: (event) ->
    disallowedKeys = [8, 13, 37, 39]
    if event.keyCode not in disallowedKeys
      @getOptions().finder.keyDownOnFinder null, event
      
  viewAppended: ->
    super
    (@getSingleton "windowController").setKeyView @
    
  # destroy: ->
  #   @getOptions().finder.mouseDown()
  #   super
    