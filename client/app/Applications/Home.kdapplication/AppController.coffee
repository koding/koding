class HomeAppController extends AppController

  KD.registerAppClass @,
    name         : "Home"
    route        : "/Home"
    hiddenHandle : yes
    behavior     : "hideTabs"

  constructor:(options = {}, data)->
    # options.view    = new HomeMainView

    {entryPoint} = KD.config

    Konstructor = if entryPoint and entryPoint.type is 'group' then GroupHomeView else HomeAppView

    options.view    = new Konstructor
      cssClass      : "content-page home"
      domId         : "content-page-home"
      entryPoint    : entryPoint
    options.appInfo =
      name          : "Home"

    super options,data

  loadView:(mainView)->
    # @createListControllers()
    # @bringFeeds()

  bringFeeds:->
    KD.getSingleton("appManager").tell "Topics", "fetchSomeTopics", null, (err,topics)=>
      unless err
        @mainView.widgetHolder.topicsLoader.hide()
        @topicsController.instantiateListItems topics

    KD.getSingleton("appManager").tell "Activity", "fetchFeedForHomePage", (activity)=>
      if activity
        @mainView.widgetHolder.activityLoader.hide()
        @activityController.instantiateListItems activity

    KD.getSingleton("appManager").tell "Members", "fetchFeedForHomePage", (err,topics)=>
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

  createContentDisplayWithOptions:(options, callback)->
    {model, route, query} = options

    controller = @getSingleton 'contentDisplayController'
    switch route
      when 'About'
        contentDisplay = new AboutView
        controller.emit 'ContentDisplayWantsToBeShown', contentDisplay
        callback contentDisplay