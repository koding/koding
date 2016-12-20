kd = require 'kd'
AceView = require 'ace/aceview'
FSHelper = require 'app/util/fs/fshelper'
BaseView = require './baseview'


module.exports = class Editor extends BaseView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'editor-view', options.cssClass

    super options, data


  setContent: (content, type = 'text') -> @ready =>
    @_getSession().setValue content


  viewAppended: ->

    super

    file = FSHelper.createFileInstance { path: 'localfile:/Untitled.yaml' }

    @aceView = new AceView {
      cssClass: 'editor'
      useStorage: no
      createBottomBar: no
    }, file

    { ace } = @aceView

    ace.ready =>

      ace.setTheme 'base16', no
      ace.setTabSize 2, no
      ace.setShowPrintMargin no, no
      ace.setUseSoftTabs yes, no
      ace.setScrollPastEnd no, no
      ace.contentChanged = no
      ace.lastSavedContents = ace.getContents()

      ace.editor.renderer.setScrollMargin 0, 15, 0, 0
      @_getSession().setScrollTop 0

      ace.off 'ace.requests.save'
      ace.off 'ace.requests.saveAs'

      if @getOption 'statusbar'
        ace.editor.on 'focus', @bound '_updateStatusBar'
        @_notifyStatusbar()

      @emit 'ready'

    @wrapper.addSubView @aceView


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
