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

    # @workspaceRef.on "value", (snapshot) =>
    #   encoded = snapshot.val()?.terminal
    #   return  unless encoded
    #   log JSON.parse(window.atob(encoded)).join "<br />"

    log "i'm a host terminal and my session key is #{@sessionKey}"

  syncContent: (encoded) ->
    @workspaceRef.set "terminal": encoded

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"
