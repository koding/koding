class ActivityAppController extends AppController

  KD.registerAppClass this,
    name         : 'Activity'
    searchRoute  : '/Activity?q=:text:'

  constructor: (options = {}) ->

    options.view    = new ActivityAppView testPath : 'activity-feed'
    options.appInfo = name : 'Activity'

    super options

    {dock, appStorageController} = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '2.0'

    dock.getView().show()


  post: (options = {}, callback = noop) ->

    {body}      = options
    {socialapi} = KD.singletons

    socialapi.message.post {body}, callback


  edit: (options = {}, callback = noop) ->

    {id, body} = options
    {socialapi} = KD.singletons

    socialapi.message.edit {id, body}, callback


  reply: ({activity, body}, callback = noop) ->

    messageId = activity.id

    {socialapi} = KD.singletons
    socialapi.message.reply {body, messageId}, callback

  fetch: (options = {}, callback = noop) ->

    {channelId} = options
    {socialapi} = KD.singletons

    socialapi.channel.fetchActivities { id: channelId }, callback


  #
  # LEGACY
  #

  createContentDisplay:(activity, callback = ->)->

    contentDisplay = new ContentDisplayStatusUpdate
      title : "Status Update"
      type  : "status"
    , activity

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
