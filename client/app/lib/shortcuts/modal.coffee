kd            = require 'kd'
_             = require 'underscore'
ShortcutsPane = require './pane'
defaults      = require './defaults'

module.exports =

class ShortcutsModal extends kd.ModalView

  constructor: (options={}, keyconfig) ->

    options.title   or= 'Shortcuts'
    options.content or= """
      <div class='shortcuts-head'>
        <p>To change a shortcut, select it, click the key combination, and then type the new keys.</p>
      </div>
    """
    options.overlay or= yes
    options.width   or= 540
    options.height  or= 520
    options.cssClass or= 'shortcuts-modal'

    super options, keyconfig


  viewAppended: ->

    @addSubView new kd.TabView
      hideHandleCloseIcons : true
      enableMoveTabHandle  : false
      cssClass: 'shortcuts-tab'
      paneData: @data.map (collection) ->
        displayData = defaults[collection.name]
        return {
          title : displayData.title
          view  : new ShortcutsPane {},
            title: displayData.title
            description: displayData.description
            collection: collection
          closable : no
        }

    @addSubView new kd.ButtonView
      title    : 'Restore Defaults'
      callback : kd.noop

    @addSubView new kd.ButtonView
      title    : 'Save'
      callback : kd.noop