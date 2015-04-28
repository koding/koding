_ = require 'lodash'
htmlencode = require 'htmlencode'
globals = require 'globals'
getGroup = require './util/getGroup'
doXhrRequest = require './util/doXhrRequest'
remote = require('./remote').getInstance()
checkFlag = require './util/checkFlag'
whoami = require './util/whoami'
kd = require 'kd'
KDController = kd.Controller
MessageEventManager = require './messageeventmanager'


module.exports = class SocialApiController extends KDController

  constructor: (options = {}, data) ->

    @openedChannels = {}
    @_cache         = {}
    @_inScreenMap   = {}

    super options, data


  getPrefetchedData: (dataPath) ->

    return [] unless globals.socialApiData

    data = if dataPath is 'navigated'
    then globals.socialApiData[dataPath]?.data?.messageList
    else globals.socialApiData[dataPath]

    return [] unless data

    fn = switch dataPath
      when 'followedChannels' then mapChannels
      when 'popularPosts', 'pinnedMessages', 'navigated' then mapActivities
      when 'privateMessages'                   then mapPrivateMessages

    return fn(data) or []


  eachCached: (id, fn) ->
    fn section[id]  for own name, section of @_cache when id of section


  isAnnouncementItem: (channelId) ->
    return no  unless channelId

    # super admins can see/post anyting
    return no  if checkFlag "super-admin"

    {socialApiAnnouncementChannelId} = getGroup()

    return channelId is socialApiAnnouncementChannelId


  onChannelReady: (channel, callback) ->
    channelName = generateChannelName channel
    if channel = @openedChannels[channelName]?.channel
    then callback channel
    else @once "ChannelRegistered-#{channelName}", callback


  leaveChannel = (response) ->

    {first} = response
    return  unless first

    {channelId} = first

    removeChannel channelId


  removeChannel = (channelId) ->

    {socialapi} = kd.singletons

    channel = socialapi.retrieveCachedItemById channelId

    return  unless channel

    channelName = generateChannelName channel

    # delete channel data from cache
    delete socialapi.openedChannels[channelName] if socialapi.openedChannels[channelName]?

    {typeConstant, id} = channel
    socialapi.deleteCachedItem typeConstant, id

    {realtime} = kd.singletons

    realtime.unsubscribeChannel channel


  mapActivity = (data) ->

    return  unless data
    return  unless plain = data.message

    {accountOldId, replies, interactions} = data
    {createdAt, deletedAt, updatedAt, typeConstant}     = plain

    cachedItem = kd.singletons.socialapi.retrieveCachedItem typeConstant, plain.id

    return cachedItem  if cachedItem

    plain._id = plain.id

    {payload} = plain

    m = new remote.api.SocialMessage plain
    m.account = mapAccounts(accountOldId)[0]

    m.replyIds = {}
    if data.replies and data.replies.length
      m.replyIds[reply.id] = yes  for reply in data.replies

    m.replies      = mapActivities data.replies or []
    m.repliesCount = data.repliesCount
    m.isFollowed   = data.isFollowed

    # this is sent by the server when
    # response for pinned messages
    m.unreadRepliesCount = data.unreadRepliesCount

    m.clientRequestId = plain.clientRequestId

    m.interactions    = interactions or
      like            :
        actorsCount   : 0
        actorsPreview : []
        isInteracted  : no

    if payload
      if payload.link_url
        m.link       =
          link_url   : payload.link_url
          link_embed :
            try JSON.parse htmlencode.htmlDecode payload.link_embed
            catch e then null

      if payload.initialParticipants and typeof payload.initialParticipants is 'string'
        m.payload.initialParticipants =
          try JSON.parse htmlencode.htmlDecode payload.initialParticipants
          catch e then null

    new MessageEventManager {}, m

    kd.singletons.socialapi.cacheItem m

    return m


  mapActivities: mapActivities
  mapActivities = (messages) ->
    # if no result, no need to do something
    return messages  unless messages
    # get messagees from result set if they are not at the first level
    messages = messages.messageList  if messages.messageList
    messages = [].concat(messages)
    revivedMessages = []
    revivedMessages = (mapActivity message for message in messages)

    return revivedMessages


  getCurrentGroup = (callback) ->

    groupsController = kd.getSingleton "groupsController"
    groupsController.ready ->
      callback  kd.getSingleton("groupsController").getCurrentGroup()


  mapPrivateMessages: mapPrivateMessages
  mapPrivateMessages = (messages) ->

    messages = [].concat(messages)
    return [] unless messages?.length > 0

    mappedChannels = []

    for channelContainer in messages
      message             = mapActivity channelContainer.lastMessage
      channel             = mapChannel channelContainer
      channel.lastMessage = message

      mappedChannels.push channel

    registerAndOpenChannels mappedChannels

    return mappedChannels


  mapAccounts = (accounts) ->

    return [] unless accounts
    mappedAccounts = []
    accounts = [].concat(accounts)

    for account in accounts
      mappedAccounts.push {_id: account, constructorName : "JAccount"}
    return mappedAccounts


  mapChannel = (channel) ->
    { socialapi } = kd.singletons
    
    data  = channel.channel

    # hold state of cache hit
    cacheFound = no

    # item is initially our data
    item = data
        
    # if we find the channel in cache, replace item with it
    if cacheItem = socialapi.retrieveCachedItem item.typeConstant, item.id
      cacheFound = yes
      item = cacheItem

    item._id                 = data.id
    item.isParticipant       = channel.isParticipant
    # we only allow name, purpose and payload to be updated  
    item.payload             = data.payload
    item.name                = data.name
    item.purpose             = data.purpose
    item.participantCount    = channel.participantCount
    item.participantsPreview = mapAccounts channel.participantsPreview
    item.unreadCount         = channel.unreadCount
    item.lastMessage         = mapActivity channel.lastMessage  if channel.lastMessage
        
    unless cacheFound 
      channelInstance = new remote.api.SocialChannel item
    else 
      channelInstance = item

    kd.singletons.socialapi.cacheItem channelInstance

    return channelInstance


  mapParticipant = (participant) ->

    return  unless participant
    return {_id: participant.accountOldId, constructorName: "JAccount"}


  mapChannels: mapChannels
  mapChannels = (channels) ->

    return channels  unless channels

    channels        = [].concat channels
    revivedChannels = (mapChannel channel  for channel in channels)

    # bind all events
    registerAndOpenChannels revivedChannels

    return revivedChannels


  # this method will prevent the arrival of
  # realtime messages to the individual messages
  # if the message is mine and current window has focus.
  isFromOtherBrowser = (message) ->

    # selenium doesn't put focus into the
    # spawned browser, it's causing problems.
    # Probably a temporary fix.
    # This flag needs to be set before running
    # tests. ~Umut
    return no  if globals.isTesting

    {message, channelId} = message  unless message.typeConstant?

    {_inScreenMap}  = kd.singletons.socialapi

    # when I am not the message owner, it is obviously from another browser
    return yes  unless message.accountId is whoami().socialApiId

    {clientRequestId} = message

    inside = _inScreenMap[getScreenMapKey(channelId, clientRequestId)]

    return not inside

  # if a newly added user message belongs to more than one channel,
  # we just need to prevent duplicate messages for initial message channel.
  # channelId is used for this reason
  getScreenMapKey = (channelId, clientRequestId) ->

    return clientRequestId  unless channelId

    return "channel-#{channelId}:#{clientRequestId}"


  isFromOtherBrowser : isFromOtherBrowser


  forwardMessageEvents : forwardMessageEvents
  forwardMessageEvents = (source, target, events) ->

    events.forEach ({event, mapperFn, validatorFn, filterFn}) ->
      source.on event, (data, rest...) ->

        if validatorFn
          if typeof validatorFn isnt "function"
            return kd.warn "validator function is not valid"

          return  unless validatorFn(data)

        if filterFn
          if typeof filterFn isnt "function"
            return warn "filter function is not valid"

          return  unless filterFn(data)

        data = mapperFn data

        target.emit event, data, rest...


  # While making retrospective realtime message query, it is possible to fetch an already
  # existing message. This is for preventing the case. - ctf
  filterMessage = (data) ->
    {message} = data  unless data.typeConstant?
    if cachedMessage = kd.singletons.socialapi.retrieveCachedItem message.typeConstant, message.id
      return yes  if cachedMessage.isShown

    message.isShown = yes


  registerAndOpenChannels = (socialApiChannels) ->

    {socialapi} = kd.singletons
    getCurrentGroup (group)->
      socialApiChannels.forEach (socialApiChannel) ->
        channelName = generateChannelName socialApiChannel
        return  if socialapi.openedChannels[channelName]
        socialapi.cacheItem socialApiChannel
        socialapi.openedChannels[channelName] = {} # placeholder to avoid duplicate registration

        {name, typeConstant, token, id} = socialApiChannel

        subscriptionData =
          group      : group.slug
          channelType: typeConstant
          channelName: name
          channelId  : id
          token      : token

        kd.singletons.realtime.subscribeChannel subscriptionData, (err, realtimeChannel) ->

          return kd.warn err  if err

          # add opened channel to the openedChannels list, for later use
          socialapi.openedChannels[channelName] = {delegate: realtimeChannel, channel: socialApiChannel}

          # start forwarding private channel evetns to the original social channel
          forwardMessageEvents realtimeChannel, socialApiChannel, getMessageEvents()

          # notify listener
          socialapi.emit "ChannelRegistered-#{channelName}", socialApiChannel


  generateChannelName = ({name, typeConstant, groupName}) ->
    return "socialapi.#{groupName}-#{typeConstant}-#{name}"


  addToScreenMap = (options) ->
    options = options.message  if options.message?
    {clientRequestId, channelId} = options
    {_inScreenMap} = kd.singletons.socialapi

    _inScreenMap[getScreenMapKey(channelId, clientRequestId)] = yes  if clientRequestId


  addToScreenMap : addToScreenMap


  messageRequesterFn = (options) ->

    options.apiType = "message"
    return requester options


  channelRequesterFn = (options) ->

    options.apiType = "channel"
    return requester options


  notificationRequesterFn = (options) ->

    options.apiType = "notification"
    return requester options

  requester = (req) ->

    (options, callback) ->

      {fnName, validate, mapperFn, defaults, apiType, successFn} = req
      # set default mapperFn
      mapperFn or= (value) -> return value
      if validate?.length > 0
        errs = []
        for property in validate
          errs.push property unless options[property]
        if errs.length > 0
          msg = "#{errs.join(', ')} fields are required for #{fnName}"
          return callback {message: msg}

      _.defaults options, defaults  if defaults

      api = {}
      switch apiType
        when "channel"
          api = remote.api.SocialChannel
        when "notification"
          api = remote.api.SocialNotification
        else
          api = remote.api.SocialMessage
          addToScreenMap options

      api[fnName] options, (err, result)->
        return callback err if err
        successFn result if successFn and typeof successFn is "function"
        return callback null, mapperFn result


  cacheItem: (item) ->

    {typeConstant, id} = item

    @_cache[typeConstant]     ?= {}
    @_cache[typeConstant][id]  = item

    return item


  retrieveCachedItem: (type, id) ->

    return item  if item = @_cache[type]?[id]

    if type is 'topic'
      for own id_, topic of @_cache.topic when topic.name is id
        return topic

    if type is 'activity'
      for own id_, post of @_cache.post when post.slug is id
        return post

    return null


  retrieveCachedItemById: (id) ->

    for own typeConstant, items of @_cache
      return item  if item = @_cache[typeConstant][id]

    return null


  deleteCachedItem: (type, id) ->
    delete @_cache[type]?[id]


  cacheable: (type, id, force, callback) ->
    [callback, force] = [force, no]  unless callback

    if not force and item = @retrieveCachedItem(type, id)

      return callback null, item

    kallback = (err, data) =>
      return callback err  if err

      callback null, @cacheItem data

    topicChannelKallback = (err, data) =>
      return callback err  if err

      registerAndOpenChannels [data]
      kallback err, data

    return switch type
      when 'topic'
        @channel.byName {name: id}, topicChannelKallback
      when 'activity'
        @message.bySlug {slug: id}, kallback
      when 'channel', 'privatemessage', 'collaboration'
        @channel.byId {id}, topicChannelKallback
      when 'post', 'message'
        @message.byId {id}, kallback
      else callback { message: "#{type} not implemented in revive" }

  getMessageEvents = ->
    [
      {event: "MessageAdded",       mapperFn: mapActivity, validatorFn: isFromOtherBrowser, filterFn: filterMessage}
      {event: "MessageRemoved",     mapperFn: mapActivity, validatorFn: isFromOtherBrowser}
      {event: "AddedToChannel",     mapperFn: mapParticipant}
      {event: "RemovedFromChannel", mapperFn: mapParticipant}
      {event: "ChannelDeleted",     mapperFn: mapChannel}
    ]

  serialize = (obj) ->
    str = []
    for own p of obj
      str.push(encodeURIComponent(p) + "=" + encodeURIComponent(obj[p]))

    return str.join "&"

  message:
    byId                 : messageRequesterFn
      fnName             : 'byId'
      validateOptionsWith: ['id']
      mapperFn           : mapActivity

    bySlug               : messageRequesterFn
      fnName             : 'bySlug'
      validateOptionsWith: ['slug']
      mapperFn           : mapActivity

    edit                 : messageRequesterFn
      fnName             : 'edit'
      validateOptionsWith: ['id', 'body']
      mapperFn           : mapActivity

    post                 : messageRequesterFn
      fnName             : 'post'
      validateOptionsWith: ['body']
      mapperFn           : mapActivity

    reply                : messageRequesterFn
      fnName             : 'reply'
      validateOptionsWith: ['body', 'messageId']
      mapperFn           : mapActivity

    delete               : messageRequesterFn
      fnName             : 'delete'
      validateOptionsWith: ['id']

    like                 : messageRequesterFn
      fnName             : 'like'
      validateOptionsWith: ['id']

    unlike               : messageRequesterFn
      fnName             : 'unlike'
      validateOptionsWith: ['id']

    listReplies          : messageRequesterFn
      fnName             : 'listReplies'
      validateOptionsWith: ['messageId']
      mapperFn           : mapActivities

    listLikers           : messageRequesterFn
      fnName             : 'listLikers'
      validateOptionsWith: ['id']

    initPrivateMessage   : messageRequesterFn
      fnName             : 'initPrivateMessage'
      validateOptionsWith: ['body', 'recipients']
      mapperFn           : mapPrivateMessages

    sendPrivateMessage   : messageRequesterFn
      fnName             : 'sendPrivateMessage'
      validateOptionsWith: ['body', 'channelId']
      mapperFn           : mapPrivateMessages

    search               : messageRequesterFn
      fnName             : 'search'
      validateOptionsWith: ['name']
      mapperFn           : mapPrivateMessages

    fetchPrivateMessages : messageRequesterFn
      fnName             : 'fetchPrivateMessages'
      mapperFn           : mapPrivateMessages

    revive               : mapActivity

    fetchDataFromEmbedly : (args...) ->
      remote.api.SocialMessage.fetchDataFromEmbedly args...

  channel:
    byId                 : channelRequesterFn
      fnName             : 'byId'
      validateOptionsWith: ['id']
      mapperFn           : mapChannel

    byName               : channelRequesterFn
      fnName             : 'byName'
      validateOptionsWith: ['name']
      mapperFn           : mapChannel

    update               : channelRequesterFn
      fnName             : 'update'
      validateOptionsWith: ["id"]
      mapperFn           : mapChannel

    list                 : channelRequesterFn
      fnName             : 'fetchChannels'
      mapperFn           : mapChannels

    fetchActivities      : (options = {}, callback = kd.noop)->

      # show exempt content if only requester is admin or exempt herself
      showExempt = checkFlag?("super-admin") or whoami()?.isExempt

      options.showExempt or= showExempt

      err = {message: "An error occurred"}

      endPoint = "/api/social/channel/#{options.id}/history?#{serialize(options)}"
      doXhrRequest {type: 'GET', endPoint, async: yes}, (err, response) ->
        return callback err  if err

        return callback null, mapActivities response


    fetchPopularPosts    : channelRequesterFn
      fnName             : 'fetchPopularPosts'
      validateOptionsWith: ['channelName']
      defaults           : type: 'weekly'
      mapperFn           : mapActivities

    fetchPopularTopics   : channelRequesterFn
      fnName             : 'fetchPopularTopics'
      defaults           : type: 'weekly'
      mapperFn           : mapChannels

    fetchPinnedMessages  : channelRequesterFn
      fnName             : 'fetchPinnedMessages'
      validateOptionsWith: []
      mapperFn           : mapActivities

    pin                  : channelRequesterFn
      fnName             : 'pinMessage'
      validateOptionsWith: ['messageId']

    unpin                : channelRequesterFn
      fnName             : 'unpinMessage'
      validateOptionsWith: ['messageId']

    follow               : channelRequesterFn
      fnName             : 'addParticipants'
      validateOptionsWith: ['channelId']

    unfollow             : channelRequesterFn
      fnName             : 'removeParticipants'
      validateOptionsWith: ['channelId']

    listParticipants     : channelRequesterFn
      fnName             : 'listParticipants'
      validateOptionsWith: ['channelIds']

    addParticipants      : channelRequesterFn
      fnName             : 'addParticipants'
      validateOptionsWith: ['channelId', "accountIds"]

    removeParticipants    : channelRequesterFn
      fnName              : 'removeParticipants'
      validateOptionsWith : ['channelId', "accountIds"]

    leave                 : channelRequesterFn
      fnName              : 'leave'
      validateOptionsWith : ['channelId']
      successFn           : leaveChannel

    kickParticipants     : channelRequesterFn
      fnName             : 'leave'
      validateOptionsWith: ['channelId', 'accountIds']

    fetchFollowedChannels: channelRequesterFn
      fnName             : 'fetchFollowedChannels'
      mapperFn           : mapChannels

    searchTopics         : channelRequesterFn
      fnName             : 'searchTopics'
      validateOptionsWith: ['name']
      mapperFn           : mapChannels

    fetchProfileFeed     : channelRequesterFn
      fnName             : 'fetchProfileFeed'
      validateOptionsWith: ['targetId']
      mapperFn           : mapActivities

    glancePinnedPost     : channelRequesterFn
      fnName             : 'glancePinnedPost'
      validateOptionsWith: ["messageId"]

    updateLastSeenTime   : channelRequesterFn
      fnName             : 'updateLastSeenTime'
      validateOptionsWith: ["channelId"]

    delete               : channelRequesterFn
      fnName             : 'delete'
      validateOptionsWith: ["channelId"]
      successFn          : removeChannel

    revive               : mapChannel

  moderation:
    link     : (options, callback) ->
      doXhrRequest {
        endPoint : "/api/social/moderation/channel/#{options.rootId}/link"
        type     : 'POST'
        data     : options
      }, callback

    unlink   : (options, callback) ->
      doXhrRequest {
        endPoint : "/api/social/moderation/channel/#{options.rootId}/link/#{options.leafId}?#{serialize(options)}"
        type     : 'DELETE'
      }, callback

    list     : (options, callback) ->
      doXhrRequest {
        endPoint : "/api/social/moderation/channel/#{options.rootId}/link?#{serialize(options)}"
        type     : 'GET'
      }, (err, result)->
        return callback err if err
        return callback null, mapChannels result

    blacklist: (options, callback) ->
      doXhrRequest {
        endPoint : "/api/social/moderation/channel/blacklist"
        type     : 'POST'
        data     : options
      }, callback

  notifications          :
    fetch                : notificationRequesterFn
      fnName             : 'fetch'

    glance               : notificationRequesterFn
      fnName             : 'glance'

  account                :
    impersonate          : (username, callback) ->

      endPoint = "/Impersonate/#{username}"
      doXhrRequest {type: 'POST', endPoint, async: yes}, callback

    fetchBotChannel      : (callback) ->
      getCurrentGroup (group) ->

        { nickname } = whoami().profile
        doXhrRequest {
          type     : 'GET'
          endPoint : "/api/integration/botchannel"
        }, (err, response) ->
          return callback err  if err

          {channelId} = response

          { socialapi } = kd.singletons

          socialapi.channel.byId {id: channelId}, (err, channel) ->

            return callback err  if err

            return callback null, mapChannel { channel: channel }
