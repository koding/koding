kd                       = require 'kd'
ActivityAppView          = require './activityappview'
ActivityFlux             = require 'activity/flux'
remote                   = require('app/remote').getInstance()
globals                  = require 'globals'
getGroup                 = require 'app/util/getGroup'
checkFlag                = require 'app/util/checkFlag'
isFeedEnabled            = require 'app/util/isFeedEnabled'
AppStorage               = require 'app/appstorage'
AppController            = require 'app/appcontroller'
KodingAppsController     = require 'app/kodingappscontroller'
keyboardKeys             = require 'app/constants/keyboardKeys'
NotificationSettingsFlux = require 'activity/flux/channelnotificationsettings'

require('./routehandler')()

module.exports = class ActivityAppController extends AppController

  @options = require './options'

  {noop} = kd

  FIRST_FETCH = yes

  constructor: (options = {}) ->

    options.view    = new ActivityAppView testPath : 'activity-feed'
    options.appInfo = name : 'Activity'

    super options

    {appStorageController, appManager} = kd.singletons

    if isFeedEnabled()
      appManager.on 'FrontAppIsChanged', (currentApp, oldApp) =>
        if currentApp isnt oldApp and oldApp is this
          {thread, message} = ActivityFlux.actions
          thread.changeSelectedThread null
          message.changeSelectedMessage null

    @appStorage = appStorageController.storage 'Activity', '2.0'

    helper.loadFonts()
    helper.loadEmojiStyles()

    NotificationSettingsFlux.actions.channel.loadGlobal()
    ActivityFlux.actions.channel.loadPopularChannels()


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

    unless e.which is keyboardKeys.ESC
      kd.utils.stopDOMEvent e

    if isFeedEnabled()
      switch e.model.name
        when 'prevwindow' then @getView().openPrev()
        when 'nextwindow' then @getView().openNext()
    else
      { actions, getters } = ActivityFlux

      switch e.model.name
        when 'prevwindow'       then actions.thread.openPrev()
        when 'nextwindow'       then actions.thread.openNext()
        when 'prevunreadwindow' then actions.thread.openUnreadPrev()
        when 'nextunreadwindow' then actions.thread.openUnreadNext()
        when 'glance'
          channelId = kd.singletons.reactor.evaluate getters.selectedChannelThreadId
          actions.channel.glance channelId


helper =

  loadFonts: ->

    global.WebFontConfig =
      google: { families: [ 'Source+Sans+Pro:400,600:latin', 'Oxygen:400,700:latin' ] }

    options =
      identifier : 'source-sans-pro'
      url        : '//ajax.googleapis.com/ajax/libs/webfont/1/webfont.js'

    KodingAppsController.appendHeadElement 'script', options


  loadEmojiStyles: ->

    options =
      identifier : 'emojis'
      url        : '/a/static/emojify/emojify.css?v=1'

    KodingAppsController.appendHeadElement 'style', options
