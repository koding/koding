class CollaborativeTerminalPane extends TerminalPane

  constructor: (options = {}, data) ->

    super options, data

    panel         = @getDelegate()
    workspace     = panel.getDelegate()
    @sessionKey   = @getOptions().sessionKey or @createSessionKey()
    @workspaceRef = workspace.firepadRef.child @sessionKey

    @terminal.on "WebTerm.flushed", _.throttle =>
      lines   = (line.innerHTML for line in @terminal.terminal.screenBuffer.lineDivs)
      # encoded =  window.btoa Encoder.htmlEncode JSON.stringify lines # FINISH HIM!!!
      encoded =  JSON.stringify lines
      @syncContent encoded
    , 500

    @workspaceRef.on "value", (snapshot) =>
      # log JSON.parse Encoder.htmlDecode window.atob snapshot.val().terminal
      encoded = snapshot.val()?.terminal
      return  unless encoded
      log JSON.parse encoded

  syncContent: (encoded) ->
    @workspaceRef.set "terminal": encoded

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"
