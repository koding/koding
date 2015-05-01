kd       = require 'kd'
_        = require 'lodash'
recorder = require 'record-shortcuts'
Pane     = require './accounteditshortcutspane'
facade   = require './accounteditshortcutsfacade'

RESTORE_CONFIRM_TEXT = 'Are you sure you want to restore the default shortcuts?'

restoreDefaults = ->

  return  unless confirm RESTORE_CONFIRM_TEXT
  kd.getSingleton('shortcuts').restore()
  @domElement.blur()


module.exports =

class AccountEditShortcuts extends kd.View

  destroy: ->

    @parent.parent.off 'KDTabPaneInactive', @bound 'destroy'
    @tabView.off 'PaneDidShow', recorder.cancel

    kd.getSingleton('shortcuts').unpause()
    facade.dispose()

    super


  viewAppended: ->

    @parent.parent.on 'KDTabPaneInactive', @bound 'destroy'

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
