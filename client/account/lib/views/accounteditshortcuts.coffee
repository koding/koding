kd       = require 'kd'
_        = require 'lodash'
recorder = require 'record-shortcuts'
Pane     = require './accounteditshortcutspane'
facade   = require './accounteditshortcutsfacade'

module.exports =

class AccountEditShortcuts extends kd.View

  INSTRUCTIONS_CSS_CLASS = 'instructions'
  INSTRUCTIONS_PARTIAL = 'To change a shortcut, click on it, then type the new keys.'
  RESTORE_BUTTON_TITLE = 'Restore Defaults'
  RESTORE_BUTTON_CLASS_NAME = 'solid light-gray medium restore'
  RESTORE_CONFIRM_TEXT = 'Are you sure you want to restore the default shortcuts?'


  destroy: ->

    @parent.parent.off 'KDTabPaneInactive', @bound 'destroy'
    @tabView.off 'PaneDidShow', recorder.cancel

    kd.getSingleton('shortcuts').unpause()
    facade.dispose()

    super


  restoreDefaults: ->

    return  unless confirm RESTORE_CONFIRM_TEXT
    kd.getSingleton('shortcuts').restore()


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
      cssClass : INSTRUCTIONS_CSS_CLASS
      partial  : INSTRUCTIONS_PARTIAL

    @addSubView @tabView = new kd.TabView
      tabClass             : Pane
      paneData             : paneData
      hideHandleCloseIcons : yes
      enableMoveTabHandle  : no

    @tabView.on 'PaneDidShow', recorder.cancel

    @addSubView new kd.ButtonView
      title    : RESTORE_BUTTON_TITLE
      style    : RESTORE_BUTTON_CLASS_NAME
      callback : @bound 'restoreDefaults'

    @tabView.showPaneByIndex 0
