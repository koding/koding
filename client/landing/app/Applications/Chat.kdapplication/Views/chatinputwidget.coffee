class ChatInputWidget extends KDHitEnterInputView

  constructor:->
    super
      type              : "text"
      placeholder       : "Type your message..."
      keyup             :
        "up"            : (e) => @emit 'goUpRequested'
        "down"          : (e) => @emit 'goDownRequested'
        # "super+up"      : (e) =>
        #   e.preventDefault()
        #   log 'move prev'
        # "super+down"    : (e) =>
        #   e.preventDefault()
        #   log 'move next'
      callback          : ->
        @emit 'messageSent', @getValue()
        @setValue ''
        @setFocus()

