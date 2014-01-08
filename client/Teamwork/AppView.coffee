class TeamworkAppView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @emit "ready"

    if location.search.match "chromeapp"
      KD.getSingleton("mainView").enableFullscreen()
      window.parent.postMessage "TeamworkReady", "*"

  handleQuery: (query) ->
    @teamworkApp = @createApp query  unless @teamworkApp
    return  @teamworkApp.emit "NewSessionRequested"  unless query
    if query.sessionKey then @handleSessionKey query.sessionKey
    else if query.importUrl then @handleImportUrl query.importUrl
    else @teamworkApp.emit "NewSessionRequested"

  handleSessionKey: (sessionKey) ->
    return  if sessionKey is @teamworkApp.getOption "sessionKey"
    @teamworkApp.emit "JoinSessionRequested", sessionKey

  handleImportUrl: (importUrl) ->
    @teamworkApp.emit "ImportRequested", importUrl

  createApp: (query) ->
    return new TeamworkApp
      delegate : this
      query    : query
