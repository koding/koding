class CollaborativeEditorPane extends CollaborativePane

  cdnRoot = "https://koding-cdn.s3.amazonaws.com/codemirror/latest"

  constructor: (options = {}, data) ->

    super options, data

    @container.on "viewAppended", =>
      @createEditor()
      @ref        = @workspace.firepadRef.child @sessionKey
      @firepad    = Firepad.fromCodeMirror @ref, @codeMirrorEditor

      @firepad.on "ready", =>
        {file, content} = @getOptions()
        return @openFile file, content  if file
        if @firepad.isHistoryEmpty()
          @firepad.setText "" # fix for a firepad bug
          @codeMirrorEditor.scrollTo 0, 0

      @ref.on "value", (snapshot) =>
        value = snapshot.val()
        return unless value
        return @save()  if value.WaitingSaveRequest is yes

      @ref.onDisconnect().remove()  if @amIHost

  openFile: (file, content) ->
    @setData file
    isLocalFile = file.path.indexOf("localfile") is 0
    content     = "" if @amIHost and isLocalFile
    @firepad.setText content  if @amIHost
    @codeMirrorEditor.scrollTo 0, 0
    @emit "OpenedAFile", file, content

  save: ->
    file        = @getData()
    isValidFile = file instanceof FSFile and file.path.indexOf("localfile") is -1

    if @amIHost
      return warn "no file instance handle save as" unless isValidFile

      @ref.child("WaitingSaveRequest").set no
      file.save @firepad.getText(), (err, res) =>
        new KDNotificationView
          type     : "mini"
          cssClass : "success"
          title    : "File has been saved"
          duration : 4000
    else
      @ref.child("WaitingSaveRequest").set yes

    @getOptions().saveCallback? @panel, @workspace, file, @firepad.getText()

  getValue: ->
    return @codeMirrorEditor.getValue()

  createEditor: ->
    @codeMirrorEditor = CodeMirror @container.getDomElement()[0],
      lineNumbers     : yes
      extraKeys       :
        "Cmd-S"       : @bound "save"
        "Ctrl-S"      : @bound "save"

    @setEditorTheme()
    @setEditorMode()

  setEditorTheme: ->
    if document.getElementById "codemirror-ambiance-style"
      return  @codeMirrorEditor.setOption "theme", "ambiance"
    link       = document.createElement "link"
    link.rel   = "stylesheet"
    link.type  = "text/css"
    link.href  = "#{cdnRoot}/theme/ambiance.css"
    link.id    = "codemirror-ambiance-style"
    document.head.appendChild link
    @codeMirrorEditor.setOption "theme", "ambiance"

  setEditorMode: ->
    {file} = @getOptions()

    return  unless file

    CodeMirror.modeURL = "#{cdnRoot}/mode/%N/%N.js"
    fileExtension      = file.getExtension()
    syntaxHandler      = __aceSettings.syntaxAssociations[fileExtension]
    modeName           = null
    corrections        =
      html             : "xml"
      json             : "javascript"
      js               : "javascript"
      go               : "go"
      txt              : "text"

    if corrections[fileExtension]
      modeName = corrections[fileExtension]
    else if syntaxHandler
      modeName = syntaxHandler[0].toLowerCase()

    if modeName
      @codeMirrorEditor.setOption "mode", modeName
      CodeMirror.autoLoadMode @codeMirrorEditor, modeName
