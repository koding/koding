kd                       = require 'kd'
FSFile                   = require 'app/util/fs/fsfile'
IDEPane                  = require './idepane'
AceView                  = require 'ace/aceview'
IDEAce                   = require '../../views/ace/ideace'
IDETailerPaneLineParser  = require './idetailerpanelineparser'

module.exports = class IDETailerPane extends IDEPane

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'editor-pane', options.cssClass
    options.paneType = 'tailer'
    { @file }        = options

    super options, data

    @hash = @file.paneHash  if @file.paneHash
    @ideViewHash = options.ideViewHash

    @lineParser = new IDETailerPaneLineParser()
    @forwardEvent @lineParser, 'BuildDone'
    @forwardEvent @lineParser, 'BuildNotification'

    @createEditor()


  handleFileUpdate: (newLine) ->

    @scrollToBottom()
    @getEditor().insert "\n#{newLine}"
    @lineParser.process newLine


  createEditor: ->

    { file, description, descriptionView, tailOffset, parseOnLoad } = @getOptions()

    unless file instanceof FSFile
      throw new TypeError 'File must be an instance of FSFile'

    aceOptions =
      delegate                 : @getDelegate()
      createBottomBar          : no
      createFindAndReplaceView : no
      aceClass                 : IDEAce

    @addSubView @aceView = new AceView aceOptions, file

    { ace } = @aceView

    ace.ready =>

      ace.setReadOnly      yes
      ace.setScrollPastEnd no

      { descriptionView, description } = @getOptions()
      file = @getData()

      ace.descriptionView = descriptionView ? new kd.View
        partial : description ? "
          This is a file watcher, which allows you to watch the additions
          on <strong>#{@file.getPath()}</strong>. It is a read-only view,
          that means you can't change the content of this file here. If you
          want to edit the contents please open it in edit-mode.
        "
        click : =>
          ace.descriptionView.destroy()
          @resize()

      ace.descriptionView.setClass 'description-view'

      ace.prepend ace.descriptionView

      @emit 'EditorIsReady'
      @emit 'ready'

      kite = @file.machine.getBaseKite()
      kite.tail
        path       : @file.getPath()
        watch      : @bound 'handleFileUpdate'
        lineOffset : tailOffset

      @setScrollMarginTop 15

      @resize()

      @lineParser.process @getContent()  if parseOnLoad


  getAce: ->

    return @aceView.ace


  getEditor: ->

    return @getAce().editor


  setFocus: (state) ->

    super state

    return  unless ace = @getEditor()

    if state
    then ace.focus()
    else ace.blur()

    @parent.tabHandle.unsetClass 'modified'


  getContent: ->

    return if @getEditor() then @getAce().getContents() else ''


  setContent: (content, emitFileContentChangedEvent = yes) ->

    @getAce().setContent content, emitFileContentChangedEvent


  getCursor: ->

    return @getEditor().selection.getCursor()


  setCursor: (positions) ->

    @getEditor().selection.moveCursorTo positions.row, positions.column


  getFile: ->

    return @aceView.getData()


  serialize: ->

    file           = @getFile()
    { paneType }   = @getOptions()
    { name, path } = file

    data       =
      file     : { name, path }
      paneType : paneType
      hash     : @hash

    return data


  scrollToBottom: ->

    content = @getContent()
    line    = (content.split '\n').length

    @setCursor { row: line, column: 0 }
    @getAce().editor.scrollPageDown()


  resize: ->

    height = @getHeight()
    ace    = @getAce()

    ace.setHeight height
    ace.editor.resize()

    @scrollToBottom()


  makeEditable: ->


  makeReadOnly: ->
