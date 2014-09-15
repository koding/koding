MainTabPane = require './maintabpaneview'

module.exports = class MainTabView extends KDTabView

  constructor:(options,data)->

    options.hideHandleContainer = yes

    super options,data

    @router = KD.getSingleton 'router'


  removePane: (pane) ->
    # we don't want to use ::showPane
    # to show the previousPane when a pane
    # is removed, that's why we override it to use
    # kodingrouter

    index = @getPaneIndex pane

    pane.emit 'KDTabPaneDestroy'

    isActivePane = @getActivePane() is pane
    @panes.splice index, 1
    pane.destroy()

    handle = @getHandleByIndex index
    @handles.splice index, 1
    handle?.destroy()

    @emit 'PaneRemoved'

    @router.handleRoute @router.currentPath


  createTabPane:(options = {}, mainView)->

    o              = {}
    o.cssClass     = @utils.curry 'content-area-pane', options.cssClass
    o.name         = options.name
    o.view         = mainView
    paneInstance   = new MainTabPane o

    @addPane paneInstance

    return paneInstance
