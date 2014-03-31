class ActivityAppController extends AppController

  KD.registerAppClass this,
    name         : "Activity"
    routes       :
      "/:name?/Activity/:slug?" : ({params:{name, slug}, query})->
        {router, appManager} = KD.singletons

        unless slug
        then router.openSection 'Activity', name, query
        else router.createContentDisplayHandler('Activity') arguments...

    searchRoute  : "/Activity?q=:text:"
    hiddenHandle : yes


  {dash} = Bongo

  USEDFEEDS = []

  @clearQuotes = clearQuotes = (activities)->
    return activities = for own activityId, activity of activities
      activity.snapshot = activity.snapshot?.replace /&quot;/g, '\"'
      activity

  constructor:(options={})->
    options.view    = new ActivityAppView
      testPath      : "activity-feed"
    options.appInfo =
      name          : 'Activity'

    super options

    @currentFeedFilter     = "Public"
    @currentActivityFilter = "Everything"
    @appStorage            = new AppStorage 'Activity', '1.0'
    @isLoading             = no
    @mainController        = KD.getSingleton 'mainController'
    @lastTo                = null
    @lastFrom              = Date.now()
    @lastQuery             = null

    KD.singletons.dock.getView().show()

    @status = KD.getSingleton "status"
    @status.on "reconnected", (conn)=>
      if conn?.reason is "internetDownForLongTime" then @refresh()

    @on "activitiesCouldntBeFetched", => @listController?.hideLazyLoader()

  loadView:->
    @getView().feedWrapper.ready (controller)=>
      @attachEvents @getView().feedWrapper.controller
      @emit 'ready'

  resetAll:->
    @lastTo                 = null
    @lastFrom               = Date.now()
    @isLoading              = no
    @reachedEndOfActivities = no
    @listController.resetList()
    @listController.removeAllItems()

  search:(text)->
    text = Encoder.XSSEncode text
    @searchText = text
    @setWarning {text, loading:yes, type:"search"}
    @populateActivity searchText:text

  bindLazyLoad:->
    @once 'LazyLoadThresholdReached', @bound "continueLoadingTeasers"

  continueLoadingTeasers:->
    # temp fix:
    # if teasersLoaded and LazyLoadThresholdReached fire at the same time
    # it leads to clear the callbacks so it will ask for the new activities
    # but will newver put them in activity feed.
    # so fix the teasersLoaded logic.
    return  if @isLoading
    @clearPopulateActivityBindings()

    options = {to : @lastFrom}
    options.searchText = @searchText if @searchText

    @populateActivity options
    KD.mixpanel "Scroll down feed, success"

  attachEvents:(controller)->
    activityController = KD.getSingleton('activityController')
    appView            = @getView()
    activityController.on 'Refresh', @bound "refresh"

    @listController = controller
    @bindLazyLoad()

    appView.activityHeader.feedFilterNav.on "FilterChanged", (filter) =>

      @resetAll()
      @clearPopulateActivityBindings()

      if filter in ["Public", "Followed"]
      then @setFeedFilter filter
      else @setActivityFilter filter

      @populateActivity()

  setFeedFilter: (feedType) -> @currentFeedFilter = feedType
  getFeedFilter: -> @currentFeedFilter

  setActivityFilter: (activityType)-> @currentActivityFilter = activityType
  getActivityFilter: -> @currentActivityFilter

  clearPopulateActivityBindings:->
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    @off "followingFeedFetched_#{eventSuffix}"
    @off "publicFeedFetched_#{eventSuffix}"
    # log "------------------ bindingsCleared", dateFormat(@lastFrom, "mmmm dS HH:mm:ss"), @_e

  handleQuery:(query = {})->
    if query.tagged
      return  if @lastQuery and query.tagged is @lastQuery.tagged
      tag = KD.utils.slugify KD.utils.stripTags query.tagged
      @setWarning {text:tag, loading:yes}
      options = filterByTag: tag
    else if query.q
      return  if @lastQuery and query.q is @lastQuery.q
      search = KD.utils.stripTags query.q
      @setWarning {text: search, loading:yes, type:"search"}
      options = searchText: search
    else
      return  if @lastQuery and Object.keys(query).length is 0 and Object.keys(@lastQuery).length is 0

    @lastQuery = query

    # TODO: populateActivity will fire twice if there is a query (FIXME) C.T.
    @ready => @populateActivity options

  populateActivity:(options = {}, callback=noop)->

    return  if @isLoading
    return  if @reachedEndOfActivities

    view = @getView()

    @listController.showLazyLoader no
    view.unsetTopicTag()

    @isLoading         = yes
    {groupsController} = KD.singletons
    {
      filterByTag
      to
      searchText
    } = options

    setFeedData = (messages) =>

      @isLoading = no
      @bindLazyLoad()
      @extractMessageTimeStamps messages
      @listController.listActivities messages
      callback messages

    fetch = =>

      groupObj     = groupsController.getCurrentGroup()
      mydate       = new Date((new Date()).setSeconds(0) + 60000).getTime()
      options      =
        to         : options.to or mydate #Date.now() we cant cache if we change ts everytime.
        group      :
          slug     : groupObj?.slug or "koding"
          id       : groupObj.getId()
        limit      : KD.config.activityFetchCount
        facets     : @getActivityFilter()
        withExempt : no
        slug       : filterByTag
        searchText : searchText

      options.withExempt = \
        KD.getSingleton("activityController").flags.showExempt?

      eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"

      {roles} = KD.config
      group   = groupObj?.slug

      {togglePinnedList, pinnedListController} = view.feedWrapper
      pinnedListView = pinnedListController.getListView()

      togglePinnedList.hide()
      pinnedListView.hide()

      if not to and (searchText or @searchText)
        @resetAll()
        @clearPopulateActivityBindings()
        @searchText = searchText

      if searchText? or (@searchText and to)
        options.searchText ?= @searchText
        @once "searchFeedFetched_#{eventSuffix}", setFeedData
        @searchActivities options
        @setWarning {text:searchText, loading:no, type:"search"}
        return

      if not to and (filterByTag or @_wasFilterByTag)
        @resetAll()
        @clearPopulateActivityBindings()
        @_wasFilterByTag = filterByTag

      if filterByTag? or (@_wasFilterByTag and to)
        options.slug ?= @_wasFilterByTag
        @once "topicFeedFetched_#{eventSuffix}", setFeedData
        @fetchTopicActivities options
        @setWarning {text:options.slug}
        view.setTopicTag options.slug
        return

      else if @getFeedFilter() is "Public"
        @once "publicFeedFetched_#{eventSuffix}", setFeedData
        @fetchPublicActivities options
        @setWarning()
        if pinnedListController.getItemCount()
          togglePinnedList.show()
          pinnedListView.show()
        return

      else
        @once "followingFeedFetched_#{eventSuffix}", setFeedData
        @fetchFollowingActivities options
        @setWarning()

      # log "------------------ populateActivity", dateFormat(@lastFrom, "mmmm dS HH:mm:ss"), @_e

    groupsController.ready fetch

  searchActivities:(options = {})->
    options.to = @lastTo
    {JNewStatusUpdate} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    JNewStatusUpdate.search options, (err, activities) =>
      if err then @emit "activitiesCouldntBeFetched", err
      else @emit "searchFeedFetched_#{eventSuffix}", activities


  fetchTopicActivities:(options = {})->
    options.to = @lastTo
    {JNewStatusUpdate} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    JNewStatusUpdate.fetchTopicFeed options, (err, activities) =>
      if err then @emit "activitiesCouldntBeFetched", err
      else @emit "topicFeedFetched_#{eventSuffix}", activities


  fetchPublicActivities:(options = {})->
    options.to = @lastTo
    options.feedType = "$ne" : "bug"
    {JNewStatusUpdate} = KD.remote.api
    # todo - implement prefetched feed
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"

    # get from cache if only it is "Public" or "Everything"
    if @getFeedFilter() is "Public" \
        and @getActivityFilter() is "Everything" \
        and KD.prefetchedFeeds \
        # if current user is exempt, fetch from db, not from cache
        and not KD.whoami().isExempt
      group  = KD.getSingleton("groupsController").getCurrentGroup()
      feedId = "#{group.slug}-activity.main"
      prefetchedActivity = KD.prefetchedFeeds[feedId]

      # TODO : REMOVING FOR GROUPS DEV. BECAUSE PREFETCH NOT WORKING FOR GROUPS

      if prefetchedActivity and (feedId not in USEDFEEDS)
        log "exhausting feed:", feedId
        USEDFEEDS.push feedId
        # update this function
        messages = @prepareCacheForListing prefetchedActivity
        @emit "publicFeedFetched_#{eventSuffix}", messages
        return

    # just here to make it work
    # we should change the other parts to make it
    # work with the new structure
    {Social}  = KD.remote.api
    Social.fetchGroupActivity options, (err, result)=>
      messages = result.messageList
      revivedMessages = []
      for message in messages
        m = new Social message.message
        m._id = message.message.id
        m.meta = {}
        m.meta.likes = message.interactions.length or 0
        m.meta.createdAt = message.message.createdAt
        m.replies = message.replies
        m.repliesCount = message.replies.length or 0
        m.interactions = message.interactions

        m.on "MessageReplySaved", log
        m.on "data", log
        m.on "update", log
        # m.on "MessageReplySaved", log

        revivedMessages.push m

      return @emit "activitiesCouldntBeFetched", err  if err
      @emit "publicFeedFetched_#{eventSuffix}", revivedMessages

  # this is only reviving the cache for now
  prepareCacheForListing: (cache)-> return KD.remote.revive cache

  fetchFollowingActivities:(options = {})->
    {JNewStatusUpdate} = KD.remote.api
    options.to  = @followingLastTo or Date.now()
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    JNewStatusUpdate.fetchFollowingFeed options, (err, activities) =>
      if err
      then @emit "activitiesCouldntBeFetched", err
      else
        if Array.isArray activities
          activities       = activities.reverse()
          @followingLastTo = activities.last.meta.createdAt if activities.length > 0
        @emit "followingFeedFetched_#{eventSuffix}", activities

  setWarning:(options = {})->
    options.type or= "tag"
    {text, loading, type} = options
    {filterWarning} = @getView()
    if text
      unless loading
        filterWarning.showWarning {text, type}
      else
        filterWarning.warning.setPartial "Filtering activities by #{text}..."
        filterWarning.show()
    else
      filterWarning.hide()

  setLastTimestamps:(from, to)->
    if from
      @lastTo   = to
      @lastFrom = from
    else
      @reachedEndOfActivities = yes

  # Store first & last cache activity timestamp.
  extractMessageTimeStamps: (messages)->
    return  if messages.length is 0
    from = new Date(messages.last.meta.createdAt).getTime()
    to   = new Date(messages.first.meta.createdAt).getTime()
    @setLastTimestamps to, from #from, to

  createContentDisplay:(activity, callback=->)->
    contentDisplay = @createStatusUpdateContentDisplay activity
    @utils.defer -> callback contentDisplay

  showContentDisplay:(contentDisplay)->

    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay

  createStatusUpdateContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayStatusUpdate
      title : "Status Update"
      type  : "status"
    ,activity

  fetchActivitiesProfilePage:(options,callback)->
    {originId} = options
    options.to = options.to or @profileLastTo or Date.now()
    if KD.checkFlag 'super-admin'
      appStorage = new AppStorage 'Activity', '1.0'
      appStorage.fetchStorage (storage)=>
        options.withExempt = appStorage.getValue('showLowQualityContent') or off
        @fetchActivitiesProfilePageWithExemptOption options, callback
    else
      options.withExempt = false
      @fetchActivitiesProfilePageWithExemptOption options, callback

  fetchActivitiesProfilePageWithExemptOption:(options, callback)->
    {JNewStatusUpdate} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    JNewStatusUpdate.fetchProfileFeed options, (err, activities)=>
      return @emit "activitiesCouldntBeFetched", err  if err

      if activities?.length > 0
        lastOne = activities.last.meta.createdAt
        @profileLastTo = (new Date(lastOne)).getTime()
      callback err, activities


  getNewItemsCount: (callback) ->
    callback? @listController?.activityHeader?.getNewItemsCount() or 0

  # Refreshes activity feed, used when user has been disconnected
  # for so long, backend connection is long gone.
  refresh:->
    # prevents multiple clicks to refresh from interfering
    return  if @isLoading

    @resetAll()
    @clearPopulateActivityBindings()
    @populateActivityWithTimeout()

  populateActivityWithTimeout:->
    @populateActivity {},\
      KD.utils.getTimedOutCallbackOne
        name      : "populateActivity",
        onTimeout : @bound 'recover'
        timeout   : 20000

  recover:->
    @isLoading = no

    @status.disconnect()
    @refresh()

  resetProfileLastTo : ->
    @profileLastTo = null
