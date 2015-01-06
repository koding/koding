class SocialApiController extends KDController

  constructor: (options = {}, data) ->

    @openedChannels = {}
    @_cache         = {}
    @_inScreenMap   = {}

    super options, data


  getPrefetchedData: (dataPath) ->

    return [] unless KD.socialApiData

    data = if dataPath is 'navigated'
    then KD.socialApiData[dataPath]?.data?.messageList
    else KD.socialApiData[dataPath]

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
    return no  if KD.checkFlag "super-admin"

    {socialApiAnnouncementChannelId} = KD.getGroup()

    return channelId is socialApiAnnouncementChannelId


  onChannelReady: (channel, callback) ->
    channelName = generateChannelName channel
    if channel = @openedChannels[channelName]?.channel
    then callback channel
    else @once "ChannelRegistered-#{channelName}", callback


  leaveChannel = (response) ->
    {first} = response
    return  unless first

    {socialapi} = KD.singletons
    {channelId} = first
    channel = socialapi._cache["privatemessage"][channelId]

    return  unless channel

    channelName = generateChannelName channel

    # delete channel data from cache
    delete socialapi.openedChannels[channelName] if socialapi.openedChannels[channelName]?

    {typeConstant, id} = channel
    delete socialapi._cache[typeConstant][id]

    {realtime} = KD.singletons

    realtime.unsubscribeChannel channel


  mapActivity = (data) ->

    return  unless data
    return  unless plain = data.message

    {accountOldId, replies, interactions} = data
    {createdAt, deletedAt, updatedAt}     = plain

    plain._id = plain.id

    {payload} = plain

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

    if payload
      if payload.link_url
        m.link       =
          link_url   : payload.link_url
          link_embed :
            try JSON.parse Encoder.htmlDecode payload.link_embed
            catch e then null

      if payload.initialParticipants and typeof payload.initialParticipants is 'string'
        payload.initialParticipants =
          try JSON.parse Encoder.htmlDecode payload.initialParticipants
          catch e then null

    new MessageEventManager {}, m

    KD.singletons.socialapi.cacheItem m

    return m


  mapActivities: mapActivities
  mapActivities = (messages) ->
    # if no result, no need to do something
    return messages  unless messages
    # get messagees from result set if they are not at the first level
    messages = messages.messageList  if messages.messageList
    messages = [].concat(messages)
    revivedMessages = []
    {SocialMessage} = KD.remote.api
    revivedMessages = (mapActivity message for message in messages)
    return revivedMessages


  getCurrentGroup = (callback) ->

    groupsController = KD.getSingleton "groupsController"
    groupsController.ready ->
      callback  KD.getSingleton("groupsController").getCurrentGroup()


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
    return no  if KD.isTesting

    {message} = message  unless message.typeConstant?
    {_inScreenMap}  = KD.singletons.socialapi

    {messageId, body, initialChannelId} = message

    type = messageId or initialChannelId
    token = getScreenMapToken body, type

    inside = _inScreenMap[token]

    return not inside


  isFromOtherBrowser : isFromOtherBrowser


  forwardMessageEvents : forwardMessageEvents
  forwardMessageEvents = (source, target, events) ->

    events.forEach ({event, mapperFn, validatorFn}) ->
      source.on event, (data, rest...) ->

        if validatorFn
          if typeof validatorFn isnt "function"
            return warn "validator function is not valid"

          return  unless validatorFn(data)

        data = mapperFn data

        target.emit event, data, rest...


  registerAndOpenChannels = (socialApiChannels) ->

    {socialapi} = KD.singletons
    getCurrentGroup (group)->
      socialApiChannels.forEach (socialApiChannel) ->
        channelName = generateChannelName socialApiChannel
        return  if socialapi.openedChannels[channelName]
        socialapi.cacheItem socialApiChannel
        socialapi.openedChannels[channelName] = {} # placeholder to avoid duplicate registration

        {name, typeConstant, token} = socialApiChannel

        subscriptionData =
          serviceType: 'socialapi'
          group      : group.slug
          channelType: typeConstant
          channelName: name
          isExclusive: yes
          connectDirectly: yes
          brokerChannelName: channelName
          token      : token

        KD.singletons.realtime.subscribeChannel subscriptionData, (err, realtimeChannel) ->

          return warn err  if err

          # add opened channel to the openedChannels list, for later use
          socialapi.openedChannels[channelName] = {delegate: realtimeChannel, channel: socialApiChannel}

          # start forwarding private channel evetns to the original social channel
          forwardMessageEvents realtimeChannel, socialApiChannel, getMessageEvents()

          # notify listener
          socialapi.emit "ChannelRegistered-#{channelName}", socialApiChannel


  generateChannelName = ({name, typeConstant, groupName}) ->
    return "socialapi.#{groupName}-#{typeConstant}-#{name}"


  getScreenMapToken = (body, type) ->

    {_id} = KD.whoami()
    md5.digest "#{type}-#{body}-#{_id}"


  addToScreenMap = (options) ->

    {messageId, body, channelId} = options
    {_inScreenMap} = KD.singletons.socialapi

    type  = messageId or channelId
    token = getScreenMapToken body, type

    _inScreenMap[token] = yes


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
          api = KD.remote.api.SocialChannel
        when "notification"
          api = KD.remote.api.SocialNotification
        else
          api = KD.remote.api.SocialMessage
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
      {event: "MessageAdded",       mapperFn: mapActivity, validatorFn: isFromOtherBrowser}
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

    fetchActivities      : (options, callback)->
      err = {message: "An error occurred"}

      endPoint = "/api/social/channel/#{options.id}/history?#{serialize(options)}"
      KD.utils.doXhrRequest {type: 'GET', endPoint, async: no}, (err, response) ->
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

    revive               : mapChannel

  notifications          :
    fetch                : notificationRequesterFn
      fnName             : 'fetch'

    glance               : notificationRequesterFn
      fnName             : 'glance'
