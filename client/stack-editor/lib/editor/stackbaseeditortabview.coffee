kd      = require 'kd'
isMine  = require 'app/util/isMine'

module.exports = class StackBaseEditorTabView extends kd.View


  constructor: (options = {}, data) ->

    super options, data

    kd.singletons.groupsController.ready =>

      { groupsController } = kd.singletons

      return  unless data

      { stackTemplate } = data

      return if groupsController.canEditGroup() or isMine(stackTemplate)

      @setClass 'isntMine'
      @editorView?.aceView.ace.editor.setReadOnly yes

    @on 'FocusToEditor', => @editorView?.setFocus yes
