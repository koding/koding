class NavigationAppsLink extends JView

  constructor:(options = {}, data)->

    options.tagName  = "a"
    options.cssClass = "title"

    super options, data

    @counter        = 0
    @appsController = KD.getSingleton "kodingAppsController"

    @count      = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "icon-top-badge"
      partial   : ""
      click     : (e) =>
        e.preventDefault()
        e.stopPropagation()
        KD.getSingleton("router").handleRoute "/Apps?filter=updates"

    @count.hide()

    @icon       = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon #{utils.slugify @getData().title}"

    @getUpdateRequiredAppsCount()

    @appsController.on "AnAppHasBeenUpdated", =>
      return if @counter is 0
      @counter--
      return @count.hide() if @counter is 0
      @count.updatePartial @counter

    @appsController.on "AppsRefreshed", =>
      @setCounter yes

  getUpdateRequiredAppsCount: ->
    return @setCounter()  if Object.keys(@appsController.publishedApps).length
    @appsController.on "UserAppModelsFetched", => @setCounter()

  setCounter: (useTheForce = no) ->
    @appsController.fetchUpdateAvailableApps (err, availables) =>
      @counter = availables.length

      @count.updatePartial @counter
      if @counter > 0 then @count.show() else @count.hide()
    , useTheForce

  pistachio: ->
    """
      {{> @count}} {{> @icon}} #{@getData().title}
    """
