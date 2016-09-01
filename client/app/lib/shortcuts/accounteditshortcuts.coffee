kd          = require 'kd'
recorder    = require 'record-shortcuts'
Pane        = require './accounteditshortcutspane'
facade      = require './accounteditshortcutsfacade'
KDModalView = kd.ModalView

RESTORE_CONFIRM_TEXT = 'Are you sure you want to restore the default shortcuts?'

restoreDefaults = ->

  modal = KDModalView.confirm
    title        : 'Are you sure?'
    description  : RESTORE_CONFIRM_TEXT
    ok           :
      style      : 'solid medium red'
      title      : 'Restore'
      callback   : =>
        kd.getSingleton('shortcuts').restore()
        @domElement.blur()
        modal.destroy()
    cancel       :
      style      : 'solid medium light-gray'
      title      : 'Cancel'
      callback   : -> modal.destroy()

require './shortcuts.styl'

module.exports =

class AccountEditShortcuts extends kd.View

  constructor: (options = {}, data) ->
    options.cssClass = 'AccountEditShortcuts'

    super options, data

  destroy: ->

    @tabView.off 'PaneDidShow', recorder.cancel

    kd.getSingleton('shortcuts').unpause()
    facade.dispose()

    super


  viewAppended: ->

    { shortcuts } = kd.singletons

    shortcuts.pause()

    # Exclude hidden shortcuts.
    predicate = (model) -> true unless model.options and model.options.hidden
    paneData =
      shortcuts.toCollection(predicate).map (collection) ->
        name       : collection.title
        collection : collection

    @addSubView new kd.View
      cssClass : 'instructions'
      partial  : 'To change a shortcut, click on it, then type the new keys.'

    @addSubView @tabView = new kd.TabView
      cssClass             : 'ShortcutsModalTabView'
      tabClass             : Pane
      paneData             : paneData
      hideHandleCloseIcons : yes
      enableMoveTabHandle  : no

    @tabView.on 'PaneDidShow', recorder.cancel

    @addSubView new kd.ButtonView
      title    : 'Restore Defaults'
      style    : 'solid light-gray medium restore'
      callback : restoreDefaults

    @tabView.showPaneByIndex 0
