kd = require 'kd'
AceView = require 'ace/aceview'
FSHelper = require 'app/util/fs/fshelper'
BaseView = require './baseview'


module.exports = class Editor extends BaseView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'editor-view', options.cssClass

    super options, data


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

      @emit 'ready'

    @wrapper.addSubView @aceView


  setContent: (content, type = 'text') -> @ready =>
    @_getSession().setValue content


  _windowDidResize: ->

    @aceView?._windowDidResize()
    @once 'transitionend', =>
      kd.utils.defer => @aceView?._windowDidResize()
  _getSession: -> @aceView.ace.editor.getSession()

