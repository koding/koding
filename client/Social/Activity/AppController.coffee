class ActivityAppController extends AppController

  KD.registerAppClass this,
    name         : "Activity"
    route        : "/:name?/Activity"
    hiddenHandle : yes
    navItem      :
      title      : "Activity"
      path       : "/Activity"
      order      : 21


  {dash} = Bongo

  USEDFEEDS = []

  activityTypes = [
    'Everything'
  ]

  newActivitiesArrivedTypes = [
    'CStatusActivity'
    'CCodeSnipActivity'
    'CFollowerBucketActivity'
    'CNewMemberBucketActivity'
    'CDiscussionActivity'
    'CTutorialActivity'
    'CInstallerBucketActivity'
    'CBlogPostActivity'
  ]

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

    # if @mainController.appIsReady then @putListeners()
    # else @mainController.on 'AppIsReady', => @putListeners()

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

  ownActivityArrived:(activity)-> @listController.ownActivityArrived activity

  fetchCurrentGroup:(callback)-> callback @currentGroupSlug

  bindLazyLoad:->
    @once 'LazyLoadThresholdReached', @bound "continueLoadingTeasers"
    @listController.once 'teasersLoaded', @bound "teasersLoaded"

  continueLoadingTeasers:->
    # temp fix:
    # if teasersLoaded and LazyLoadThresholdReached fire at the same time
    # it leads to clear the callbacks so it will ask for the new activities
    # but will newver put them in activity feed.
    # so fix the teasersLoaded logic.
    return  if @isLoading
    @clearPopulateActivityBindings()

    KD.mixpanel "Scrolled down feed"
    @populateActivity to : @lastFrom

  attachEvents:(controller)->
    activityController = KD.getSingleton('activityController')
    appView            = @getView()
    activityController.on 'ActivitiesArrived', @bound "activitiesArrived"
    activityController.on 'Refresh', @bound "refresh"

    @listController = controller
    @bindLazyLoad()

    @getView().on "InputSubmitted", @bound "ownActivityArrived"

    appView.innerNav.on "NavItemReceivedClick", (data)=>
      KD.track "Activity", data.type + "FilterClicked"
      @resetAll()
      @clearPopulateActivityBindings()

      if data.type in ["Public", "Followed"]
      then @setFeedFilter data.type
      else @setActivityFilter data.type

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
      tag = KD.utils.slugify KD.utils.stripTags query.tagged
      @setWarning tag, yes
      options = filterByTag: tag

    @ready => @populateActivity options

  populateActivity:(options = {}, callback=noop)->

    return  if @isLoading
    return  if @reachedEndOfActivities

    @listController.showLazyLoader no

    @isLoading       = yes
    groupsController = KD.getSingleton 'groupsController'
    {isReady}        = groupsController
    currentGroup     = groupsController.getCurrentGroup()
    {filterByTag,to} = options

    setFeedData = (messages) =>

      @isLoading = no
      @bindLazyLoad()
      @extractMessageTimeStamps messages
      @listController.listActivities messages
      callback messages

    fetch = =>

      #since it is not working, disabled it,
      #to-do add isExempt control.
      #@isExempt (exempt)=>
      #if exempt or @getFilter() isnt activityTypes

      groupObj     = KD.getSingleton("groupsController").getCurrentGroup()
      mydate       = new Date((new Date()).setSeconds(0) + 60000).getTime()
      options      =
        to         : options.to or mydate #Date.now() we cant cache if we change ts everytime.
        group      :
          slug     : groupObj?.slug or "koding"
          id       : groupObj.getId()
        limit      : 20
        facets     : @getActivityFilter()
        withExempt : no
        slug       : filterByTag

      options.withExempt = \
        KD.getSingleton("activityController").flags.showExempt?

      eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"

      {roles} = KD.config
      group   = groupObj?.slug

      if not to and (filterByTag or @_wasFilterByTag)
        @resetAll()
        @clearPopulateActivityBindings()
        @_wasFilterByTag = filterByTag

      if filterByTag? or (@_wasFilterByTag and to)

        options.slug ?= @_wasFilterByTag
        @once "topicFeedFetched_#{eventSuffix}", setFeedData
        @fetchTopicActivities options
        @setWarning options.slug

      else if @getFeedFilter() is "Public"

        @once "publicFeedFetched_#{eventSuffix}", setFeedData
        @fetchPublicActivities options
        @setWarning()

      else

        @once "followingFeedFetched_#{eventSuffix}", setFeedData
        @fetchFollowingActivities options
        @setWarning()

      # log "------------------ populateActivity", dateFormat(@lastFrom, "mmmm dS HH:mm:ss"), @_e

    if isReady then fetch()
    else groupsController.once 'GroupChanged', fetch

  fetchTopicActivities:(options = {})->
    {JStatusUpdate} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    JStatusUpdate.fetchTopicFeed options, (err, activities) =>
      if err then @emit "activitiesCouldntBeFetched", err
      else @emit "topicFeedFetched_#{eventSuffix}", activities

  fetchPublicActivities:(options = {})->
    options.to = @lastTo
    {JStatusUpdate} = KD.remote.api
    # todo - implement prefetched feed
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    JStatusUpdate.fetchGroupActivity options, (err, messages)=>
      return @emit "activitiesCouldntBeFetched", err  if err
      @emit "publicFeedFetched_#{eventSuffix}", messages

  fetchFollowingActivities:(options = {})->
    {JStatusUpdate} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    CActivity.fetchFollowingFeed options, (err, activities) =>
      if err
      then @emit "activitiesCouldntBeFetched", err
      else @emit "followingFeedFetched_#{eventSuffix}", activities

  setWarning:(tag, loading = no)->
    {filterWarning} = @getView()
    if tag
      unless loading
        filterWarning.showWarning tag
      else
        filterWarning.warning.setPartial "Filtering activities by #{tag}..."
        filterWarning.show()
    else
      filterWarning.hide()

  setLastTimestamps:(from, to)->
    # debugger

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

  # Store first & last activity timestamp.
  extractTeasersTimeStamps:(teasers)->
    return unless teasers.first
    @setLastTimestamps new Date(teasers.last.meta.createdAt).getTime(), new Date(teasers.first.meta.createdAt).getTime()

  sanitizeCache:(cache, callback)->
    activities = clearQuotes cache.activities

    KD.remote.reviveFromSnapshots activities, (err, instances)->
      for activity,i in activities
        cache.activities[activity._id] or= {}
        cache.activities[activity._id].teaser = instances[i]

      callback null, cache

  activitiesArrived:(activities)->
    for activity in activities when activity.bongo_.constructorName in newActivitiesArrivedTypes
      @listController?.newActivityArrived activity

  teasersLoaded:->
    # the page structure has changed
    # we don't need this anymore
    # we need a different approach tho, tBDL - SY

    # due to complex nesting of subviews, i used jQuery here. - AK

    # contentPanel     = KD.getSingleton('contentPanel')
    # scrollViewHeight = @listController.scrollView.$()[0].clientHeight
    # headerHeight     = contentPanel.$('.feeder-header')[0].offsetHeight
    # panelHeight      = contentPanel.$('.activity-content')[0].clientHeight

    # if scrollViewHeight + headerHeight < panelHeight
    #   @continueLoadingTeasers()

  createContentDisplay:(activity, callback=->)->
    controller = switch activity.bongo_.constructorName
      when "JStatusUpdate" then @createStatusUpdateContentDisplay activity
      when "JCodeSnip"     then @createCodeSnippetContentDisplay activity
      when "JDiscussion"   then @createDiscussionContentDisplay activity
      when "JBlogPost"     then @createBlogPostContentDisplay activity
      when "JTutorial"     then @createTutorialContentDisplay activity
    @utils.defer -> callback controller

  showContentDisplay:(contentDisplay)->

    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay

  createStatusUpdateContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayStatusUpdate
      title : "Status Update"
      type  : "status"
    ,activity

  createBlogPostContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayBlogPost
      title : "Blog Post"
      type  : "blogpost"
    ,activity

  createCodeSnippetContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayCodeSnippet
      title : "Code Snippet"
      type  : "codesnip"
    ,activity

  createDiscussionContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayDiscussion
      title : "Discussion"
      type  : "discussion"
    ,activity

  createTutorialContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayTutorial
      title : "Tutorial"
      type  : "tutorial"
    ,activity

  streamByIds:(ids, callback)->

    selector = _id : $in : ids
    KD.remote.api.CActivity.streamModels selector, {}, (err, model) =>
      if err then callback err
      else
        unless model is null
          callback null, model[0]
        else
          callback null, null

  lastTo : null

  fetchActivitiesProfilePage:(options,callback)->
    options.to = options.to or @lastTo or Date.now()
    if KD.checkFlag 'super-admin'
      appStorage = new AppStorage 'Activity', '1.0'
      appStorage.fetchStorage (storage)=>
        options.withExempt = appStorage.getValue('showLowQualityContent') or off
        @fetchActivitiesProfilePageWithExemptOption options, callback
    else
      options.withExempt = false
      @fetchActivitiesProfilePageWithExemptOption options, callback

  fetchActivitiesProfilePageWithExemptOption:(options, callback)->
    {CStatusActivity} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    CStatusActivity.fetchUsersActivityFeed options, (err, activities)=>
      return @emit "activitiesCouldntBeFetched", err  if err

      if activities?.length > 0
        lastOne = activities.last.meta.createdAt
        @lastTo = (new Date(lastOne)).getTime()
      callback err, activities

  unhideNewItems: ->
    @listController?.activityHeader.updateShowNewItemsLink yes

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

  feederBridge : (options, callback)->

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', options, callback
