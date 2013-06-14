class NavigationActivityLink extends KDCustomHTMLView

  constructor:(options = {}, data)->
    options.tagName  = "a"
    options.cssClass = "title"

    super options, data

    appManager = KD.getSingleton "appManager"

    @newActivityCount = 0

    @count = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon transparent"
      partial   : "#{@newActivityCount}"
      click     : =>
        @setActivityLinkToDefaultState()
        appManager.tell "Activity", "unhideNewItems"

    @count.hide()

    @icon  = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon #{__utils.slugify @getData().title}"

    @utils.wait 1000, =>
      KD.getSingleton('activityController').on "ActivitiesArrived", (activities) =>
        return if KD.getSingleton('router').currentPath is "Activity"
        myId = KD.whoami().getId()
        @newActivityCount++ for activity in activities when activity.originId and activity.originId isnt myId

        appManager.tell "Activity", "getNewItemsCount", (itemCount) =>
          @updateNewItemsCount itemCount

    KD.getSingleton("mainController").on "NavigationLinkTitleClick", (options) =>
      @setActivityLinkToDefaultState() if options.appPath is "Activity" and @newActivityCount > 0

  updateNewItemsCount: (itemCount) ->
    newItemsCount = itemCount or= @newActivityCount
    return if newItemsCount is 0
    @count.show()
    @icon.hide()
    @count.updatePartial newItemsCount

  setActivityLinkToDefaultState: ->
    @icon.show()
    @count.hide()
    @newActivityCount = 0

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  pistachio: ->
    """
      {{> @count}} {{> @icon}} #{@getData().title}
    """
