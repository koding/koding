class ApplicationTabView extends KDTabView

  constructor: (options = {}, data) ->

    options.resizeTabHandles            ?= yes
    options.lastTabHandleMargin         ?= 80
    options.sortable                    ?= yes
    options.closeAppWhenAllTabsClosed   ?= yes
    options.enableMoveTabHandle         ?= no
    options.detachPanes                 ?= no
    options.cssClass = KD.utils.curry 'application-tabview', options.cssClass

    super options, data

    appManager = KD.getSingleton "appManager"

    @on "PaneAdded", (pane) =>
      @tabHandleContainer.repositionPlusHandle @handles

      pane.on "KDTabPaneDestroy", ->
        # -1 because the pane is still there but will be destroyed after this event
        if @panes.length - 1 is 0
          if options.closeAppWhenAllTabsClosed
            appManager.quit appManager.getFrontApp()

          @emit "AllTabsClosed"

        @tabHandleContainer.repositionPlusHandle @handles

      {tabHandle}  = pane
      {plusHandle} = @getOptions().tabHandleContainer

      tabHandle.on "DragInAction", ->
        plusHandle?.hide() if tabHandle.dragIsAllowed

      tabHandle.on "DragFinished", ->
        plusHandle?.show()
