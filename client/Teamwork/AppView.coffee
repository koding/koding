class TeamworkAppView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @emit "ready"

    if location.search.match "chromeapp"
      KD.getSingleton("mainView").enableFullscreen()
      window.parent.postMessage "TeamworkReady", "*"

  handleQuery: (query) ->
    @teamworkApp = @createApp query  unless @teamworkApp
    importUrl = query.importUrl or query.import
    if query.sessionKey then @handleSessionKey query.sessionKey
    else if importUrl then @handleImportUrl importUrl
    else if @teamworkApp.getOption "sessionKey" then @restoreLocation()
    else @teamworkApp.emit "NewSessionRequested"

  handleSessionKey: (sessionKey) ->
    currentSessionKey = @teamworkApp.getOption "sessionKey"
    return @restoreLocation()  if sessionKey is currentSessionKey or (currentSessionKey and not sessionKey)

    if currentSessionKey
    then @showChooseWindowModal sessionKey
    else @teamworkApp.emit "JoinSessionRequested", sessionKey

  handleImportUrl: (importUrl) ->
    @teamworkApp.emit "ImportRequested", importUrl

  showChooseWindowModal: (sessionKey) ->
    modal = new KDModalView
      title      : "Choose session window"
      content    : "Where do you want to open session #{sessionKey}?"
      cssClass   : "tw-modal"
      overlay    : yes
      buttons         :
        CurrentWindow :
          title       : "Current window"
          callback    : =>
            @teamworkApp.emit "JoinSessionRequested", sessionKey
            modal.destroy()
        NewWindow     :
          title       : "New window"
          callback    : =>
            @restoreLocation()
            window.open "#{window.location.origin}/Teamwork?sessionKey=#{sessionKey}", "_blank"
            modal.destroy()

  restoreLocation: ->
    @setLocation @teamworkApp.getOption "sessionKey"

  setLocation: (sessionKey) ->
    KD.singleton("router").handleRoute "/Teamwork?sessionKey=#{sessionKey}",
      replaceState      : yes
      suppressListeners : yes

  createApp: (query) ->
    return new TeamworkApp
      delegate : this
      query    : query

  parentPaneShown: ->
    return  unless @teamworkApp
    element = @teamworkApp.teamwork.chatView.scrollToBottom()

  viewAppended: ->
    @parent.on "PaneDidShow", @bound "parentPaneShown"
