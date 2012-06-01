class FinderEditInputView extends KDInputView
  keyDown: (event) -> #broadcasting keys to finder
    disallowedKeys = [8, 13, 37, 39]
    if event.keyCode not in disallowedKeys
      @getOptions().finder.handleEvent event
    event
      
  destroy: ->
    @getOptions().finder.mouseDown()