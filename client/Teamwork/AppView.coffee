class TeamworkAppView extends KDView

  constructor: (options = {}, data) ->

    super options, data

    @emit "ready"

    if location.search.match "chromeapp"
      KD.getSingleton("mainView").enableFullscreen()
      window.parent.postMessage "TeamworkReady", "*"

  handleQuery: (query) ->
