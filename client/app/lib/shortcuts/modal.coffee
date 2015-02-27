kd = require 'kd'
_ = require 'underscore'
ShortcutsList = require './list'

module.exports = class ShortcutsModal extends kd.ModalView

  constructor: (options={}, data) ->

    options.title or= 'Shortcuts'
    options.content or= """
      <div class='modalformline'>
        <p>To change a shortcut, select it, click the key combination, and then type the new keys.</p>
      </div>
    """
    options.overlay or= true
    options.width or= 620
    options.height or= 'auto'

    super options, data

  viewAppended: ->
    
    tabs = new kd.TabView
      hideHandleCloseIcons: true
      enableMoveTabHandle: false
      paneData: _.map @data, (value) ->
        title: value.title
        view: new ShortcutsList {}, value.shortcuts

    @addSubView tabs

    restoreDefaults = new kd.ButtonView
      title: 'Restore Defaults'
      callback: kd.noop
    
    @addSubView restoreDefaults