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

    {appStorageController} = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '2.0'

    warn 'dock.getView().show()'

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


  sendPrivateMessage: (options = {}, callback = noop) ->

    {socialapi} = KD.singletons
    socialapi.message.sendPrivateMessage options, callback


  firstFetch = yes

  fetch: ({channelId, from, limit}, callback = noop) ->

    id = channelId
    {socialapi} = KD.singletons
    {socialApiChannelId} = KD.getGroup()
    id ?= socialApiChannelId

    if firstFetch and socialapi.getPrefetchedData('navigated').length > 0
      messages   = socialapi.getPrefetchedData 'navigated'
      KD.utils.defer ->  callback null, messages
    else
      log id, firstFetch, 'hello'
      socialapi.channel.fetchActivities {id, from, limit}, callback

    firstFetch = yes


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


  bindModalDestroy: (modal, lastRoute) ->

    {router} = KD.singletons

    modal.once 'KDModalViewDestroyed', ->
      router.back() if lastRoute is router.visitedRoutes.last

    router.once 'RouteInfoHandled', -> modal?.destroy()
