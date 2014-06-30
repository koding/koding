class ActivityAppController extends AppController


  KD.registerAppClass this,
    name         : 'Activity'
    searchRoute  : '/Activity?q=:text:'
    commands:
      'next tab'     : 'goToNextTab'
      'previous tab' : 'goToPreviousTab'
    keyBindings: [
      { command: 'next tab',      binding: 'meta+alt+]',    global: yes }
      { command: 'next tab',      binding: 'meta+alt+down', global: yes }
      { command: 'previous tab',  binding: 'meta+alt+up',   global: yes }
      { command: 'previous tab',  binding: 'meta+alt+[',    global: yes }
    ]

  constructor: (options = {}) ->

    options.view    = new ActivityAppView testPath : 'activity-feed'
    options.appInfo = name : 'Activity'

    super options

    {dock, appStorageController} = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '2.0'

    dock.getView().show()

    @on 'LazyLoadThresholdReached', @getView().bound 'lazyLoadThresholdReached'


  post: (options = {}, callback = noop) ->

    (KD.singleton 'socialapi').message.post options, callback


  edit: (options = {}, callback = noop) ->

    (KD.singleton 'socialapi').message.edit options, callback


  reply: ({activity, body}, callback = noop) ->

    messageId = activity.id

    {socialapi} = KD.singletons
    socialapi.message.reply {body, messageId}, callback


  delete: ({id}, callback) ->

    {socialapi} = KD.singletons
    socialapi.message.delete {id}, callback


  listReplies: ({activity, from, limit}, callback = noop) ->

    messageId = activity.id

    {socialapi} = KD.singletons
    socialapi.message.listReplies {messageId, from, limit}, callback


  fetch: ({channelId, from}, callback = noop) ->

    id = channelId
    {socialapi} = KD.singletons
    {socialApiChannelId} = KD.getGroup()

    if socialApiChannelId is channelId and socialapi.getPrefetchedData('publicFeed').length > 0
      messages = socialapi.getPrefetchedData 'publicFeed'
      KD.utils.defer ->  callback null, messages
      KD.socialApiData.publicFeed = null
    else
      socialapi.channel.fetchActivities {id, from}, callback


  getActiveChannel: -> @getView().sidebar.selectedItem.getData()


  goToNextTab: (event) ->

    KD.utils.stopDOMEvent event
    @getView().openNext()


  goToPreviousTab: (event) ->

    KD.utils.stopDOMEvent event
    @getView().openPrev()


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


  bindModalDestroy: (modal, lastRoute) ->

    {router} = KD.singletons

    modal.once 'KDModalViewDestroyed', ->
      router.back() if lastRoute is router.visitedRoutes.last

    router.once 'RouteInfoHandled', -> modal?.destroy()
