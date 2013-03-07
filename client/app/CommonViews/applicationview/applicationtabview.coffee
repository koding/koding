class ApplicationTabView extends KDTabView
  constructor: (options = {}, data) ->

    options.resizeTabHandles       = yes
    options.lastTabHandleMargin    = 40
    options.sortable               = yes
    options.saveSession          or= no
    options.sessionName          or= ""
    options.sessionKey           or= "sessions"

    super options, data

    @isSessionEnabled = options.saveSession and options.sessionName

    appView = @getDelegate()

    @on 'PaneRemoved', =>
      appView.emit 'AllViewsClosed' if @panes.length is 0
      @tabHandleContainer.repositionPlusHandle @handles
      @removeFromSession yes

    @on 'PaneAdded', =>
      @tabHandleContainer.repositionPlusHandle @handles
      @initSession @panes.last, => @updateSession() if @isSessionEnabled

    @on 'SaveSession', (data) =>
      @appStorage.setValue @getOptions().sessionKey, data

    @on "SessionItemClicked", (items) =>
      @getDelegate().openFile FSHelper.createFileFromPath file for file in items

    appView.on "AceAppDidQuit", => @removeFromSession no

  fetchStorage: (callback) ->
    @appStorage.fetchValue @getOptions().sessionKey, (data) => callback? data

  initSession: (pane, callback) ->
    options     = @getOptions()
    @appStorage = new AppStorage options.sessionName, '0.1'

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
        @getDelegate().emit 'UpdateSessionData', @panes, data

  restoreSession: (data, pane) ->
    return if data.latestSessions.length is 0
    @getDelegate().emit "SessionListCreated", pane, @createSessionList data

  createSessionList: (data) ->
    items = @createSessionItems data
    button = new KDButtonViewWithMenu
      title    : "Sessions"
      cssClass : "editor-button ace-session-button"
      menu     : => items

    return button

  createSessionItems: (data) ->
    items      = {}
    delegate   = @getDelegate()
    date       = new Date()

    data.latestSessions.forEach (sessionId, i) =>
      isSessionActive = yes for aceApp in appManager.appControllers.Ace when aceApp.getView().id is sessionId
      unless isSessionActive
        sessionItems    = data[sessionId]
        itemLen         = sessionItems.length
        itemTxt         = if itemLen is 1 then "file" else "files"
        formattedDate   = dateFormat date.setTime(sessionId.split("_")[1]), "dd mmm yyyy - HH:MM"
        items["#{formattedDate} (#{itemLen} #{itemTxt})"] =
          callback: => @emit "SessionItemClicked", sessionItems

    items.separator = type: "separator"

    fileCount = 0
    for sessionId in data.latestSessions
      isSessionActive = yes for aceApp in appManager.appControllers.Ace when aceApp.getView().id is sessionId
      unless isSessionActive
        sessionItems = data[sessionId]
        for path, i in sessionItems
          if fileCount < 10
            filePath = path.replace("/Users/#{KD.whoami().profile.nickname}", "~")
            items[filePath] = callback: @emit.bind(@, "SessionItemClicked", [path])
            fileCount++

    return items
