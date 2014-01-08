class TeamworkAppView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @emit "ready"

    if location.search.match "chromeapp"
      KD.getSingleton("mainView").enableFullscreen()
      window.parent.postMessage "TeamworkReady", "*"

  handleQuery: (query) ->
    @teamworkApp = @createApp query  unless @teamworkApp

  createApp: (query) ->
    return new TeamworkApp
      delegate : this
      query    : query
