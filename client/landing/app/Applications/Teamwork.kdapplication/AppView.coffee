class TeamworkAppView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @emit "ready"

    if location.search.match "chromeapp"
      KD.getSingleton("mainView").enableFullscreen()
      window.parent.postMessage "TeamworkReady", "*"

  handleQuery: (query) ->
    if query.import
      teamworkApp = new TeamworkApp
      {teamwork}  = teamworkApp
      @addSubView teamwork
      teamwork.on "WorkspaceSyncedWithRemote", =>
        teamworkApp.showImportWarning query.import
    else if query.playground
      teamworkApp = new TeamworkApp playground: query.playground
      @addSubView teamworkApp.teamwork
    else
      teamworkApp = new TeamworkApp sessionKey: query.sessionKey
      @addSubView teamworkApp.teamwork
