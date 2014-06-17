class ChatInputWidget extends KDHitEnterInputView

  constructor:->
    super
      type              : "text"
      placeholder       : "Type your message..."
      keyup             :
        "up"            : => @emit 'goUpRequested'
        "down"          : => @emit 'goDownRequested'
        "meta+up"      : => @emit 'moveUpRequested'
        "meta+down"    : => @emit 'moveDownRequested'
      callback          : ->
        @emit 'messageSent', @getValue()  if @getValue() isnt ''
        @setValue ''
        @setFocus()
