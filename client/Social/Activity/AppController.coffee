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

  constructor: (options = {}) ->

    options.view    = new ActivityAppView testPath : "activity-feed"
    options.appInfo = name : 'Activity'

    super options

    {dock, appStorageController} = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '2.0'

    dock.getView().show()


  fetchPublicActivities: (options = {}, callback = ->) ->

    # just here to make it work
    # we should change the other parts to make it
    # work with the new structure
    {SocialChannel, SocialMessage}  = KD.remote.api
    options.id = KD.singletons.groupsController.getCurrentGroup().socialApiChannelId
    SocialChannel.fetchActivity options, (err, result)=>
      console.log err  if err
      messages = result.messageList
      revivedMessages = []

      for message in messages
        m = new SocialMessage message.message
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
      callback err, revivedMessages




  #
  # LEGACY
  #

  createContentDisplay:(activity, callback = ->)->

    contentDisplay = new ContentDisplayStatusUpdate
      title : "Status Update"
      type  : "status"
    ,activity

    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay
    @utils.defer -> callback contentDisplay


  fetchActivitiesProfilePage:(options, callback)->

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
