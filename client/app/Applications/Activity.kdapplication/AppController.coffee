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

  lastTo    = null
  lastFrom  = null
  aRange    = 2*60*60*1000
  isLoading = no

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

    @currentFilter     = activityTypes
    @appStorage        = new AppStorage 'Activity', '1.0'
    activityController = @getSingleton('activityController')
    activityController.on "ActivityListControllerReady", @attachEvents.bind @

  bringToFront:()->

    super name : 'Activity'

    if @listController then @populateActivity()
    else
      ac = @getSingleton('activityController')
      ac.once "ActivityListControllerReady", @populateActivity.bind @

  resetList:->

    lastFrom = null
    lastTo   = null
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

    activityController.on 'ActivitiesArrived', (activities)=>
      for activity in activities when activity.bongo_.constructorName in @getFilter()
        controller.newActivityArrived activity

    KD.whoami().on "FollowedActivityArrived", (activityId) =>
      KD.remote.api.CActivity.one {_id: activityId}, (err, activity) =>
        if activity.constructor.name in @getFilter()
          activity.snapshot?.replace /&quot;/g, '"'
          controller.followedActivityArrived activity

    @getView().innerNav.on "NavItemReceivedClick", (data)=>
      @resetList()
      @setFilter data.type
      @populateActivity()

  populateActivity:(options = {})->

    return if isLoading
    isLoading = yes
    @listController.showLazyLoader()
    @listController.noActivityItem.hide()

    isExempt (exempt)=>

      if exempt or @getFilter() isnt activityTypes

        options = to : options.to or Date.now()

        @fetchActivity options, (err, teasers)=>
          isLoading = no
          @listController.hideLazyLoader()
          if err or teasers.length is 0
            warn err
            @listController.noActivityItem.show()
          else
            @listController.listActivities teasers

      else
        @fetchCachedActivity options, (err, cache)=>
          isLoading = no
          if err or cache.length is 0
            warn err
            @listController.hideLazyLoader()
            @listController.noActivityItem.show()
          else
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

    KD.remote.api.CActivity.fetchFacets options, (err, activities)=>
      if err then callback err
      else
        KD.remote.reviveFromSnapshots clearQuotes(activities), callback


  fetchCachedActivity:(options = {}, callback)->

    $.ajax
      url     : "/-/cache/#{options.slug or 'latest'}"
      cache   : no
      error   : (err)->   callback? err
      success : (cache)->
        cache.overview.reverse()  if cache?.overview
        callback null, cache

  continueLoadingTeasers:->

    unless isLoading
      if @listController.itemsOrdered.last
        lastItemData = @listController.itemsOrdered.last.getData()
        # memberbucket data has no serverside model it comes from cache
        # so it has no meta, that's why we check its date by its overview
        lastDate = if lastItemData.createdAt
          lastItemData.createdAt.first
        else
          lastItemData.meta.createdAt
      else
        lastDate = Date.now()

      @populateActivity {slug : "before/#{(new Date(lastDate)).getTime()}"}

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

  # streamByIds:(ids, callback)->

  #   selector = _id : $in : ids
  #   KD.remote.api.CActivity.streamModels selector, {}, (err, model) =>
  #     if err then callback err
  #     else
  #       unless model is null
  #         callback null, model[0]
  #       else
  #         callback null, null




  # performFetchingTeasers:(selector, options, callback) ->
  #   KD.remote.api.CActivity.streamModels selector, options, (err, model) =>
  #     if err then callback err
  #     else
  #       unless model is null
  #         log model
  #         # model[0].snapshot = model[0].snapshot.replace /&quot;/g, '"'
  #         # callback null, model


  # loadSomeTeasers:(range, callback)->
  #   [callback, range] = [range, callback] unless callback
  #   range or= {}
  #   {from, to, limit} = range

  #   controller = @listController

  #   selector      =
  #     type        :
  #       $in       : @currentFilter

  #   options       =
  #     limit       : limit or= 20
  #     sort        :
  #       createdAt : -1

  #   if not options.skip < options.limit
  #     @fetchTeasers selector, options, (activities)=>
  #       if activities
  #         for activity in activities when activity?
  #           controller.addItem activity
  #         callback? activities
  #       else
  #         callback?()
  #       @teasersLoaded()














  # remove this shit, do it with kitecontroller :) - 8 October 2012 sinan
  # saveCodeSnippet:(title, content)->
  #   # This custom method is used because FS,
  #   # command, environment are all a mess and
  #   # devrim is currently working on refactoring them - 3/15/12 sah

  #   # i kind of cleared that mess, still needs work - 26 April 2012 sinan
  #   if KD.isLoggedIn()
  #     @getSingleton('fs').saveToDefaultCodeSnippetFolder '"' + title + '"', content, (error, safeName)->
  #       if error
  #         new KDNotificationView
  #           title    : "Saving the snippet failed with error: #{error}"
  #           duration : 2500
  #           type     : 'mini'
  #       else
  #         nonEscapedName = safeName.replace /"(.*)"$/, '$1'
  #         new KDNotificationView
  #           title    : "Code snippet saved to: #{nonEscapedName}"
  #           duration : 2500
  #           type     : 'mini'
  #   else
  #     new KDNotificationView
  #       title    : "Please login!"
  #       type     : 'mini'
  #       duration : 2500


















    # @activityTabView = new KDTabView
    #   cssClass            : "maincontent-tabs feeder-tabs"
    #   hideHandleContainer : yes




  # createFollowedAndPublicTabs:->
  #   # FIRST TAB = FOLLOWED ACTIVITIES, SORT AND POST NEW
  #   @activityTabView.addPane followedTab = new KDTabPaneView
  #     cssClass : "activity-content"

  #   # SECOND TAB = ALL ACTIVITIES, SORT AND POST NEW
  #   @activityTabView.addPane allTab = new KDTabPaneView
  #     cssClass : "activity-content"

  #   @listController = listController = new ActivityListController
  #     delegate          : @
  #     lazyLoadThreshold : .75
  #     itemClass         : ActivityListItemView

  #   allTab.addSubView activityListScrollView = listController.getView()

  #   {activitySplit} = @getView()
  #   activitySplit.on "ViewResized", ->
  #     newHeight = activitySplit.getHeight() - 28 # HEIGHT OF THE HEADER
  #     listController.scrollView.setHeight newHeight

  #   controller = @

  #   listController.on 'LazyLoadThresholdReached', @continueLoadingTeasers.bind @

  # loadSomeTeasersIn:(sourceIds, options, callback)->
  #   KD.remote.api.Relationship.within sourceIds, options, (err, rels)->
  #     KD.remote.cacheable rels.map((rel)->
  #       constructorName : rel.targetName
  #       id              : rel.targetId
  #     ), callback
