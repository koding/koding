class HomeAppController extends ActivityAppController

  KD.registerAppClass this,
    name         : "Home"
    route        : "/Home"          # slug removed intentionally
    hiddenHandle : yes
    behavior     : "hideTabs"
    navItem      :
      title      : "Home"
      path       : "/Home"

  constructor:(options = {}, data)->

    {entryPoint} = KD.config
    Konstructor  = if entryPoint and entryPoint.type is 'group'
    then GroupHomeView
    else HomeAppView

    options.view    = new Konstructor
      cssClass      : "content-page home extra-wide"
      domId         : "content-page-home"
      entryPoint    : entryPoint
    options.appInfo =
      name          : "Home"

    AppController::constructor.call this, options, data

  loadView:(appView)->
    appView.ready =>
      appView.featuredActivities.ready =>
        @listController = appView.featuredActivities.controller
        @populateActivity()

  populateActivity:(options = {}, callback=noop)->
    @listController.showLazyLoader no
    @listFeaturedActivities callback

  listActivities:(activities, callback)->
    @sanitizeCache activities, (err, sanitizedCache)=>
      @extractCacheTimeStamps sanitizedCache
      @listController.listActivitiesFromCache sanitizedCache, 0 , {type : "slideDown", duration : 100}, yes
      callback sanitizedCache

  listFeaturedActivities:(callback)->
    @on "FeaturedActivityCommentRequested", @bound "featuredActivityCommentRequested"
    @on "FeaturedActivityRequested", @bound "featuredActivityRequested"

    eventName = "activity_fetch"
    @once "#{eventName}_failed", ()->
      console.log "ERR : static main page activities will not work"

    @once "#{eventName}_succeeded", (activities)=>
      activities.overview.reverse()  if activities.overview
      @listActivities activities, callback
      @emit "FeaturedActivityRequested", {activityId:1}, callback
    @fetchFeaturedActivities()

  fetchFeaturedActivities:(activityId=0, commentId=0, likeId=0)->
    activityName = "activity"
    activityName += "_#{activityId}" unless activityId is 0
    activityName += "_C#{commentId}" unless commentId is 0
    activityName += "_L#{commentId}" unless likeId is 0

    $.ajax
      url     : "js/activity/#{activityName}.json"
      success : (json) => @emit "#{activityName}_fetch_succeeded", json
      failure : =>  @emit "#{activityName}_fetch_failed"

  featuredActivityCommentRequested:({activityId, commentId}, callback)=>
    return if commentId > 2
    timeoutValue = KD.utils.getRandomNumber 100000, 70000
    KD.utils.wait timeoutValue, =>
      eventName = "activity_#{activityId}_C#{commentId}_fetch"
      @off "#{eventName}_succeeded"

      # if fetching comments fails, then shut down the event
      @once "#{eventName}_failed", ()=>
        @off "activity_#{activityId}_fetch_succeeded"

      # if fetching success, add them to activity feed
      @once eventName, (activities)=>
        @listActivities activities, callback, true
        @emit "FeaturedActivityCommentRequested", {activityId:activityId, commentId:commentId+1}, callback
      @fetchFeaturedActivities(activityId, commentId)

  featuredActivityRequested:({activityId}, callback)=>
    unless activityId? then activityId = 0
    return if activityId > 7

    @isLoading = true
    timeoutValue = KD.utils.getRandomNumber 10000, 8000

    eventName = "activity_#{activityId}_fetch"
    @off "#{eventName}_succeeded"

    KD.utils.wait timeoutValue, =>
      @once "#{eventName}_failed", ()=>
        @off "#{eventName}_succeeded"
        @emit "FeaturedActivityRequested", {activityId:activityId+1}, callback

      @once "#{eventName}_succeeded", (activities)=>
        @listActivities activities, (sanitizedCache)=>
          callback sanitizedCache
          @emit "FeaturedActivityCommentRequested", {activityId:activityId, commentId:1}, callback

        @emit "FeaturedActivityRequested", {activityId:activityId+1}, callback
      #fetch featured activity
      @fetchFeaturedActivities(activityId)

