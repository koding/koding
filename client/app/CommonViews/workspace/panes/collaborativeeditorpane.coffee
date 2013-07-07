class CollaborativeEditorPane extends CollaborativePane

  cdnRoot = "https://fatihacet.kd.io/cdn/codemirror/latest"

  constructor: (options = {}, data) ->

    super options, data

    log "i am a CollaborativeEditorPane and my session key is #{options.sessionKey}"

    @sessionKey = @getOptions().sessionKey or @createSessionKey()

    @container = new KDView

    @container.on "viewAppended", =>
      @createEditor()
      @panel      = @getDelegate()
      @workspace  = @panel.getDelegate()
      @ref        = @workspace.firepadRef.child @sessionKey
      @firepad    = Firepad.fromCodeMirror @ref, @codeMirrorEditor

      @firepad.on "ready", =>
        {file, content} = @getOptions()
        return @openFile file, content  if file
        if @firepad.isHistoryEmpty()
          @firepad.setText "" # fix for a firepad bug

      @ref.on "value", (snapshot) =>
        return @save()  if snapshot.val().WaitingSaveRequest is yes

  openFile: (file, content) ->
    @setData    file
    @setContent content

  setContent: (content) ->
    @firepad.setText content

  save: ->
    file        = @getData()
    amIHost     = @panel.amIHost @sessionKey
    isValidFile = file instanceof FSFile and file.path.indexOf("localfile") is -1

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

  createEditor: ->
    @codeMirrorEditor = CodeMirror @container.getDomElement()[0],
      lineNumbers     : yes
      mode            : "javascript"
      extraKeys       :
        "Cmd-S"       : @bound "save"

    @setEditorTheme()
    @setEditorMode()

  setEditorTheme: ->
    unless document.getElementById "codemirror-ambiance-style"
      link       = document.createElement "link"
      link.rel   = "stylesheet"
      link.type  = "text/css"
      link.href  = "#{cdnRoot}/theme/ambiance.css"
      document.head.appendChild link
      @codeMirrorEditor.setOption "theme", "ambiance"

  setEditorMode: ->
    {file} = @getOptions()

    return  unless file

    CodeMirror.modeURL = "#{cdnRoot}/mode/%N/%N.js" # TODO: fatihacet - it should be publicly available. should change the cdn url.
    fileExtension      = file.getExtension()
    syntaxHandler      = __aceSettings.syntaxAssociations[fileExtension]
    modeName           = null
    corrections        =
      html             : "xml"
      json             : "javascript"
      js               : "javascript"

    if corrections[fileExtension]
      modeName = corrections[fileExtension]
    else if syntaxHandler
      modeName = syntaxHandler[0].toLowerCase()

    if modeName
      @codeMirrorEditor.setOption "mode", modeName
      CodeMirror.autoLoadMode @codeMirrorEditor, modeName

  pistachio: ->
    """
      {{> @header}}
      {{> @container}}
    """