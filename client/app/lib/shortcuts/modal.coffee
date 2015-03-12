kd            = require 'kd'
_             = require 'underscore'
ShortcutsPane = require './pane'

module.exports =

class ShortcutsModal extends kd.ModalView

  constructor: (options={}, keyconfig) ->

    options.title   or= 'Shortcuts'
    options.content or= """
      <div class='modalformline'>
        <p>To change a shortcut, select it, click the key combination, and then type the new keys.</p>
      </div>
    """
    options.overlay or= yes
    options.width   or= 522
    options.height  or= 'auto'

    super options, keyconfig


  viewAppended: ->

    @addSubView new kd.TabView
      hideHandleCloseIcons : true
      enableMoveTabHandle  : false
      paneData             : @data.map (set) ->
        title : set.name
        view  : new ShortcutsPane {}, set

    @addSubView new kd.ButtonView
      title    : 'Restore Defaults'
      callback : kd.noop

    @addSubView new kd.ButtonView
      title    : 'Save'
      callback : kd.noop