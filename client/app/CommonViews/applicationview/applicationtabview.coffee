class ApplicationTabView extends KDTabView

  constructor: (options = {}, data) ->

    options.resizeTabHandles             = yes
    options.lastTabHandleMargin          = 40
    options.sortable                     = yes
    options.closeAppWhenAllTabsClosed  or= yes
    options.saveSession                or= no
    options.sessionName                or= ""

    super options, data

    @isSessionEnabled = options.saveSession and options.sessionName

    @initSession() if @isSessionEnabled

    @on "PaneRemoved", =>
      if @panes.length is 0
        @getDelegate().emit "AllViewsClosed"
        if options.closeAppWhenAllTabsClosed
          appManager = KD.getSingleton "appManager"
          appManager.quit appManager.frontApp

      @tabHandleContainer.repositionPlusHandle @handles

    @on "PaneAdded", =>
      @tabHandleContainer.repositionPlusHandle @handles
      @updateSession() if @isSessionEnabled and @sessionData

    @on "SaveSessionData", (data) =>
      @appStorage.setValue "sessions", data if @isSessionEnabled

  initSession: ->
    @appStorage = new AppStorage @getOptions().sessionName, "0.5"

    @appStorage.fetchStorage (storage) =>
      data = @appStorage.getValue "sessions"
      @sessionData = data or {}
      @restoreSession data

  updateSession: ->
    @getDelegate().emit "UpdateSessionData", @panes, @sessionData

  restoreSession: ->
    @getDelegate().emit "SessionDataCreated", @sessionData
