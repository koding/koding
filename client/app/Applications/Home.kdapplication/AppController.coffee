class HomeAppController extends AppController
  constructor:(options = {}, data)->
    options.view = new KDView
    # options.view = new HomeMainView
      cssClass : "content-page home"
    super options,data

  bringToFront:()->
    super name : 'Home', type : 'background'

  loadView:(mainView)->
    @mainView = mainView
    mainView.putSlideShow()
    widgetHolder = mainView.putWidgets()
    mainView.putTechnologies()
    mainView.putScreenshotDemo()
    mainView.putFooter()
    mainView._windowDidResize()
    @createListControllers()

    widgetHolder.setTemplate widgetHolder.pistachio()
    widgetHolder.template.update()
    widgetHolder.showLoaders()

    @bringFeeds()

  bringFeeds:->
    appManager.tell "Topics", "fetchSomeTopics", null, (err,topics)=>
      unless err
        @mainView.widgetHolder.topicsLoader.hide()
        @topicsController.instantiateListItems topics

    # appManager.tell "Activity", "fetchFeedForHomePage", (activity)=>
    #   if activity
    #     @mainView.widgetHolder.activityLoader.hide()
    #     @activityController.instantiateListItems activity

    appManager.tell "Members", "fetchFeedForHomePage", (err,topics)=>
      unless err
        @mainView.widgetHolder.membersLoader.hide()
        @membersController.instantiateListItems topics

  createListControllers:->
    @createTopicsList()
    @createActivity()
    @createMembersList()

  createTopicsList:->
    @topicsController = new KDListViewController
      view            : new KDListView
        itemClass  : HomeTopicItemView

    @mainView.widgetHolder.topics = @topicsController.getView()

  createActivity:->
    @activityController = new KDListViewController
      view            : new KDListView
        lastToFirst   : no
        itemClass  : HomeActivityItem

    @mainView.widgetHolder.activity = @activityController.getView()

  createMembersList:->
    @membersController = new KDListViewController
      view            : new KDListView
        itemClass  : HomeMemberItemView


    @mainView.widgetHolder.members = @membersController.getView()
