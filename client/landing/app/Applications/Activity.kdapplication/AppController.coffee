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

  lastTo   = null
  lastFrom = null
  aRange   = 2*60*60*1000

  constructor:(options={})->

    options.view = new ActivityAppView

    super options

    @currentFilter = activityTypes
    @appStorage = new AppStorage 'Activity', '1.0'
    @getSingleton('activityController').on "ActivityListControllerReady", (controller)=>
      @listControllerReady controller

  bringToFront:()-> super name : 'Activity'

  resetList:->
    lastFrom = null
    lastTo   = null
    @listController.removeAllItems()

  setFilter:(type) ->
    @resetList()
    @currentFilter = if type? then [type] else activityTypes

  getFilter: -> @currentFilter

  listControllerReady:(controller)->

    @listController    = controller
    activityController = @getSingleton('activityController')

    @listController.on 'LazyLoadThresholdReached', @continueLoadingTeasers.bind @
    @listController.on 'teasersLoaded', @teasersLoaded.bind @

    activityController.on "OwnActivityHasArrived", (activity)=>
      @listController.ownActivityArrived activity

    activityController.on 'ActivitiesArrived', (activities)=>
      for activity in activities when activity.constructor.name in @currentFilter
        @listController.newActivityArrived activity

    KD.whoami().on "FollowedActivityArrived", (activityId) =>
      KD.remote.api.CActivity.one {_id: activityId}, (err, activity) =>
        if activity.constructor.name in @currentFilter
          activity.snapshot?.replace /&quot;/g, '"'
          @listController.followedActivityArrived activity

    @getView().innerNav.on "NavItemReceivedClick", (data)=>
      @setFilter data.type
      @fetchActivityOverview()

    @fetchActivityOverview()

  fetchActivityOverview:(callback)->

    @appStorage.fetchStorage (storage)=>

      flags      = KD.whoami().globalFlags
      exempt     = (flags? and 'exempt' in flags) or storage.getAt 'bucket.showLowQualityContent'
      now        = Date.now()
      lastTo     = if lastTo   then lastFrom else now
      lastFrom   = if lastFrom then lastFrom - aRange else now - aRange
      lowQuality = yes  if exempt

      options =
        lowQuality : lowQuality
        from       : lastFrom
        to         : lastTo
        types      : @getFilter()

      KD.remote.api.CActivity.fetchActivityOverview options, (err, overview)=>
        if overview.length is 0
          @fetchActivityOverview callback
        else
          callback?()
          @listController.prepareToStream overview

  streamByIds:(ids, callback)->

    selector = _id : $in : ids
    KD.remote.api.CActivity.streamModels selector, {}, (err, model) =>
      if err then callback err
      else
        unless model is null
          callback null, model[0]
        else
          callback null, null




  continueLoadingTeasers:->

    unless @listController.isLoading
      @listController.showLazyLoader()
      @fetchActivityOverview =>
        @listController.hideLazyLoader()

  teasersLoaded:->
    {scrollView} = @listController
    if scrollView.getScrollHeight() <= scrollView.getHeight()
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
      title       : "Code Share"
      type        : "codeshare"
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















  # performFetchingTeasers:(selector, options, callback) ->
  #   KD.remote.api.CActivity.streamModels selector, options, (err, model) =>
  #     if err then callback err
  #     else
  #       unless model is null
  #         log model
  #         # model[0].snapshot = model[0].snapshot.replace /&quot;/g, '"'
  #         # callback null, model

  # fetchTeasers:(selector,options,callback)->
  #   @performFetchingTeasers selector, options, (err, data) ->
  #     KD.remote.reviveFromSnapshots data, (err, instances)->
  #       callback instances

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
