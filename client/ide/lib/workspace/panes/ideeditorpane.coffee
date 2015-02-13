kd = require 'kd'
getColorFromString = require 'app/util/getColorFromString'
nick = require 'app/util/nick'
FSFile = require 'app/util/fs/fsfile'
IDEPane = require './idepane'
Ace = require 'ace/ace'
AceView = require 'ace/aceview'


module.exports = class IDEEditorPane extends IDEPane

  shortcutsShown = no

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'editor-pane', options.cssClass
    options.paneType = 'editor'

    {file}       = options
    @file        = file
    @lineWidgets = {}

    super options, data

    @hash  = file.paneHash  if file.paneHash

    @on 'SaveRequested', @bound 'save'

    @createEditor()

    file.once 'fs.delete.finished', =>
      kd.getSingleton('appManager').tell 'IDE', 'handleFileDeleted', file

    @once 'RealTimeManagerSet', @bound 'setContentFromCollaborativeString'
    @once 'RealTimeManagerSet', @bound 'listenCollaborativeStringChanges'


    @getAce().on 'ace.requests.save', =>
      change = @getInitialChangeObject()
      change.type = 'FileSaved'

      @emit 'ChangeHappened', change


  createEditor: ->

    {file, content} = @getOptions()

    unless file instanceof FSFile
      throw new TypeError 'File must be an instance of FSFile'

    unless content?
      throw new TypeError 'You must pass file content to IDEEditorPane'

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

      kd.singletons.appManager.tell 'IDE', 'setRealTimeManager', this

      @once 'RealTimeManagerSet', =>
        myPermission = @rtm.getFromModel('permissions').get nick()
        @makeReadOnly()  if myPermission is 'read'


  handleAutoSave: ->

    return   if @getFile().path.indexOf('localfile:/') > -1
    @save()  if @getAce().isContentChanged()


  save: ->

    @getAce().emit 'ace.requests.save', @getContent()


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


  getInitialChangeObject: ->

    change        =
      origin      : nick()
      context     :
        paneHash  : @hash
        paneType  : @getOptions().paneType
        file      :
          path    : @file.path
          machine :
            uid   : @file.machine.uid

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


  setLineWidgets: (row, col, username) ->

    oldWidget      = @lineWidgets[username]
    {renderer}     = @getEditor()
    widgetManager  = @getAce().lineWidgetManager
    lineHeight     = renderer.lineHeight
    charWidth      = renderer.characterWidth
    color          = getColorFromString username
    widgetStyle    = "border-bottom:2px dotted #{color};height:#{lineHeight}px;margin-top:-#{lineHeight+2}px;"
    userWidgetCss  = "ace-line-widget-#{username}"
    lineCssClass   = "ace-line-widget #{userWidgetCss}"
    cursorStyle    = "background-color:#{color};height:#{lineHeight}px;margin-left:#{charWidth*col+3}px"
    lineWidgetHTML = """
      <div class='#{lineCssClass}' style='#{widgetStyle}'>
        <span class="username">#{username}</span>
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

    kd.utils.defer =>
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

        @parent.tabHandle.unsetClass 'modified'
        @getAce().contentChanged = no


  setContentFromCollaborativeString: ->

    return  if @rtm.isDisposed

    {path} = @getFile()

    unless string = @rtm.getFromModel path
      return @rtm.create 'string', path, @getContent()

    @setContent string.getText(), no

    ace = @getAce()
    if ace.contentChanged = ace.isCurrentContentChanged()
      ace.emit 'FileContentChanged'


  listenCollaborativeStringChanges: ->

    return  if @rtm.isDisposed
    return  unless string = @rtm.getFromModel @getFile().path

    @rtm.bindRealtimeListeners string, 'string'

    @rtm
      .on 'TextInsertedIntoString', @bound 'handleCollaborativeStringEvent'
      .on 'TextDeletedFromString',  @bound 'handleCollaborativeStringEvent'


  handleCollaborativeStringEvent: (changedString, change) ->

    string = @rtm.getFromModel @getFile().path

    return  if @isChangedByMe change

    string = @rtm.getFromModel @getFile().path
    return  unless changedString is string

    @applyChange change


  isChangedByMe: (change) ->

    for collaborator in @rtm.getCollaborators() when collaborator.isMe
      me = collaborator

    return me.sessionId is change.sessionId


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


  makeReadOnly: ->

    @getEditor()?.setReadOnly yes


  makeEditable: ->

    @getEditor()?.setReadOnly no
