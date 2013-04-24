class ActivityAppController extends AppController

  activityTypes = [
      'CStatusActivity'
      'CCodeSnipActivity'
      'CFollowerBucketActivity'
      'CNewMemberBucketActivity'
      'CDiscussionActivity'
      'CTutorialActivity'
      'CInstallerBucketActivity'
      # DISABLING NOT READY ITEM TYPES
      # 'COpinionActivity'
      # 'CLinkActivity'
      # 'CCodeShareActivity'
    ]

  @clearQuotes = clearQuotes = (activities)->

    return activities = for activityId, activity of activities
      activity.snapshot = activity.snapshot?.replace /&quot;/g, '"'
      activity

  isExempt = (callback)->

    appManager.fetchStorage 'Activity', '1.0', (err, storage) =>
      if err
        log 'error fetching app storage', err
        callback no
      else
        flags = KD.whoami().globalFlags
        exempt = flags?.indexOf 'exempt'
        exempt = (exempt? and ~exempt) or storage.getAt 'bucket.showLowQualityContent'
        callback exempt

  constructor:(options={})->

    options.view = new ActivityAppView

    super options

    @isLoading         = no
    @currentFilter     = activityTypes
    @appStorage        = new AppStorage 'Activity', '1.0'
    activityController = @getSingleton('activityController')
    activityController.on "ActivityListControllerReady", @attachEvents.bind @

    status = @getSingleton "status"
    status.on "reconnected", (reason)=>
      if reason is "internetDownForLongTime"
        @resetAll()
        @populateActivity()
      else
        @fetchSomeActivities()

  bringToFront:()->

    super name : 'Activity'

    if @listController then @populateActivity()
    else
      ac = @getSingleton('activityController')
      ac.once "ActivityListControllerReady", @populateActivity.bind @

  resetAll:->

    delete @lastTo
    delete @lastFrom

    @listController.resetList()
    @listController.removeAllItems()

  setFilter:(type) -> @currentFilter = if type? then [type] else activityTypes

  getFilter: -> @currentFilter

  ownActivityArrived:(activity)-> @listController.ownActivityArrived activity

  attachEvents:(controller)->

    @listController    = controller
    activityController = @getSingleton('activityController')

    controller.on 'LazyLoadThresholdReached', @continueLoadingTeasers.bind @
    controller.on 'teasersLoaded', @teasersLoaded.bind @

    @getView().widgetController.on "FakeActivityHasArrived", (activity)->
      controller.fakeActivityArrived activity

    @getView().widgetController.on "OwnActivityHasArrived", @ownActivityArrived.bind @

    activityController.on 'ActivitiesArrived', @bound "activitiesArrived"

    KD.whoami().on "FollowedActivityArrived", (activityId) =>
      KD.remote.api.CActivity.one {_id: activityId}, (err, activity) =>
        if activity.constructor.name in @getFilter()
          activities = clearQuotes [activity]
          controller.followedActivityArrived activities.first

    @getView().innerNav.on "NavItemReceivedClick", (data)=>
      @resetAll()
      @setFilter data.type
      @populateActivity()

    @listController.on "scrolledToTopOfPage", =>
      return if @isLoading

      log "scrolled_up fetching activities"
      @fetchSomeActivities()

  activitiesArrived:(activities)->
    for activity in activities when activity.bongo_.constructorName in @getFilter()
      @listController.newActivityArrived activity

  # Store first & last activity timestamp.
  extractTeasersTimeStamps:(teasers)->

    teasers  = _.compact(teasers)
    @lastTo   = teasers.first.meta.createdAt
    @lastFrom = teasers.last.meta.createdAt

  # Store first & last cache activity timestamp.
  extractCacheTimeStamps: (cache)->

    @lastTo   = cache.to
    @lastFrom = cache.from

  populateActivity:(options = {})->

    return if @isLoading
    @isLoading = yes
    @listController.showLazyLoader()
    @listController.noActivityItem.hide()

    isExempt (exempt)=>

      if exempt or @getFilter() isnt activityTypes

        options = to : options.to or Date.now()

        @fetchActivity options, (err, teasers)=>
          @isLoading = no
          @listController.hideLazyLoader()
          if err or teasers.length is 0
            warn err
            @listController.noActivityItem.show()
          else
            @extractTeasersTimeStamps(teasers)
            @listController.listActivities teasers

      else
        @fetchCachedActivity options, (err, cache)=>
          @isLoading = no
          if err or cache.length is 0
            warn err
            @listController.hideLazyLoader()
            @listController.noActivityItem.show()
          else
            @extractCacheTimeStamps(cache)

            @sanitizeCache cache, (err, cache)=>
              @listController.hideLazyLoader()
              @listController.listActivitiesFromCache cache

  sanitizeCache:(cache, callback)->

    activities = clearQuotes cache.activities

    KD.remote.reviveFromSnapshots activities, (err, instances)->

      for activity,i in activities
        cache.activities[activity._id] or= {}
        cache.activities[activity._id].teaser = instances[i]

      callback null, cache

  fetchActivity:(options = {}, callback)->

    options       =
      limit       : options.limit  or 20
      to          : options.to     or Date.now()
      facets      : options.facets or @getFilter()
      lowQuality  : options.exempt or no
      sort        :
        createdAt : -1

    KD.remote.api.CActivity.fetchFacets options, (err, activities)->
      if err then callback err
      else
        KD.remote.reviveFromSnapshots clearQuotes(activities), callback

  # Fetches activities that occur when user is disconnected.
  fetchSomeActivities:(options = {}) ->

    return if @isLoading
    @isLoading = yes

    lastItemCreatedAt = @listController.getLastItemTimeStamp()
    unless lastItemCreatedAt? or lastItemCreatedAt is ""
      @isLoading = no
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
          # FIXME: SY
          # if it is exact 20 there may be other items
          # put a separator and check for new items in between
          if activities.length is 20
            warn "put a separator in between new and old activities"

          @activitiesArrived activities.reverse()
          @isLoading = no
      , ->
        @isLoading = no
        log "fetchSomeActivities timeout reached"

  fetchCachedActivity:(options = {}, callback)->

    $.ajax
      url     : "/-/cache/#{options.slug or 'latest'}"
      cache   : no
      error   : (err)->   callback? err
      success : (cache)->
        cache.overview.reverse()  if cache?.overview
        callback null, cache

  continueLoadingTeasers:->

    lastTimeStamp = (new Date @lastFrom).getTime()
    @populateActivity {slug : "before/#{lastTimeStamp}", to: lastTimeStamp}

  teasersLoaded:->

    unless @listController.scrollView.hasScrollBars()
      @continueLoadingTeasers()

  createContentDisplay:(activity)->
    switch activity.bongo_.constructorName
      when "JStatusUpdate" then @createStatusUpdateContentDisplay activity
      when "JCodeSnip"     then @createCodeSnippetContentDisplay activity
      when "JDiscussion"   then @createDiscussionContentDisplay activity
      when "JTutorial"     then @createTutorialContentDisplay activity
      # THIS WILL DISABLE CODE SHARES/LINKS/DISCUSSIONS
      # when "JCodeShare"    then @createCodeShareContentDisplay activity

  showContentDisplay:(contentDisplay)->
    contentDisplayController = @getSingleton "contentDisplayController"
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay

  createStatusUpdateContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayStatusUpdate
      title : "Status Update"
      type  : "status"
    ,activity

  createCodeSnippetContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayCodeSnippet
      title : "Code Snippet"
      type  : "codesnip"
    ,activity

  createCodeShareContentDisplay:(activity)->
    @showContentDisplay new ContentDisplayCodeShare
      title : "Code Share"
      type  : "codeshare"
    , activity

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

  fetchTeasers:(selector,options,callback)->

    KD.remote.api.CActivity.some selector, options, (err, data) =>
      if err then callback err
      else
        data = clearQuotes data
        KD.remote.reviveFromSnapshots data, (err, instances)->
          if err then callback err
          else
            callback instances

