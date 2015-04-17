kd     = require 'kd'
_      = require 'lodash'
Pane   = require './accounteditshortcutspane'
facade = require './accounteditshortcutsfacade'

module.exports = class AccountEditShortcuts extends kd.View

  constructor: (options={}, data) ->

    super options, data


  destroy: ->

    @parent.parent.off 'KDTabPaneInactive', @bound 'destroy'

    kd.getSingleton('shortcuts').unpause()
    facade.dispose()

    super


  restoreDefaults: ->

    console.log 'not implemented'


  viewAppended: ->

    @parent.parent.on 'KDTabPaneInactive', @bound 'destroy'

    { shortcuts } = kd.singletons

    shortcuts.pause()

    # exclude hidden shortcuts
    predicate = (model) -> true unless model.options and model.options.hidden
    paneData =
      shortcuts.toCollection(predicate).map (collection) ->
        name: collection.title
        collection: collection
        cssClass: 'pane'

    @addSubView new kd.View
      tagName: 'div'
      cssClass: 'instructions'
      partial: 'To change a shortcut, click the key combination, then type the new keys.'

    @addSubView tabView = new kd.TabView
      tabClass: Pane
      paneData: paneData
      hideHandleCloseIcons: yes
      enableMoveTabHandle: no

    @addSubView new kd.ButtonView
      title: 'Restore Defaults'
      style: 'solid light-gray medium restore'
      callback: @bound 'restoreDefaults'

    tabView.showPaneByIndex 0
