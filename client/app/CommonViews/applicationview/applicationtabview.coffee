class ApplicationTabView extends KDTabView

  constructor: (options = {}, data) ->

    options.resizeTabHandles             = yes
    options.lastTabHandleMargin          = 40
    options.sortable                     = yes
    options.saveSession                or= no
    options.sessionName                or= ""
    options.sessionKey                 or= "sessions"
    options.closeAppWhenAllTabsClosed  or= yes

    super options, data

    @isSessionEnabled = options.saveSession and options.sessionName
    appManager        = KD.getSingleton 'appManager'

    @on 'PaneAdded', (pane)=>
      @tabHandleContainer.repositionPlusHandle @handles
      @initSession @panes.last, @bound "updateSession" if @isSessionEnabled

      tabView = this
      pane.on "KDTabPaneDestroy", ->
        # -1 because the pane is still there but will be destroyed after this event
        if tabView.panes.length - 1 is 0 and options.closeAppWhenAllTabsClosed
          appManager.quit appManager.getFrontApp()
        tabView.tabHandleContainer.repositionPlusHandle tabView.handles
        tabView.removeFromSession yes

    @on 'SaveSession', (data) =>
      @appStorage.setValue @getOptions().sessionKey, data



  # FIXME: @fatihacet ace related stuff can not live here in this file
  # please generalize this - SY
  # session related methods

  fetchStorage: (callback) ->
    @appStorage.fetchValue @getOptions().sessionKey, (data) => callback? data

  initSession: (pane, callback) ->
    options     = @getOptions()
    @appStorage = new AppStorage options.sessionName, '0.2'

    @fetchStorage (data) =>
      if data then @restoreSession data, pane
      callback?()

  removeFromSession: (isTabClosed) ->
    viewId = @getDelegate().id
    if @isSessionEnabled
      @fetchStorage (data) =>
        if isTabClosed
          openFilePaths = []
          openFilePaths.push pane.getOptions().aceView.getData().path for pane in @panes
          data[viewId] = openFilePaths
          if data[viewId].length is 0
            delete data[viewId]
            data.latestSessions.splice data.latestSessions.indexOf(viewId), 1
        else
          delete data[viewId]
          data.latestSessions.splice data.latestSessions.indexOf(viewId), 1

        @emit "SaveSession", data

  updateSession: ->
    if @isSessionEnabled
      @fetchStorage (data) =>
        @getDelegate().emit "UpdateSessionData", @panes, data

  restoreSession: (data, pane) ->
    return if data.latestSessions.length is 0
    @getDelegate().emit "SessionListCreated", pane, @createSessionItems data

  createSessionItems: (data) ->
    items = {}
    date  = new Date()

    data.latestSessions.forEach (sessionId, i) =>
      isSessionActive = yes for aceApp in appManager.appControllers.Ace when aceApp.getView().id is sessionId
      unless isSessionActive
        sessionItems    = data[sessionId]
        itemLen         = sessionItems.length
        itemTxt         = if itemLen is 1 then "file" else "files"
        formattedDate   = dateFormat date.setTime(sessionId.split("_")[1]), "dd mmm yyyy - HH:MM"
        items["#{formattedDate} (#{itemLen} #{itemTxt})"] =
          callback: => @getDelegate().emit "SessionItemClicked", sessionItems

    items.separator = type: "separator"

    fileCount = 0
    for sessionId in data.latestSessions
      isSessionActive = yes for aceApp in appManager.appControllers.Ace when aceApp.getView().id is sessionId
      unless isSessionActive
        sessionItems = data[sessionId]
        sessionItems.forEach (path, i) =>
          if fileCount < 10
            filePath = path.replace("/home/#{KD.whoami().profile.nickname}", "~")
            items[filePath] = callback: => @getDelegate().emit "SessionItemClicked", [path]
            fileCount++

    return items

  # end of session related methods