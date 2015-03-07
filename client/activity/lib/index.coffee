kd = require 'kd'
ActivityAppView = require './activityappview'
ContentDisplayStatusUpdate = require './contentdisplays/contentdisplaystatusupdate'
remote = require('app/remote').getInstance()
globals = require 'globals'
getGroup = require 'app/util/getGroup'
checkFlag = require 'app/util/checkFlag'
AppStorage = require 'app/appstorage'
AppController = require 'app/appcontroller'
require('./routehandler')()

module.exports = class ActivityAppController extends AppController

  @options = require './options'

  {noop} = kd

  FIRST_FETCH = yes

  constructor: (options = {}) ->

    options.view    = new ActivityAppView testPath : 'activity-feed'
    options.appInfo = name : 'Activity'

    super options

    {appStorageController} = kd.singletons

    @appStorage = appStorageController.storage 'Activity', '2.0'


  post: (options = {}, callback = noop) ->

    {socialapi} = kd.singletons

    socialapi.message.post options, callback


  edit: (options = {}, callback = noop) ->

    {id, body, payload} = options
    {socialapi} = kd.singletons

    socialapi.message.edit {id, body, payload}, callback


  reply: (options = {}, callback = noop) ->

    {activity, body, clientRequestId, payload} = options

    messageId = activity.id

    {socialapi} = kd.singletons
    socialapi.message.reply {body, messageId, clientRequestId, payload}, callback


  delete: ({id}, callback) ->

    {socialapi} = kd.singletons
    socialapi.message.delete {id}, callback


  listReplies: ({activity, from, limit}, callback = noop) ->

    messageId = activity.id

    {socialapi} = kd.singletons
    socialapi.message.listReplies {messageId, from, limit}, callback


  sendPrivateMessage: (options = {}, callback = noop) ->

    {socialapi} = kd.singletons
    socialapi.message.sendPrivateMessage options, callback


  isCorrectPath = (key)->
    return true  unless key is "navigated"

    {router} = kd.singletons
    {section, name, slug} = globals.socialApiData.navigated
    routeToLookUp  = "#{name}/#{section}"
    routeToLookUp += "/#{slug}"  if slug and slug isnt '/'

    return router.getCurrentPath().search(routeToLookUp) > 0


  fetch: (options, callback = noop) ->
    {channelId, from, limit, skip, mostLiked} = options

    prefetchedKey = if mostLiked then "popularPosts" else "navigated"
    id = channelId
    {socialapi} = kd.singletons
    {socialApiChannelId} = getGroup()
    id ?= socialApiChannelId
    prefetchedItems = socialapi.getPrefetchedData prefetchedKey

    if FIRST_FETCH and prefetchedItems.length > 0 and isCorrectPath(prefetchedKey)
      messages = socialapi.getPrefetchedData prefetchedKey
      kd.utils.defer ->  callback null, messages
    else
      if mostLiked then @fetchMostLikedPosts({skip, limit}, callback)
      else socialapi.channel.fetchActivities {id, from, limit}, callback

    FIRST_FETCH = no


  fetchMostLikedPosts : (options, callback)->
    options.group       = getGroup().slug
    options.channelName = "public"

    {socialapi} = kd.singletons
    socialapi.channel.fetchPopularPosts options, callback


  bindModalDestroy: (modal, lastRoute) ->

     {router} = kd.singletons

     modal.once 'KDModalViewDestroyed', ->
       router.back() if lastRoute is router.visitedRoutes.last

     router.once 'RouteInfoHandled', -> modal?.destroy()


  getActiveChannel: -> @getView().sidebar.selectedItem.getData()


  handleShortcut: (e) ->

    kd.utils.stopDOMEvent e

    switch e.model.name
      when 'prevwindow' then @getView().openPrev()
      when 'nextwindow' then @getView().openNext()
