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

    appManager        = KD.getSingleton "appManager"

    @on "PaneAdded", (pane) =>
      @tabHandleContainer.repositionPlusHandle @handles
      tabView = this
      pane.on "KDTabPaneDestroy", ->
        # -1 because the pane is still there but will be destroyed after this event
        if tabView.panes.length - 1 is 0
          if options.closeAppWhenAllTabsClosed
            appManager.quit appManager.getFrontApp()
          tabView.emit "AllTabsClosed"
        tabView.tabHandleContainer.repositionPlusHandle tabView.handles

      {tabHandle}  = pane
      {plusHandle} = @getOptions().tabHandleContainer
      tabHandle.on "DragInAction", ->
        plusHandle?.hide() if tabHandle.dragIsAllowed
      tabHandle.on "DragFinished", ->
        plusHandle?.show()

    focusActivePane = (pane)=>
      if mainView = pane.getMainView()
        {tabView} = pane.getMainView()
        if this is tabView
          @getActivePane()?.getHandle()?.$().click()

    {mainController, mainViewController} = KD.singletons
    mainController.ready =>
      mainView = mainViewController.getView()
      mainView.mainTabView.on "PaneDidShow", focusActivePane

    @on "KDObjectWillBeDestroyed", ->
      mainView.mainTabView.off "PaneDidShow", focusActivePane
