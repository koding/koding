kd      = require 'kd'
KDView  = kd.View
curryIn = require 'app/util/curryIn'

module.exports = class StackBaseEditorTabView extends KDView


  constructor: (options = {}, data) ->

    if data
      { stackTemplate } = data
    unless stackTemplate?.isMine()
      curryIn options, { cssClass: 'isntMine' }

    super options, data

    @on 'FocusToEditor', => @editorView?.setFocus yes
