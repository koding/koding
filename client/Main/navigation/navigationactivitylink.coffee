class NavigationActivityLink extends KDCustomHTMLView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.tagName  = "a"
    options.cssClass = "title"

    super options, data

    appManager = KD.getSingleton "appManager"

    @count = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon transparent"
      partial   : ""
      click     : =>
        @setActivityLinkToDefaultState()

    @count.hide()

    @icon  = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "main-nav-icon #{utils.slugify @getData().title}"

    mainController = KD.getSingleton "mainController"

    mainController.ready =>
      activityController = KD.getSingleton "activityController"
      activityController.on "ActivitiesArrived", =>
        return if KD.getSingleton("router").currentPath is "/Activity"

        newItemsCount = activityController.getNewItemsCount()
        @updateNewItemsCount newItemsCount  if newItemsCount > 0

        activityController.on "NewItemsCounterCleared", @bound "setActivityLinkToDefaultState"

    # mainController.on "NavigationLinkTitleClick", (options) =>
    #   if options.appPath is "Activity"
    #     KD.getSingleton("activityController").clearNewItemsCount()

  updateNewItemsCount: (itemCount) ->
    return if itemCount is 0
    @count.updatePartial itemCount
    @count.show()
    @icon.hide()

  setActivityLinkToDefaultState: ->
    @icon.show()
    @count.hide()

  pistachio: -> "{{> @count}} {{> @icon}} #{@getData().title}"
