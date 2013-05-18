class ActivityAppController extends AppController

  KD.registerAppClass @,
    name         : "Activity"
    route        : "/Activity"
    hiddenHandle : yes

  activityTypes = [
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
      activity.snapshot = activity.snapshot?.replace /&quot;/g, '"'
      activity

  constructor:(options={})->

    options.view    = new ActivityAppView
    options.appInfo =
      name          : 'Activity'

    super options

    @currentFilter     = activityTypes
    @filterType = "Public"
    @appStorage        = new AppStorage 'Activity', '1.0'
    @isLoading         = no
    @mainController    = @getSingleton 'mainController'
    @lastTo            = null
    @lastFrom          = null

    # if @mainController.appIsReady then @putListeners()
    # else @mainController.on 'FrameworkIsReady', => @putListeners()

    @status = @getSingleton "status"
    @status.on "reconnected", (conn)=>
      if conn && conn.reason is "internetDownForLongTime"
      then @refresh()
      else @fetchSomeActivities()

  loadView:->
    # Do we really need this? ~ GG
    # yes - SY
    @getView().feedWrapper.ready (controller)=>
      @attachEvents @getView().feedWrapper.controller
      @ready @bound "populateActivity"

    @emit 'ready'

  resetAll:->
    @lastTo   = null
    @lastFrom = null
    @listController.resetList()
    @listController.removeAllItems()

  setFilter:(type) ->
    if type?
      @currentFilter = type
    else
      @currentFilter = activityTypes

  getFilter: -> @currentFilter

  ownActivityArrived:(activity)-> @listController.ownActivityArrived activity

  fetchCurrentGroup:(callback)-> callback @currentGroupSlug

  attachEvents:(controller)->

    @listController    = controller
    activityController = @getSingleton('activityController')

    controller.on 'LazyLoadThresholdReached', @continueLoadingTeasers.bind @
    controller.on 'teasersLoaded', @teasersLoaded.bind @

    @getView().widgetController.on "FakeActivityHasArrived", (activity)->
      controller.fakeActivityArrived activity

    @getView().widgetController.on "OwnActivityHasArrived", @ownActivityArrived.bind @

    activityController.on 'ActivitiesArrived', @bound "activitiesArrived"
    activityController.on 'Refresh', @bound "refresh"

    KD.whoami().on "FollowedActivityArrived", (activityId) =>
      KD.remote.api.CActivity.one {_id: activityId}, (err, activity) =>
        if activity.constructor.name in @getFilter()
          activities = clearQuotes [activity]
          controller.followedActivityArrived activities.first

    @getView().innerNav.on "NavItemReceivedClick", (data)=>

      console.log("data??????", data)
      # the filterList on top of the innerNav is clicked
      if data.filterType
        @filterType = data.filterType
        @resetAll()
        @populateActivity()
      else
        @resetAll()
        @setFilter data.type
        @populateActivity()

  activitiesArrived:(activities)->
    for activity in activities when activity.bongo_.constructorName in @getFilter()
      @listController?.newActivityArrived activity

  isExempt:(callback)->

    @appStorage.fetchStorage (storage) =>
      flags  = KD.whoami().globalFlags
      exempt = flags?.indexOf 'exempt'
      exempt = (exempt? and exempt > -1) or storage.getAt 'bucket.showLowQualityContent'
      callback exempt

  fetchActivitiesDirectly:(options = {}, callback)->
    console.log("starting to fetch activities ... !!!" + JSON.stringify(options) )
    KD.time "Activity fetch took - "
    options = to : options.to or Date.now()

    console.log("fetching activity now ", @filterType)
    @fetchActivity options, (err, teasers)=>
      console.log("got it now ?")
      @isLoading = no
      @listController.hideLazyLoader()
      KD.timeEnd "Activity fetch took"

      if err or teasers.length is 0
        warn "An error occured:", err  if err
        @listController.showNoItemWidget()
      else
        @extractTeasersTimeStamps(teasers)
        @listController.listActivities teasers

      callback? err, teasers

  fetchActivitiesFromCache:(options = {})->
    @fetchCachedActivity options, (err, cache)=>
      @isLoading = no
      if err or cache.length is 0
        warn err  if err
        @listController.hideLazyLoader()
        @listController.showNoItemWidget()
      else
        @extractCacheTimeStamps cache
        @sanitizeCache cache, (err, cache)=>
          @listController.hideLazyLoader()
          @listController.listActivitiesFromCache cache

  # Store first & last activity timestamp.
  extractTeasersTimeStamps:(teasers)->
    @lastTo   = teasers.first.meta.createdAt
    @lastFrom = teasers.last.meta.createdAt

  # Store first & last cache activity timestamp.
  extractCacheTimeStamps: (cache)->
    @lastTo   = cache.to
    @lastFrom = cache.from

  # Refreshes activity feed, used when user has been disconnected
  # for so long, backend connection is long gone.
  refresh:->
    # prevents multiple clicks to refresh from interfering
    return  if @isLoading

    @resetAll()
    @populateActivityWithTimeout()

  populateActivityWithTimeout:->
    console.log("populateActivityWithTimeout 1")
    @populateActivity {},\
      KD.utils.getTimedOutCallbackOne
        name      : "populateActivity",
        onSuccess : -> KD.logToMixpanel "refresh activity feed success"
        onTimeout : @recover.bind this

  recover:->

    KD.logToMixpanel "activity feed render failed; recovering"

    @isLoading = no
    @status.reconnect()

  populateActivity:(options = {}, callback)->
    console.log("populating activities - 1")
    return if @isLoading

    @listController.showLazyLoader()
    @listController.hideNoItemWidget()

    @isLoading       = yes
    groupsController = @getSingleton 'groupsController'
    {isReady}        = groupsController
    currentGroup     = groupsController.getCurrentGroup()

    fetch = (slug)=>
      console.log("activities ---- !!!! fetch - slug:" + slug)

      if KD.config.useNeo4j
        @fetchActivitiesDirectly options, callback
      else:
        unless slug is 'koding'
          @fetchActivitiesDirectly options, callback
        else
          @isExempt (exempt)=>
            console.log("activities, calling this or that exempt " + exempt)
            if exempt or @getFilter() isnt activityTypes
              console.log("fetching activities directly")
              @fetchActivitiesDirectly options, callback
            else
              console.log("fetching activities from cache")
              @fetchActivitiesFromCache options, callback

    unless isReady
    then groupsController.once 'groupChanged', fetch
    else fetch currentGroup.slug


  sanitizeCache:(cache, callback)->

    activities = clearQuotes cache.activities

    KD.remote.reviveFromSnapshots activities, (err, instances)->

      for activity,i in activities
        cache.activities[activity._id] or= {}
        cache.activities[activity._id].teaser = instances[i]

      callback null, cache

  fetchActivity:(options = {}, callback)->

    options       =
      limit       : options.limit    or 20
      to          : options.to       or Date.now()
      facets      : options.facets   or @getFilter()
      originId    : options.originId or null
      sort        :
        createdAt : -1

    if KD.config.useNeo4j
      options['filterType'] = @filterType
      console.log("KD.remote.api.CActivity.fetchFolloweeContents - " + JSON.stringify(options) )
      if @filterType == "Public"
        KD.remote.api.CActivity.fetchPublicContents options, (err, activities)->
          if err
            console.log("err" + err)
            callback err
          else
            callback null, activities
      else
        KD.remote.api.CActivity.fetchFolloweeContents options, (err, activities)->
          if err
            console.log("err" + err)
            callback err
          else
            callback null, activities
    else

      @isExempt (exempt)->
        options.lowQuality = exempt
        console.log("fetching -- ", JSON.stringify(options))
        KD.remote.api.CActivity.fetchFacets options, (err, activities)->
          if err
            console.log("err", err)
            callback err
          else if not exempt
            console.log("11111 = ?????", activities.length)
            KD.remote.reviveFromSnapshots clearQuotes(activities), callback
          else
            console.log("22222 = ?????")
            # trolls and admins in show troll mode will load data on request
            # as the snapshots do not include troll comments
            stack = []
            activities.forEach (activity)->
              stack.push (cb)->
                activity.fetchTeaser (err, teaser)->
                  if err then console.warn 'could not fetch teaser'
                  else
                    cb err, teaser
                , yes

            async.parallel stack, (err, res)->
              callback null, res

  # Fetches activities that occured after the first entry in user feed,
  # used for minor disruptions.
  fetchSomeActivities:(options = {}) ->
    console.log("fetching some activities")
    return if @isLoading
    @isLoading = yes

    lastItemCreatedAt = @listController.getLastItemTimeStamp()
    unless lastItemCreatedAt? or lastItemCreatedAt is ""
      @isLoading = no
      log "lastItemCreatedAt is empty"

      # if lastItemCreatedAt is null, we assume there are no entries
      # and refresh the entire feed
      @refresh()

      return

    selector       =
      createdAt    :
        $gt        : options.createdAt or lastItemCreatedAt
      type         : { $in : options.facets or @getFilter() }
      isLowQuality : { $ne : options.exempt or no }

    options       =
      limit       : 20
      sort        :
        createdAt : -1

    KD.remote.api.CActivity.some selector, options,\
      KD.utils.getTimedOutCallback (err, activities) =>
        if err then warn err
        else

          KD.logToMixpanel "refresh activity feed success"

          # FIXME: SY
          # if it is exact 20 there may be other items
          # put a separator and check for new items in between
          if activities.length is 20
            warn "put a separator in between new and old activities"

          @activitiesArrived activities.reverse()
          @isLoading = no
      , =>
        @isLoading = no
        log "fetchSomeActivities timeout reached"

  fetchCachedActivity:(options = {}, callback)->

    urlPrefix = "cache"

    if KD.config.useNeo4j
      urlPrefix = "neo4j"

    $.ajax
      url     : "/-/#{urlPrefix}/#{options.slug or 'latest'}"
      cache   : no
      error   : (err)->   callback? err
      success : (cache)=>
        cache.overview.reverse()  if cache?.overview
        callback null, cache

  continueLoadingTeasers:->
    # ?????
    # HACK: this gets called multiple times if there's no wait
    KD.utils.wait 10000, =>
      lastTimeStamp = (new Date @lastFrom or Date.now()).getTime()
      @populateActivity {slug : "before/#{lastTimeStamp}", to: lastTimeStamp}

  teasersLoaded:->
    # the page structure has changed
    # we don't need this anymore
    # we need a different approach tho, tBDL - SY

    # due to complex nesting of subviews, i used jQuery here. - AK
    contentPanel     = @getSingleton('contentPanel')
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
    contentDisplayController = @getSingleton "contentDisplayController"
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
          else
            callback instances

  unhideNewItems: ->
    @listController?.activityHeader.updateShowNewItemsLink yes

  getNewItemsCount: (callback) ->
    callback? @listController?.activityHeader?.getNewItemsCount() or 0
