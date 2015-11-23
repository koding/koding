kd                 = require 'kd'
nick               = require 'app/util/nick'
IDEAce             = require '../../views/ace/ideace'
FSFile             = require 'app/util/fs/fsfile'
IDEPane            = require './idepane'
AceView            = require 'ace/aceview'
FSHelper           = require 'app/util/fs/fshelper'
IDEHelpers         = require '../../idehelpers'
getColorFromString = require 'app/util/getColorFromString'


module.exports = class IDEEditorPane extends IDEPane

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'editor-pane', options.cssClass
    options.paneType = 'editor'

    {file}       = options
    @file        = file
    @lineWidgets = {}

    super options, data

    @hash        = file.paneHash  if file.paneHash
    @ideViewHash = options.ideViewHash

    @on 'SaveRequested', @bound 'save'

    @createEditor()

    file.once 'fs.delete.finished', ->
      kd.getSingleton('appManager').tell 'IDE', 'handleFileDeleted', file

    @errorOnSave = no
    file.on [ 'fs.save.failed', 'fs.saveAs.failed' ], @bound 'handleSaveFailed'

    @on 'RealtimeManagerSet', @bound 'setContentFromCollaborativeString'
    @on 'RealtimeManagerSet', @bound 'listenCollaborativeStringChanges'

    @getAce().on 'ace.requests.save', =>
      change = @getInitialChangeObject()
      change.type = 'FileSaved'

      @emit 'ChangeHappened', change

    @getFileModifiedDate (date) => @lastModifiedDate = date


  getFileModifiedDate: (callback = noop) ->

    path = FSHelper.plainPath @file.path
    @file.machine.getBaseKite()?.fsGetInfo?({ path }).then (info) ->
      callback info.time


  createEditor: ->

    { file, content } = @getOptions()

    unless file instanceof FSFile
      throw new TypeError 'File must be an instance of FSFile'

    unless content?
      throw new TypeError 'You must pass file content to IDEEditorPane'

    aceOptions =
      aceClass                 : IDEAce
      delegate                 : @getDelegate()
      createBottomBar          : no
      createFindAndReplaceView : no

    @addSubView @aceView = new AceView aceOptions, file

    { ace } = @aceView

    ace.ready =>
      @getEditor().setValue content, 1
      ace.setReadOnly yes  if @getOptions().readOnly
      @bindChangeListeners()
      @bindFileSyncEvents()
      @emit 'EditorIsReady'

    @on 'RealtimeManagerSet', =>
      myPermission = @rtm.getFromModel('permissions').get nick()
      return  if myPermission isnt 'read'
      ace.ready @bound 'makeReadOnly'


  bindFileSyncEvents: ->

    ace = @getAce()

    ace.on 'FileContentChanged', =>
      kd.utils.defer => # defer to get the updated cursor position after the keypress
        cursor    = @getCursor()
        content   = @getContent()
        eventName = 'ContentChanged'
        from      = @getId()

        @file.emit 'FileActionHappened', { eventName, content, cursor, from }

    ace.forwardEvent @file, 'FileContentRestored'

    @file.on 'FileActionHappened', (data) =>
      { from, eventName, content } = data
      return  if from is @getId()

      if eventName is 'ContentChanged'
        @updateContent content
        @aceView.showModifiedIconOnTabHandle()

    @file.on 'FileContentRestored', => ace.removeModifiedFromTab()

    @file.on 'fs.save.finished', =>
      ace.removeModifiedFromTab()
      @updateFileModifiedTime()

    @file.on 'FileContentsNeedsToBeRefreshed', =>
      ace.fetchContents (err, content) =>
        @updateContent content, yes
        ace.removeModifiedFromTab()
        @updateFileModifiedTime()
        @contentChangedWarning?.destroy()
        @contentChangedWarning = null


  updateContent: (content, isSaved = no) ->

    scrollTop = @getAceScrollTop()
    cursor    = @getCursor()
    @setContent content, no
    @setCursor cursor
    @setAceScrollTop scrollTop
    @getAce().lastSavedContents = content  if isSaved


  handleAutoSave: ->

    return  if @getFile().path.indexOf('localfile:/') > -1
    return  if @errorOnSave

    if @getAce().isContentChanged()
      @save ignoreActiveLineOnTrim: yes


  save: (options = {}) -> @getAce().requestSave options


  getAce: -> return @aceView.ace


  getEditor: -> return @getAce().editor


  getEditorSession: -> return @getEditor().getSession()


  getValue: -> return  @getEditorSession().getValue()


  goToLine: (lineNumber) -> @getAce().gotoLine lineNumber


  getAceScrollTop: -> @getEditorSession().getScrollTop()


  setAceScrollTop: (top) -> @getEditorSession().setScrollTop top


  getContent: -> return if @getEditor() then @getAce().getContents() else ''


  setContent: (content, emitFileContentChangedEvent = yes) ->

    @getAce().setContent content, emitFileContentChangedEvent


  getCursor: -> return @getEditor().selection.getCursor()


  setCursor: (positions) ->

    @getEditor().selection.moveCursorTo positions.row, positions.column


  getFile: -> @aceView.getData()


  setFocus: (state) ->

    super state

    return  unless ace = @getEditor()

    return ace.blur()  unless state
    ace.focus()

    @checkForContentChange()


  checkForContentChange: ->

    return if @contentChangedWarning or @rtm?.isReady or @isCheckingContentChange

    @isCheckingContentChange = yes

    @getFileModifiedDate (time) =>
      if time isnt @lastModifiedDate
        @getAce().prepend @contentChangedWarning = view = new kd.View
          cssClass : 'description-view editor'
          partial  : '<div>This file has changed on disk. Do you want to reload it?</div>'

        view.addSubView new kd.ButtonView
          title    : 'No'
          cssClass : 'solid compact red'
          callback : => @handleContentChangeWarningAction()

        view.addSubView new kd.ButtonView
          title    : 'Yes'
          cssClass : 'solid compact green'
          callback : => @handleContentChangeWarningAction yes

      @isCheckingContentChange = no


  handleContentChangeWarningAction: (isAccepted) ->

    @contentChangedWarning?.destroy()
    @contentChangedWarning = null

    if isAccepted
      @file.emit 'FileContentsNeedsToBeRefreshed'
      @updateFileModifiedTime()


  updateFileModifiedTime: ->

    @getFileModifiedDate (date) =>
      @file.time = date
      @lastModifiedDate = date


  getInitialChangeObject: ->

    change       =
      origin     : nick()
      context    :
        paneHash : @hash
        paneType : @getOptions().paneType
        file     : path: @file.path

    return change


  bindChangeListeners: ->

    change = @getInitialChangeObject()

    @getAce()
      .on 'ace.change.cursor',   @lazyBound 'handleCursorChange',      change
      .on 'FileContentChanged',  @lazyBound 'handleFileContentChange', change
      .on 'FileContentRestored', @lazyBound 'handleFileContentChange', change


  handleCursorChange: (change, cursor) ->

    change.type = 'CursorActivity'
    change.context.cursor = cursor

    @emit 'ChangeHappened', change


  handleFileContentChange: (change) ->

    return if @dontEmitChangeEvent

    change.type = 'ContentChange'
    change.context.file.content = @getContent()

    @emit 'ChangeHappened', change


  serialize: ->

    file           = @getFile()
    { paneType }   = @getOptions()
    { name, path } = file

    data       =
      file     : { name, path }
      paneType : paneType
      hash     : @hash

    if file.isDummyFile()
      data.file.content = @getContent()

    return data


  setLineWidgets: (row, col, username) ->

    return  unless editor = @getEditor()
    return  if username is nick()

    oldWidget      = @lineWidgets[username]
    {renderer}     = editor
    widgetManager  = @getAce().lineWidgetManager
    lineHeight     = renderer.lineHeight
    charWidth      = renderer.characterWidth
    color          = getColorFromString username
    widgetStyle    = "border-bottom:2px solid #{color};height:#{lineHeight}px;margin-top:-#{lineHeight+2}px;line-height:#{lineHeight+2}px"
    userWidgetCss  = "ace-line-widget-#{username}"
    lineCssClass   = "ace-line-widget #{userWidgetCss}"
    cursorStyle    = "background-color:#{color};height:#{lineHeight}px;margin-left:#{charWidth*col+3}px"
    usernameStyle  = "background-color:#{color}"
    lineWidgetHTML = """
      <div class='#{lineCssClass}' style='#{widgetStyle}'>
        <span class="username" style='#{usernameStyle}'>#{username}</span>
        <span class="ace-participant-cursor" style="#{cursorStyle}"></span>
      </div>
    """

    if oldWidget
      widgetManager.removeLineWidget oldWidget

    oldWidgetElements = @getElement().querySelectorAll ".#{userWidgetCss}"

    if oldWidgetElements.length
      for el in oldWidgetElements
        parent = el.parentNode
        parent.parentNode.removeChild parent

    lineWidgetOptions =
      row        : row
      rowCount   : 0
      fixedWidth : yes
      editor     : @getEditor()
      html       : lineWidgetHTML

    widgetManager.addLineWidget lineWidgetOptions
    @lineWidgets[username] = lineWidgetOptions


  removeAllCursorWidgets: ->

    widgetManager = @getAce().lineWidgetManager

    for username, widget of @lineWidgets
      widgetManager.removeLineWidget widget

    @lineWidgets = {}


  removeParticipantCursorWidget: (targetUser) ->

    userLineWidget = @lineWidgets?[targetUser]

    if userLineWidget
      widgetManager = @getAce().lineWidgetManager
      widgetManager.removeLineWidget userLineWidget
      delete @lineWidgets[targetUser]


  handleChange: (change) ->

    {context, type, origin} = change

    switch type

      when 'CursorActivity'

        {row, column} = context.cursor
        @setLineWidgets row, column, origin

      when 'FileSaved'

        @getAce().removeModifiedFromTab()
        @getAce().contentChanged = no


  setContentFromCollaborativeString: ->

    return  if @rtm.isDisposed

    {path} = @getFile()

    unless string = @rtm.getFromModel path
      return @rtm.create 'string', path, @getContent()

    ace = @getAce()

    ace.ready =>

        @setContent string.getText(), no

        if ace.contentChanged = ace.isCurrentContentChanged()
          ace.emit 'FileContentChanged'


  listenCollaborativeStringChanges: ->

    return  if @rtm.isDisposed
    return  unless string = @rtm.getFromModel @getFile().path

    @rtm.bindRealtimeListeners string, 'string'

    modificationHandler = @bound 'handleCollaborativeStringEvent'

    @rtm
      .on 'TextInsertedIntoString', modificationHandler
      .on 'TextDeletedFromString', modificationHandler
      .on 'RealtimeManagerWillDispose', @bound 'unsetRealtimeBindings'


  handleCollaborativeStringEvent: (changedString, change) ->

    return  if @isChangedByMe change

    string = @rtm.getFromModel @getFile().path
    return  unless changedString is string

    @applyChange change


  isChangedByMe: (change) -> return change.isLocal


  getRange: (index, length, str) ->

    start   = index
    end     = index + length
    lines   = str.split "\n"
    read    = 0
    points  =
      start : row: 0, column: 0
      end   : row: 0, column: 0

    for line in lines when read <= index
      read                += line.length + 1
      offset               = read - 1 - index
      points.start.row    += 1
      points.start.column  = line.length - offset  if read > index

    points.end.row    = points.start.row
    points.end.column = points.start.column + end - index

    for lineIndex in [points.start.row...lines.length] when read <= end
      line               = lines[lineIndex]
      read              += line.length + 1
      offset             = read - 1 - end
      points.end.row    += 1
      points.end.column  = line.length - offset  if read > end

    points.start.row -= 1
    points.end.row   -= 1

    return points


  applyChange: (change) ->

    isInserted = change.type is 'text_inserted'
    isDeleted  = change.type is 'text_deleted'
    range      = @getRange change.index, change.text.length, @getContent()

    @dontEmitChangeEvent = yes

    if isInserted
      @getEditorSession().insert range.start, change.text

    else if isDeleted
      @getEditorSession().remove range

    @dontEmitChangeEvent = no


  unsetRealtimeBindings: ->

    return  unless string = @rtm.getFromModel @getFile().path

    @rtm.unbindRealtimeListeners string, 'string'
    @removeAllCursorWidgets()


  makeReadOnly: -> @getEditor()?.setReadOnly yes


  makeEditable: -> @getEditor()?.setReadOnly no


  handleSaveFailed: (err) ->

    @errorOnSave = err?
    IDEHelpers.showPermissionErrorOnSavingFile err  if err


  destroy: ->

    @file.off [ 'fs.save.failed', 'fs.saveAs.failed' ], @bound 'handleSaveFailed'

    super


  updateAceViewDelegate: (ideView) -> @aceView?.setDelegate ideView
