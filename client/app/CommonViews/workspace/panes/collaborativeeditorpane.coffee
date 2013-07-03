class CollaborativeEditorPane extends Pane

  constructor: (options = {}, data) ->

    super options, data

    log "i am a CollaborativeEditorPane and my session key is #{options.sessionKey}" if options.sessionKey

    @container = new KDView

    @container.on "viewAppended", =>
      @codeMirrorEditor = CodeMirror @container.getDomElement()[0],
        lineNumbers     : yes
        mode            : "javascript"
        extraKeys       :
          "Cmd-S"       : @bound "save"

      @panel      = @getDelegate()
      @workspace  = @panel.getDelegate()
      @sessionKey = @getOptions().sessionKey or @createSessionKey()
      @ref        = @workspace.firepadRef.child @sessionKey
      @firepad    = Firepad.fromCodeMirror @ref, @codeMirrorEditor

      @firepad.on "ready", =>
        if @firepad.isHistoryEmpty()
          @firepad.setText "" # fix for a firepad bug

      @ref.on "value", (snapshot) =>
        return @save()  if snapshot.val().WaitingSaveRequest is yes

  setContent: (content) ->
    @firepad.setText content

  save: ->
    file        = @getData()
    amIHost     = @panel.amIHost @sessionKey
    isValidFile = file instanceof FSFile

    if amIHost
      return warn "no file instance handle save as" unless isValidFile

      log "host is saving a file"
      @ref.child("WaitingSaveRequest").set no
      file.save @firepad.getText(), (err, res) =>
        new KDNotificationView
          type     : "mini"
          cssClass : "success"
          title    : "File has been saved"
          duration : 4000
    else
      log "client wants to save a file"
      @ref.child("WaitingSaveRequest").set yes

  createSessionKey: ->
    nick = KD.nick()
    u    = KD.utils
    return "#{nick}:#{u.generatePassword(4)}:#{u.getRandomNumber(100)}"

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """