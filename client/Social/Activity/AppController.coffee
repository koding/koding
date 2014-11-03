class ActivityAppController extends AppController


  KD.registerAppClass this,
    name         : 'Activity'
    searchRoute  : '/Activity?q=:text:'
    commands     :
      'next tab'     : 'goToNextTab'
      'previous tab' : 'goToPreviousTab'
    keyBindings: [
      { command: 'next tab',      binding: 'alt+]',    global: yes }
      { command: 'next tab',      binding: 'alt+down', global: yes }
      { command: 'previous tab',  binding: 'alt+up',   global: yes }
      { command: 'previous tab',  binding: 'alt+[',    global: yes }
    ]

  firstFetch = yes

  constructor: (options = {}) ->

    options.view    = new ActivityAppView testPath : 'activity-feed'
    options.appInfo = name : 'Activity'

    super options

    {appStorageController} = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '2.0'


  post: (options = {}, callback = noop) ->

    {socialapi} = KD.singletons

    socialapi.message.post options, callback


  edit: (options = {}, callback = noop) ->

    {id, body} = options
    {socialapi} = KD.singletons

    socialapi.message.edit {id, body}, callback


  reply: (options = {}, callback = noop) ->

    {activity, body, clientRequestId} = options

    messageId = activity.id

    {socialapi} = KD.singletons
    socialapi.message.reply {body, messageId, clientRequestId}, callback


  delete: ({id}, callback) ->

    {socialapi} = KD.singletons
    socialapi.message.delete {id}, callback


  listReplies: ({activity, from, limit}, callback = noop) ->

    messageId = activity.id

    {socialapi} = KD.singletons
    socialapi.message.listReplies {messageId, from, limit}, callback


  sendPrivateMessage: (options = {}, callback = noop) ->

    {socialapi} = KD.singletons
    socialapi.message.sendPrivateMessage options, callback



  fetch: ({channelId, from, limit, skip, mostLiked}, callback = noop) ->

    prefetchedKey = if mostLiked then "popularPosts" else "navigated"
    id = channelId
    {socialapi, router} = KD.singletons
    {socialApiChannelId} = KD.getGroup()
    id ?= socialApiChannelId
    prefetchedItems = socialapi.getPrefetchedData prefetchedKey

    isCorrectPath = ->
      {section, name, slug} = KD.socialApiData.navigated
      routeToLookUp  = "#{name}/#{section}"
      routeToLookUp += "/#{slug}"  if slug and slug isnt '/'

      return router.getCurrentPath().search(routeToLookUp) > 0

    if firstFetch and prefetchedItems.length > 0 and isCorrectPath()
      messages = socialapi.getPrefetchedData prefetchedKey
      KD.utils.defer ->  callback null, messages
    else
      if mostLiked then @fetchMostLikedPosts({skip, limit}, callback)
      else socialapi.channel.fetchActivities {id, from, limit}, callback

    firstFetch = no

  fetchMostLikedPosts : (options, callback)->
    options.group       = KD.getGroup().slug
    options.channelName = "public"

    {socialapi} = KD.singletons
    socialapi.channel.fetchPopularPosts options, callback

  bindModalDestroy: (modal, lastRoute) ->

     {router} = KD.singletons

     modal.once 'KDModalViewDestroyed', ->
       router.back() if lastRoute is router.visitedRoutes.last

     router.once 'RouteInfoHandled', -> modal?.destroy()


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
      title : 'Status Update'
      type  : 'status'
    , activity

    KD.singleton('display').emit 'ContentDisplayWantsToBeShown', contentDisplay
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
        lastOne = activities.last.createdAt
        @profileLastTo = (new Date(lastOne)).getTime()
      callback err, activities
