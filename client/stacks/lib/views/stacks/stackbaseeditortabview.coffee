kd      = require 'kd'
KDView  = kd.View
curryIn = require 'app/util/curryIn'

module.exports = class StackBaseEditorTabView extends KDView


  constructor: (options = {}, data) ->

    super options, data

    kd.singletons.groupsController.ready =>
      
      { groupsController } = kd.singletons
      
      return  unless data
      
      { stackTemplate } = data
      isMine = stackTemplate?.isMine() or groupsController.canEditGroup()
      return  if isMine
      @setClass 'isntMine'
      @editorView.once 'EditorReady', =>
        @editorView.aceView.ace.editor.setReadOnly yes

    @on 'FocusToEditor', => @editorView?.setFocus yes
    