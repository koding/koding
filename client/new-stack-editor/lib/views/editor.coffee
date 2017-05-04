debug = (require 'debug') 'nse:editor'

kd = require 'kd'
AceView = require 'ace/aceview'
FSHelper = require 'app/util/fs/fshelper'

Events = require '../events'
BaseView = require './baseview'

yamlutils = require 'app/util/stacks/yamlutils'


module.exports = class Editor extends BaseView


  constructor: (options = {}, data) ->

    options.cssClass    = kd.utils.curry 'editor-view', options.cssClass
    options.filename   ?= 'untitled.yaml'
    options.showgutter ?= yes
    options.readonly   ?= no
    options.preview    ?= no

    super options, data

    @_initialContent = ''

    { filename, preview } = @getOptions()

    @aceView = new AceView {
      cssClass: 'editor'
      useStorage: no
      createBottomBar: no
    }, FSHelper.createFileInstance { path: "localfile:/#{filename}" }

    @getPreview = preview  if preview


  getContent: (as) ->

    content = @aceView.ace.getContents()

    switch as
      when 'json'
        { content } = yamlutils.yamlToJson content
      when 'yaml'
        { content } = yamlutils.jsonToYaml content

    return content


  parseContent: ->

    { err, content, contentObject } = yamlutils.yamlToJson @getContent()
    return [ err, contentObject ]


  setContent: (content, type = 'text') -> @ready =>

    @_initialContent = content
    @_getSession().setValue content


  hasChange: ->
    @getContent() isnt @_initialContent


  addContent: (content) -> @ready =>

    session = @_getSession()
    [ row, column ] = [ session.getLength(), 0 ]
    session.insert { row, column }, "#{content}\n"
    @scrollToBottom()


  scrollToBottom: -> @ready =>

    { editor } = @aceView.ace
    line = @_getSession().getLength()
    editor.scrollToLine line, yes, yes, kd.noop
    editor.gotoLine line, 0, yes


  focus: -> @ready =>
    @aceView.ace.focus()


  setReadOnly: (state) -> @ready =>

    if intialState = @getOption 'readonly'
      state = intialState

    @aceView.ace.setReadOnly state, no
    state = if state then 'none' else 'block'
    @aceView.ace.editor.renderer.$cursorLayer.element.style.display = state


  viewAppended: ->

    super

    { showgutter, readonly, theme = 'base16' } = @getOptions()

    { ace } = @aceView

    ace.ready =>

      @setReadOnly readonly

      ace.setTheme theme, no
      ace.setTabSize 2, no
      ace.setShowPrintMargin no, no
      ace.setShowGutter showgutter, no
      ace.setUseSoftTabs yes, no
      ace.setScrollPastEnd no, no
      ace.contentChanged = no
      ace.lastSavedContents = ace.getContents()

      ace.editor.renderer.setScrollMargin 0, 15, 0, 0
      @_getSession().setScrollTop 0

      ace.off 'ace.requests.save'
      ace.off 'ace.requests.saveAs'

      ace.editor.on 'focus', @lazyBound 'setClass',   'focus'
      ace.editor.on 'blur',  @lazyBound 'unsetClass', 'focus'

      if @getOption 'statusbar'
        ace.editor.on 'focus', @bound '_updateStatusBar'
        @_notifyStatusbar()

      @emit 'ready'

    @wrapper.addSubView @aceView
    @on Events.GotFocus, @bound 'focus'


  _windowDidResize: ->

    @aceView?._windowDidResize()
    @once 'transitionend', =>
      kd.utils.defer => @aceView?._windowDidResize()


  _updateStatusBar: ->

    { statusbar, title } = @getOptions()
    cursor = @_getSession().selection.getCursor()
    statusbar.setData {
      row    : ++cursor.row
      column : ++cursor.column
      title  : @getOption 'title'
    }


  _notifyStatusbar: ->

    return  unless @getOption 'statusbar'

    session = @_getSession()
    session.selection.on 'changeCursor', @bound '_updateStatusBar'


  # restore/dump functionality referenced from following example ~ GG
  # http://stackoverflow.com/questions/28257566/ace-editor-save-send-session-on-server-via-post

  filterHistory = (deltas) ->
    deltas.filter (d) -> d.group isnt 'fold'


  _getSession: -> @aceView.ace.editor.getSession()


  _dump: ->

    session   = @_getSession()
    selection : session.selection.toJSON()
    value     : session.getValue()
    history   :
      undo    : session.$undoManager.$undoStack.map filterHistory
      redo    : session.$undoManager.$redoStack.map filterHistory
    scrollTop : session.getScrollTop()
    scrollLeft: session.getScrollLeft()
    options   : session.getOptions()


  _restore: (dump) ->

    session = (require 'brace').createEditSession dump.value

    session.$undoManager.$doc = session # workaround for a bug in ace
    session.setOptions dump.options
    session.$undoManager.$undoStack = dump.history.undo
    session.$undoManager.$redoStack = dump.history.redo
    session.selection.fromJSON dump.selection
    session.setScrollTop dump.scrollTop
    session.setScrollLeft dump.scrollLeft

    @aceView.ace.editor.setSession session
    @_notifyStatusbar()
    @_updateStatusBar()
