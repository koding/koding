class CollaborativeEditorPane extends Pane

  constructor: (options = {}, data) ->

    super options, data

  viewAppended: ->
    super

    @codeMirrorEditor = CodeMirror @getDomElement()[0],
      lineNumbers     : yes
      mode            : "javascript"

    panel       = @getDelegate()
    workspace   = panel.getDelegate()
    @sessionKey = @getOptions().sessionKey or @createSessionId()
    ref         = workspace.firepadRef.child @sessionKey
    @firepad    = Firepad.fromCodeMirror ref, @codeMirrorEditor

    # workspace.workspaceRef.set "help me" : {szki: "obi-wan", jedi: "tes"}

    @firepad.on "ready", =>
      if @firepad.isHistoryEmpty()
        @firepad.setText "" # this should be

  createSessionId: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"