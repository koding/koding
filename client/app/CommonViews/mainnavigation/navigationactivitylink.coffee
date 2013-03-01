class NavigationActivityLink extends KDCustomHTMLView

  constructor:(options = {}, data)->
    options.tagName  = "a"
    options.cssClass = "title"

    super options, data

    @newActivityCount = 0

    @count = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon invite-friends" # TODO: Update class name
      partial   : "#{@newActivityCount}"
      click     : =>
        @setActivityLinkToDefaultState()
        appManager.tell "Activity", "unhideNewItems"

    @count.hide()

    @icon  = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon #{__utils.slugify @getData().title}"

    @utils.wait 1000, =>
      @getSingleton('activityController').on "ActivitiesArrived", (activities) =>
        return if @getSingleton('router').currentPath is "Activity"
        myId = KD.whoami().getId()
        @newActivityCount++ for activity in activities when activity.originId isnt myId

        appManager.tell "Activity", "getNewItemsCount", (itemCount) =>
          @updateNewItemsCount itemCount

    @getSingleton("mainController").on "NavigationLinkTitleClick", (options) =>
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
