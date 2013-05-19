class ChatInputWidget extends KDHitEnterInputView

  constructor:->
    super
      type              : "text"
      placeholder       : "Type your message..."
      keyup             :
        "up"            : => @emit 'goUpRequested'
        "down"          : => @emit 'goDownRequested'
        "super+up"      : => @emit 'moveUpRequested'
        "super+down"    : => @emit 'moveDownRequested'
      callback          : ->
        @emit 'messageSent', @getValue()
        @setValue ''
        @setFocus()

