kd            = require 'kd'
_             = require 'underscore'
ShortcutsPane = require './pane'
defaults      = require '../config'

module.exports =

class ShortcutsModal extends kd.ModalView

  constructor: (options={}, keyconfig) ->

    options.title   or= 'Shortcuts'
    options.content or= """
      <div class='shortcuts-head'>
        <p>To change a shortcut, select it, click the key combination, and then type the new keys.</p>
      </div>
    """
    options.overlay  or= yes
    options.width    or= 540
    options.height   or= 600
    options.cssClass or= 'shortcuts-modal'

    super options, keyconfig


  viewAppended: ->

    @addSubView tabView = new kd.TabView

      hideHandleCloseIcons : true
      enableMoveTabHandle  : false
      cssClass             : 'shortcuts-tab'

      paneData: @data.map (collection) ->
        displayData = defaults[collection.name]
        return {
          title    : displayData.title
          closable : no
          view     : new ShortcutsPane {},
            title       : displayData.title
            description : displayData.description
            collection  : collection
        }

    tabView.showPaneByIndex 0

    buttonBar = new kd.View
      cssClass: 'buttons'

    buttonBar.addSubView new kd.ButtonView
      title    : 'Restore Defaults'
      cssClass : 'solid light-gray medium'
      callback : kd.noop

    buttonBar.addSubView new kd.ButtonView
      title    : 'Save'
      cssClass : 'solid green medium'
      callback : kd.noop

    @addSubView buttonBar