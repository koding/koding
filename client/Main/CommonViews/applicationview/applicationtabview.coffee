class ApplicationTabView extends KDTabView

  constructor: (options = {}, data) ->

    options.resizeTabHandles            ?= yes
    options.lastTabHandleMargin         ?= 40
    options.sortable                    ?= yes
    options.closeAppWhenAllTabsClosed   ?= yes
    options.saveSession                 ?= no
    options.sessionName                or= ""
    options.cssClass = KD.utils.curry 'application-tabview', options.cssClass

    super options, data

    appManager        = KD.getSingleton "appManager"
    @isSessionEnabled = options.saveSession and options.sessionName

    @initSession() if @isSessionEnabled

    @on "PaneAdded", (pane) =>
      @tabHandleContainer.repositionPlusHandle @handles
      @updateSession() if @isSessionEnabled and @sessionData

      tabView = this
      pane.on "KDTabPaneDestroy", ->
        # -1 because the pane is still there but will be destroyed after this event
        if tabView.panes.length - 1 is 0 and options.closeAppWhenAllTabsClosed
          appManager.quit appManager.getFrontApp()
        tabView.tabHandleContainer.repositionPlusHandle tabView.handles

      {tabHandle}  = pane
      {plusHandle} = @getOptions().tabHandleContainer
      tabHandle.on "DragInAction", =>
        plusHandle.hide() if tabHandle.dragIsAllowed
      tabHandle.on "DragFinished", =>
        plusHandle.show()

    @on "SaveSessionData", (data) =>
      @appStorage.setValue "sessions", data if @isSessionEnabled

    focusActivePane = (pane)=>
      if mainView = pane.getMainView()
        {tabView} = pane.getMainView()
        if this is tabView
          @getActivePane()?.getHandle?().$().click()

    mainView = KD.getSingleton("mainViewController").getView()
    mainView.mainTabView.on "PaneDidShow", focusActivePane

    @on "KDObjectWillBeDestroyed", ->
      mainView.mainTabView.off "PaneDidShow", focusActivePane


  initSession: ->
    @appStorage = new AppStorage @getOptions().sessionName, "1.0"

    @appStorage.fetchStorage (storage) =>
      data = @appStorage.getValue "sessions"
      @sessionData = data or {}
      @restoreSession data

  updateSession: ->
    @getDelegate().emit "UpdateSessionData", @panes, @sessionData

  restoreSession: ->
    @getDelegate().emit "SessionDataCreated", @sessionData
