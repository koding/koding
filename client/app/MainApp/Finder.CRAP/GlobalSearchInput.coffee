class GlobalSearchInput extends KDInputView
  keyDown: (event) ->
    switch event.which
      when 40 
        @emit 'go.down'
      when 38 
        @emit 'go.up'
      when 13 
        @emit 'open'
    
  keyUp: (event) ->
    forbiddenKeys = [40, 38, 13]
    if event.which in forbiddenKeys
      return no
      
    clearTimeout @_lastKeyPress
    callback = @getOptions().callback
    @_lastKeyPress = setTimeout ->
      callback?()
    , 200
    
