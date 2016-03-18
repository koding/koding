kd        = require 'kd'
KDTabView = kd.TabView


module.exports = class ApplicationTabView extends KDTabView

  constructor: (options = {}, data) ->

    options.resizeTabHandles            ?= yes
    options.lastTabHandleMargin         ?= 90
    options.closeAppWhenAllTabsClosed   ?= yes
    options.enableMoveTabHandle         ?= no
    options.detachPanes                 ?= no
    options.sortable                    ?= yes
    options.droppable                   ?= yes

    options.cssClass = kd.utils.curry 'application-tabview', options.cssClass

    super options, data

    appManager        = kd.getSingleton 'appManager'

    @on 'PaneAdded', (pane) =>
      @tabHandleContainer.repositionPlusHandle @handles
      tabView = this

      pane.on 'KDTabPaneDestroy', ->
        # -1 because the pane is still there but will be destroyed after this event
        if tabView.panes.length - 1 is 0

          if options.closeAppWhenAllTabsClosed
            appManager.quit appManager.getFrontApp()

          tabView.emit 'AllTabsClosed'

        tabView.tabHandleContainer.repositionPlusHandle tabView.handles

      { tabHandle }  = pane
      { plusHandle } = @getOptions().tabHandleContainer

      tabHandle.on 'DragInAction', ->
        plusHandle?.hide() if tabHandle.dragIsAllowed

      tabHandle.on 'DragFinished', ->
        plusHandle?.show()
