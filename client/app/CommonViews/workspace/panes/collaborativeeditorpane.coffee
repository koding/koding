class CollaborativeEditorPane extends Pane

  constructor: (options = {}, data) ->

    super options, data

    log "i am a CollaborativeEditorPane and my session key is #{options.sessionKey}" if options.sessionKey

    @container = new KDView

    @container.on "viewAppended", =>
      @codeMirrorEditor = CodeMirror @container.getDomElement()[0],
        lineNumbers     : yes
        mode            : "javascript"

      panel       = @getDelegate()
      workspace   = panel.getDelegate()
      @sessionKey = @getOptions().sessionKey or @createSessionKey()
      ref         = workspace.firepadRef.child @sessionKey
      @firepad    = Firepad.fromCodeMirror ref, @codeMirrorEditor

      @firepad.on "ready", =>
        if @firepad.isHistoryEmpty()
          @firepad.setText "" # fix for a firepad bug

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """