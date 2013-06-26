class ActivityAppController extends AppController

  KD.registerAppClass this,
    name         : "Activity"
    route        : "/:name?/Activity"
    hiddenHandle : yes
    navItem      :
      title      : "Activity"
      path       : "/Activity"
      order      : 10

  {dash} = Bongo

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
    return activities = for activityId, activity of activities
      activity.snapshot = activity.snapshot?.replace /&quot;/g, '\"'
      activity

  constructor:(options={})->
    options.view    = new ActivityAppView
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

    #@status = KD.getSingleton "status"
    #@status.on "reconnected", (conn)=>
      #if conn && conn.reason is "internetDownForLongTime"
      #then @refresh()
      #else @fetchSomeActivities()

  loadView:->
    @getView().feedWrapper.ready (controller)=>
      @attachEvents @getView().feedWrapper.controller
      @ready @bound "populateActivity"

    @emit 'ready'
    console.clear()

  resetAll:->
    @lastTo    = null
    @lastFrom  = Date.now()
    @isLoading = no
    @listController.resetList()
    @listController.removeAllItems()

  ownActivityArrived:(activity)-> @listController.ownActivityArrived activity

  fetchCurrentGroup:(callback)-> callback @currentGroupSlug

  bindLazyLoad:->
    @listController.once 'LazyLoadThresholdReached', @continueLoadingTeasers.bind @
    @listController.once 'teasersLoaded', @teasersLoaded.bind @

  continueLoadingTeasers:->
    @clearPopulateActivityBindings()
    @populateActivity to : @lastFrom

  attachEvents:(controller)->
    activityController = KD.getSingleton('activityController')
    appView            = @getView()
    {widgetController} = appView
    activityController.on 'ActivitiesArrived', @bound "activitiesArrived"
    activityController.on 'Refresh', @bound "refresh"

    @listController = controller
    @bindLazyLoad()

    widgetController.on "FakeActivityHasArrived", (activity)->
      controller.fakeActivityArrived activity

    widgetController.on "OwnActivityHasArrived", @ownActivityArrived.bind @

    appView.innerNav.on "NavItemReceivedClick", (data)=>
      KD.track "Activity", data.type + "FilterClicked"

      @clearPopulateActivityBindings()
      @resetAll()

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
    @off "activitiesFetched_#{eventSuffix}"
    @off "cacheFetched_#{eventSuffix}"
    # log ">>>>>>>>>>>>>>>>>    clearPopulateActivityBindings", @_e


  populateActivity:(options = {})->

    return  if @isLoading

    @listController.showLazyLoader no
    @listController.hideNoItemWidget()

    @isLoading       = yes
    groupsController = KD.getSingleton 'groupsController'
    {isReady}        = groupsController
    currentGroup     = groupsController.getCurrentGroup()

    reset = =>
      @isLoading = no
      @bindLazyLoad()

    fetch = do =>=>
      #since it is not working, disabled it,
      #to-do add isExempt control.
      #@isExempt (exempt)=>
        #if exempt or @getFilter() isnt activityTypes

      options =
        to     : options.to or Date.now()
        group  :
          slug : currentGroup.slug or "koding"
          id   : currentGroup.getId()
        limit  : 20
        facets : @getActivityFilter()

      eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"

      if @getFeedFilter() is "Public"
        @once "publicFeedFetched_#{eventSuffix}", (cache)=>
          reset()
          @extractCacheTimeStamps cache
          @listController.listActivitiesFromCache cache
        @fetchPublicActivities options
      else
        @once "followingFeedFetched_#{eventSuffix}", (activities)=>
          reset()
          @extractTeasersTimeStamps activities
          @listController.listActivities activities
        @fetchFollowingActivities options

      # log "------------------    populateActivity", @getActivityFilter(), @lastFrom

    if isReady
    then fetch()
    else groupsController.once 'groupChanged', fetch

  fetchPublicActivities:(options = {})->
    {CStatusActivity} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    CStatusActivity.fetchPublicActivityFeed options, (err, cache)=>
      cache.overview.reverse()  if cache.overview

      return @emit "activitiesCouldntBeFetched", err  if err

      @sanitizeCache cache, (err, sanitizedCache)=>
        if err
        then @emit "activitiesCouldntBeFetched", err
        else @emit "publicFeedFetched_#{eventSuffix}", sanitizedCache


  fetchFollowingActivities:(options = {})->
    {CActivity} = KD.remote.api
    eventSuffix = "#{@getFeedFilter()}_#{@getActivityFilter()}"
    CActivity.fetchFolloweeContents options, (err, activities) =>
      if err
      then @emit "activitiesCouldntBeFetched", err
      else @emit "followingFeedFetched_#{eventSuffix}", activities

  # Store first & last cache activity timestamp.
  extractCacheTimeStamps: (cache)->
    @lastTo   = (new Date cache.to).getTime()
    @lastFrom = (new Date cache.from).getTime()

  # Store first & last activity timestamp.
  extractTeasersTimeStamps:(teasers)->
    return unless teasers.first
    @lastTo   = new Date(teasers.first.meta.createdAt).getTime()
    @lastFrom = new Date(teasers.last.meta.createdAt).getTime()

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
    contentPanel     = KD.getSingleton('contentPanel')
    scrollViewHeight = @listController.scrollView.$()[0].clientHeight
    headerHeight     = contentPanel.$('.feeder-header')[0].offsetHeight
    panelHeight      = contentPanel.$('.activity-content')[0].clientHeight

    if scrollViewHeight + headerHeight < panelHeight
      @continueLoadingTeasers()

  createContentDisplay:(activity, callback=->)->
    controller = switch activity.bongo_.constructorName
      when "JStatusUpdate" then @createStatusUpdateContentDisplay activity
      when "JCodeSnip"     then @createCodeSnippetContentDisplay activity
      when "JDiscussion"   then @createDiscussionContentDisplay activity
      when "JBlogPost"     then @createBlogPostContentDisplay activity
      when "JTutorial"     then @createTutorialContentDisplay activity
    @utils.defer -> callback controller

  showContentDisplay:(contentDisplay)->
    contentDisplayController = KD.getSingleton "contentDisplayController"
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplayController

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

  fetchTeasers:(options,callback)->
    KD.remote.api.CActivity.fetchFacets options, (err, data) =>
      if err then callback err
      else
        data = clearQuotes data
        KD.remote.reviveFromSnapshots data, (err, instances)->
          if err then callback err
          else callback null, instances

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

  #populateActivityWithTimeout:->
    #@populateActivity {},\
      #KD.utils.getTimedOutCallbackOne
        #name      : "populateActivity",
        #onSuccess : -> KD.logToMixpanel "refresh activity feed success"
        #onTimeout : @recover.bind this

  #recover:->

    #KD.logToMixpanel "activity feed render failed; recovering"

    #@isLoading = no
    #@status.reconnect()

  ## Fetches activities that occured after the first entry in user feed,
  ## used for minor disruptions.
  #fetchSomeActivities:(options = {}) ->
    #return if @isLoading
    #@isLoading = yes

    #lastItemCreatedAt = @listController.getLastItemTimeStamp()
    #unless lastItemCreatedAt? or lastItemCreatedAt is ""
      #@isLoading = no
      #log "lastItemCreatedAt is empty"
      ## if lastItemCreatedAt is null, we assume there are no entries
      ## and refresh the entire feed
      #@refresh()
      #return

    #selector       =
      #createdAt    :
        #$gt        : options.createdAt or lastItemCreatedAt
      #type         : { $in : options.facets or @getFilter() }
      #isLowQuality : { $ne : options.exempt or no }

    #options       =
      #limit       : 20
      #sort        :
        #createdAt : -1

    #KD.remote.api.CActivity.some selector, options,\
      #KD.utils.getTimedOutCallback (err, activities) =>
        #if err then warn err
        #else

          #KD.logToMixpanel "refresh activity feed success"

          ## FIXME: SY
          ## if it is exact 20 there may be other items
          ## put a separator and check for new items in between
          #if activities.length is 20
            #warn "put a separator in between new and old activities"

          #@activitiesArrived activities.reverse()
          #@isLoading = no
      #, =>
        #@isLoading = no
        #log "fetchSomeActivities timeout reached"

  #isExempt:(callback)->

    #@appStorage.fetchStorage (storage) =>
      #flags  = KD.whoami().globalFlags
      #exempt = flags?.indexOf 'exempt'
      #exempt = (exempt? and exempt > -1) or storage.getAt 'bucket.showLowQualityContent'
      #callback exempt