class FatihOpenAppPlugin extends FatihPluginAbstract

  constructor: (options = {}, data) ->

    options.name          = "Application Runner"
    options.keyword       = "open"
    options.notFoundText  = "Cannot find an application like that."

    super options, data

    @on "FatihPluginListItemClicked", (item) ->
      KD.getSingleton("appManager").open item.data.name
      @fatihView.destroy()

  generateIndex: ->
    KD.getSingleton("kodingAppsController").fetchApps (err, res = {}) =>
      res.Terminal = name : "WebTerm"
      res.Ace      = name : "Ace"
      @index       = res

  action: (keyword) ->
    keyword        = keyword.toLowerCase()
    possibleApps   = []

    for appName of @index
      currentApp   = @index[appName]
      lowerAppName = currentApp.name.toLowerCase()
      app          = currentApp.name if lowerAppName is keyword

      if lowerAppName.indexOf(keyword) > -1
        possibleApps.push currentApp

    if app
      KD.getSingleton("appManager").open app
      return @fatihView.destroy()

    listData = []

    for app in possibleApps
      listData.push
        title: "Open #{app.name}.kdapp"
        data : app

    return @emit "FatihPluginCreatedAList", listData if listData.length

    @fatihView.emit "PluginFoundNothing"
