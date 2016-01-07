kd      = require 'kd'
KDView  = kd.View


module.exports = class StackBaseEditorTabView extends KDView


  constructor: (options = {}, data) ->

    super options, data

    @on 'FocusToEditor', => @editorView?.setFocus yes
