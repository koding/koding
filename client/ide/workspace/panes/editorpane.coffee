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

  getValue: ->
    return  @getEditor().getSession().getValue()

  goToLine: (lineNumber) ->
    @getAce().gotoLine lineNumber

  getContent: ->
    return @getAce().getContents()

  setContent: (content) ->
    @getAce().editor.setValue content, -1

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
      change.context.content = @getContent()

      @emit 'ChangeHappened', change

    ace.on 'FileContentSynced', =>
      change.type = 'FileSave'

      @emit 'ChangeHappened', change

  serialize: ->
    file       = @getFile()
    content    = @getContent()
    cursor     = @getCursor()
    {paneType} = @getOptions()
    {machine}  = file


    {name, path } = file
    {label, ipAddress, slug, uid} = machine

    data       =
      file     : { name, path, content, cursor }
      machine  : { label, ipAddress, slug, uid }
      paneType : paneType
      hash     : @hash

    return data
