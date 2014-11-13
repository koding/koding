class IDE.EditorPane extends IDE.Pane

  shortcutsShown = no

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'editor-pane', options.cssClass
    options.paneType = 'editor'

    {file} = options
    @file  = file

    super options, data

    @hash  = file.paneHash  if file.paneHash

    @on 'SaveRequested', @bound 'save'

    @lineWidgets = {}
    @cursors     = {}

    @createEditor()

    file.once 'fs.delete.finished', =>
      KD.getSingleton('appManager').tell 'IDE', 'handleFileDeleted', file

  createEditor: ->
    {file, content} = @getOptions()

    unless file instanceof FSFile
      throw new TypeError 'File must be an instance of FSFile'

    unless content?
      throw new TypeError 'You must pass file content to IDE.EditorPane'

    aceOptions =
      delegate                 : @getDelegate()
      createBottomBar          : no
      createFindAndReplaceView : no

    @addSubView @aceView = new AceView aceOptions, file

    {ace} = @aceView

    ace.once 'ace.ready', =>
      @getEditor().setValue content, 1
      ace.setReadOnly yes  if @getOptions().readOnly
      @bindChangeListeners()
      @emit 'EditorIsReady'

  save: ->
    ace.emit 'ace.requests.save', @getContent()

  getAce: ->
    return @aceView.ace

  getEditor: ->
    return @getAce().editor

  getEditorSession: ->
    return @getEditor().getSession()

  getValue: ->
    return  @getEditorSession().getValue()

  goToLine: (lineNumber) ->
    @getAce().gotoLine lineNumber

  setFocus: (state) ->
    super state

    return  unless ace = @getEditor()

    if state
    then ace.focus()
    else ace.blur()

  getContent: ->
    return @getAce().getContents()

  setContent: (content, emitFileContentChangedEvent = yes) ->
    @getAce().setContent content, emitFileContentChangedEvent

  getCursor: ->
    return @getEditor().selection.getCursor()

  setCursor: (positions) ->
    @getEditor().selection.moveCursorTo positions.row, positions.column

  getFile: ->
    return @aceView.getData()

  bindChangeListeners: ->
    ace           = @getAce()
    change        =
      origin      : KD.nick()
      context     :
        paneHash  : @hash
        paneType  : @getOptions().paneType
        file      :
          path    : @file.path
          machine :
            uid   : @file.machine.uid

    ace.on 'ace.change.cursor', (cursor) =>
      change.type = 'CursorActivity'
      change.context.cursor = cursor

      @emit 'ChangeHappened', change

    ace.on 'FileContentChanged', =>
      change.type = 'ContentChange'
      change.context.file.content = @getContent()

      @emit 'ChangeHappened', change

  serialize: ->
    file       = @getFile()
    {paneType} = @getOptions()
    {machine}  = file

    {name, path } = file
    {label, ipAddress, slug, uid} = machine

    data       =
      file     : { name, path }
      machine  : { label, ipAddress, slug, uid }
      paneType : paneType
      hash     : @hash

    return data


  setLineWidget: (rowNumber, username) ->
    oldWidget    = @lineWidgets[username]
    lineHeight   = @getEditor().renderer.lineHeight + 2
    color        = KD.utils.getColorFromString username
    style        = "border-bottom:2px dotted #{color};margin-top:-#{lineHeight}px;"
    cssClass     = 'ace-line-widget'
    manager      = @getAce().lineWidgetManager

    if oldWidget
      manager.removeLineWidget oldWidget

    options      =
      row        : rowNumber
      rowCount   : 0
      fixedWidth : yes
      editor     : @getEditor()
      html       : "<div class='#{cssClass}' style='#{style}'>#{username}</div>"

    KD.utils.defer =>
      manager.addLineWidget options
      @lineWidgets[username] = options


  setParticipantCursor: (row, column, username) ->
    oldCursor = @cursors[username]
    session   = @getEditorSession()
    AceRange  = @getAce().Range
    color     = KD.utils.getColorFromString username
    cssClass  = "ace-participant-cursor ace-cursor-#{username}"

    return unless AceRange

    if oldCursor
      session.removeMarker oldCursor.id

    range = new AceRange row, column, row, column + 1
    id    = session.addMarker range, cssClass, 'text'

    @cursors[username] = { id, row, column }


  handleChange: (change, rtm, realTimeDoc) ->
    {context, type, origin} = change

    if type is 'ContentChange'
      oldContent = @getValue()
      string     = rtm.getFromModel realTimeDoc, context.file.path
      newContent = string.getText()
      cursor     = @getCursor()

      @setContent newContent, no

      row = @getNewCursorPosition oldContent, newContent, cursor.row
      col = cursor.column

      KD.utils.defer =>
        @setCursor { row, column: col }

    if type is 'CursorActivity'
      {row, column} = context.cursor
      @setLineWidget row, origin
      @setParticipantCursor row, column, origin


  getNewCursorPosition: (oldContent, newContent, oldRowNumber) ->
    return if not oldContent or not newContent

    oldContentLines = oldContent.split '\n'
    newContentLines = newContent.split '\n'
    oldLinesAbove   = oldContentLines.slice 0, oldRowNumber
    newLinesAbove   = newContentLines.slice 0, oldRowNumber
    oldLinesBelow   = oldContentLines.slice oldRowNumber, oldContentLines.length

    unless oldLinesAbove is newLinesAbove
      newCursorPosition = newContentLines.length - oldLinesBelow.length

    return newCursorPosition ? 0
