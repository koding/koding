class NavigationAppsLink extends KDCustomHTMLView

  constructor:(options = {}, data)->
    options.tagName  = "a"
    options.cssClass = "title"

    super options, data

    @isFetchedAgain = no
    @counter        = 0

    @count = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "icon-top-badge"
      partial   : ""

    @count.hide()

    @icon  = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon #{__utils.slugify @getData().title}"

    @getUpdateRequiredAppsCount()

  getUpdateRequiredAppsCount: ->
    appsController = @getSingleton "kodingAppsController"
    appsController.fetchApps (err, apps) =>
      {publishedApps} = appsController
      # just a fallback for any race condition, however not think so required
      if not publishedApps and not isFetchedAgain
        return @utils.wait 1500, =>
          @getUpdateRequiredAppsCount()
          @isFetchedAgain = yes

      for name, jApp of publishedApps when apps[name]
        @counter++ if appsController.isAppUpdateAvailable name, apps[name].version

      if @counter > 0
        @count.updatePartial @counter
        @count.show()

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    """
      {{> @count}} {{> @icon}} #{@getData().title}
    """
