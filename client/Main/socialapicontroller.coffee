class SocialApiController extends KDController

  constructor: (options = {}, data) ->

    @openedChannels = {}
    @_cache         = {}

    super options, data

  getPrefetchedData: (dataPath) ->

    return [] unless KD.socialApiData

    data = if dataPath is 'navigated'
    then KD.socialApiData[dataPath].messageList
    else KD.socialApiData[dataPath]

    return [] unless data

    fn = switch dataPath
      when 'popularTopics', 'followedChannels' then mapChannels
      when 'pinnedMessages', 'navigated'       then mapActivities
      when 'privateMessages'                   then mapPrivateMessages

    return fn(data) or []


  eachCached: (id, fn) ->
    fn section[id]  for own name, section of @_cache when id of section

  onChannelReady: (channel, callback) ->
    channelName = generateChannelName channel
    if channel = @openedChannels[channelName]?.channel
    then callback channel
    else @once "ChannelRegistered-#{channelName}", callback

  mapActivity = (data) ->

    return  unless data
    return  unless plain = data.message

    {accountOldId, replies, interactions} = data
    {createdAt, deletedAt, updatedAt}     = plain

    plain._id = plain.id

    {payload} = plain
    delete plain.payload

    m = new KD.remote.api.SocialMessage plain
    m.account = mapAccounts(accountOldId)[0]

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

    m.meta      =
      createdAt : new Date createdAt
      deletedAt : new Date deletedAt
      updatedAt : new Date updatedAt

    if payload
      m.link       =
        link_url   : payload.link_url
        link_embed :
          try JSON.parse Encoder.htmlDecode payload.link_embed
          catch e then null

    new MessageEventManager {}, m

    KD.singletons.socialapi.cacheItem m

    return m

  mapActivities = (messages)->
    # if no result, no need to do something
    return messages unless messages
    # get messagees from result set if they are not at the first level
    messages = messages.messageList if messages.messageList
    messages = [].concat(messages)
    revivedMessages = []
    {SocialMessage} = KD.remote.api
    revivedMessages = (mapActivity message for message in messages)
    return revivedMessages

  mapActivities: mapActivities

  getCurrentGroup = (callback)->
    groupsController = KD.getSingleton "groupsController"
    groupsController.ready ->
      callback  KD.getSingleton("groupsController").getCurrentGroup()

  mapPrivateMessages: mapPrivateMessages
  mapPrivateMessages = (messages)->
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

  mapAccounts = (accounts)->
    return [] unless accounts
    mappedAccounts = []
    accounts = [].concat(accounts)

    for account in accounts
      mappedAccounts.push {_id: account, constructorName : "JAccount"}
    return mappedAccounts


  mapChannel = (channel) ->

    data                     = channel.channel
    data._id                 = data.id
    data.isParticipant       = channel.isParticipant
    data.participantCount    = channel.participantCount
    data.participantsPreview = mapAccounts channel.participantsPreview
    data.unreadCount         = channel.unreadCount
    data.lastMessage         = mapActivity channel.lastMessage  if channel.lastMessage


    channelInstance = new KD.remote.api.SocialChannel data

    KD.singletons.socialapi.cacheItem channelInstance

    return channelInstance

  mapParticipant = (participant) ->
    return  unless participant
    return {_id: participant.accountOldId, constructorName: "JAccount"}

  mapChannels = (channels)->

    return channels  unless channels

    channels        = [].concat channels
    revivedChannels = (mapChannel channel  for channel in channels)

    # bind all events
    registerAndOpenChannels revivedChannels

    return revivedChannels


  mapChannels: mapChannels



  forwardMessageEvents = (source, target,  events)->
    events.forEach ({event, mapperFn}) ->
      source.on event, (data, rest...) ->
        data = mapperFn data
        target.emit event, data, rest...

  forwardMessageEvents : forwardMessageEvents

  registerAndOpenChannels = (socialApiChannels)->
    {socialapi} = KD.singletons

    getCurrentGroup (group)->
      socialApiChannels.forEach (socialApiChannel) ->
        channelName = generateChannelName socialApiChannel
        return  if socialapi.openedChannels[channelName]
        socialapi.cacheItem socialApiChannel
        socialapi.openedChannels[channelName] = {} # placeholder to avoid duplicate registration

        subscriptionData =
          serviceType: 'socialapi'
          group      : group.slug
          channelType: socialApiChannel.typeConstant
          channelName: socialApiChannel.name
          isExclusive: yes
          connectDirectly: yes

        # do not use callbacks while subscribing, KD.remote.subscribe already
        # returns the required channel object. Use it. Callbacks are called
        # twice in the subscribe function
        brokerChannel = KD.remote.subscribe channelName, subscriptionData

        # add opened channel to the openedChannels list, for later use
        socialapi.openedChannels[channelName] = {delegate: brokerChannel, channel: socialApiChannel}

        # start forwarding private channel evetns to the original social channel
        forwardMessageEvents brokerChannel, socialApiChannel, getMessageEvents()

        # notify listener
        socialapi.emit "ChannelRegistered-#{channelName}", socialApiChannel


  cycleChannel: (channel, callback)->
    options =
      groupSlug     : channel.groupName
      apiChannelType: channel.typeConstant
      apiChannelName: channel.name
    KD.remote.api.SocialChannel.cycleChannel options, callback

  generateChannelName = ({name, typeConstant, groupName}) ->
    return "socialapi.#{groupName}-#{typeConstant}-#{name}"

  messageRequesterFn = (options)->
    options.apiType = "message"
    return requester options

  channelRequesterFn = (options)->
    options.apiType = "channel"
    return requester options

  requester = (req) ->
    (options, callback)->
      {fnName, validate, mapperFn, defaults, apiType} = req
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
      if apiType is "channel"
        api = KD.remote.api.SocialChannel
      else
        api = KD.remote.api.SocialMessage

      api[fnName] options, (err, result)->
        return callback err if err
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
        item = topic

    if not item and type is 'activity'
      for own id_, post of @_cache.post when post.slug is id
        item = post

    return item


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
      when 'topic'                     then @channel.byName {name: id}, topicChannelKallback
      when 'activity'                  then @message.bySlug {slug: id}, kallback
      when 'channel', 'privatemessage' then @channel.byId {id}, topicChannelKallback
      when 'post', 'message'           then @message.byId {id}, kallback
      else callback { message: "#{type} not implemented in revive" }

  getMessageEvents = ->
    [
      {event: "MessageAdded", mapperFn: mapActivity}
      {event: "MessageRemoved", mapperFn: mapActivity}
      {event: "AddedToChannel", mapperFn: mapParticipant}
    ]


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

    initPrivateMessageFromBot : messageRequesterFn
      fnName                  : 'initPrivateMessageFromBot'
      validateOptionsWith     : ['body']
      mapperFn                : mapPrivateMessages

    sendPrivateMessageFromBot : messageRequesterFn
      fnName                  : 'sendPrivateMessageFromBot'
      validateOptionsWith     : ['body', 'channelId']
      mapperFn                : mapPrivateMessages

    fetchPrivateMessages : messageRequesterFn
      fnName             : 'fetchPrivateMessages'
      mapperFn           : mapPrivateMessages

    revive               : mapActivity

    fetchDataFromEmbedly : (args...) ->
      KD.remote.api.SocialMessage.fetchDataFromEmbedly args...

  channel:
    byId                 : channelRequesterFn
      fnName             : 'byId'
      validateOptionsWith: ['id']
      mapperFn           : mapChannel

    byName               : channelRequesterFn
      fnName             : 'byName'
      validateOptionsWith: ['name']
      mapperFn           : mapChannel

    list                 : channelRequesterFn
      fnName             : 'fetchChannels'
      mapperFn           : mapChannels

    fetchActivities      : channelRequesterFn
      fnName             : 'fetchActivities'
      validateOptionsWith: ['id']
      mapperFn           : mapActivities

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

    addParticipants      : channelRequesterFn
      fnName             : 'addParticipants'
      validateOptionsWith: ['channelId', "accountIds"]

    removeParticipants    : channelRequesterFn
      fnName              : 'removeParticipants'
      validateOptionsWith : ['channelId', "accountIds"]

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

    revive               : mapChannel
