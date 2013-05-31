class ApplicationTabView extends KDTabView

  constructor: (options = {}, data) ->

    options.resizeTabHandles            ?= yes
    options.lastTabHandleMargin         ?= 40
    options.sortable                    ?= yes
    options.closeAppWhenAllTabsClosed   ?= yes
    options.saveSession                 ?= no
    options.sessionName                or= ""

    super options, data

    appManager        = KD.getSingleton 'appManager'
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

    @on "SaveSessionData", (data) =>
      @appStorage.setValue "sessions", data if @isSessionEnabled

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
