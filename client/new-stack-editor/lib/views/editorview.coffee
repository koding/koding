kd = require 'kd'
AceView = require 'ace/aceview'
FSHelper = require 'app/util/fs/fshelper'
BaseView = require './baseview'

module.exports = class EditorView extends BaseView


  viewAppended: ->

    super

    file = FSHelper.createFileInstance { path: 'localfile:/Untitled.txt' }

    @aceView = new AceView {
      cssClass: 'editor'
      delegate: this
      createBottomBar: no
    }, file

    @aceView.ace.ready =>
      @aceView.ace.editor.renderer.setScrollMargin 0, 15, 0, 0

    @wrapper.addSubView @aceView


  _windowDidResize: ->

    @aceView?._windowDidResize()

    @once 'transitionend', =>
      console.log 'yokladi bi'
      kd.utils.defer => @aceView?._windowDidResize()
