class CollaborativeTerminalPane extends TerminalPane

  constructor: (options = {}, data) ->

    super options, data

    panel         = @getDelegate()
    workspace     = panel.getDelegate()
    @sessionKey   = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef = workspace.firepadRef.child @sessionKey

    @terminal.on "WebTerm.flushed", _.throttle =>
      lines   = (line.innerHTML for line in @terminal.terminal.screenBuffer.lineDivs)
      encoded =  JSON.stringify lines
      @syncContent window.btoa encoded
    , 500

    @workspaceRef.on "value", (snapshot) =>
      return unless snapshot.val()

      log "everything is something happened", snapshot.name(), snapshot.val()

      {keyEventFromClient} = snapshot.val()

      if keyEventFromClient
        log "host terminal received a key event from a client", keyEventFromClient

        eventInstance = new Event "ClientTerminalKeyEvent"
        eventName     = if keyEventFromClient.type is "keyup" then "keyDown" else "keyPress"
        eventInstance.initEvent keyEventFromClient.type, true, true

        eventInstance[key] = value for key, value of keyEventFromClient

        @terminal.terminal.inputHandler[eventName] eventInstance

    log "i'm a host terminal and my session key is #{@sessionKey}"

  syncContent: (encoded) ->
    @workspaceRef.set "terminal": encoded

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"
