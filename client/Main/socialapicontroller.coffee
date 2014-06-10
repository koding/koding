class SocialApiController extends KDController

  constructor: (options = {}, data) ->
    @openedChannels = {}
    super options, data

    KD.getSingleton("mainController").ready @bound "openGroupChannel"

  getPrefetchedData:->

    data = {}

    return data  unless KD.socialApiData

    { popularTopics, followedChannels
      pinnedMessages, privateMessages,
      publicFeed } = KD.socialApiData

    processInCase = (fn, items) -> if items then fn items else []

    data.popularTopics    = processInCase mapChannels, popularTopics
    data.followedChannels = processInCase mapChannels, followedChannels
    data.pinnedMessages   = processInCase mapActivities, pinnedMessages
    data.privateMessages  = processInCase mapPrivateMessages, privateMessages
    data.publicFeed       = processInCase mapActivities, publicFeed

    return data

  openGroupChannel: ->
    # to - do refactor this part to use same functions with other parts
    groupsController = KD.singleton "groupsController"
    groupsController.ready =>
      {slug} = groupsController.getCurrentGroup()

      subscriptionData =
        serviceType: 'socialapi'
        group      : slug
        channelType: "group"
        channelName: slug
        isExclusive: yes

      channelName    = generateChannelName
        name         : slug
        typeConstant : 'group'
        groupName    : slug

      brokerChannel = KD.remote.subscribe channelName, subscriptionData
      @forwardMessageEvents brokerChannel, this, ["MessageAdded", "MessageRemoved"]
      @openedChannels[name] = brokerChannel
      @emit "ChannelRegistered-#{channelName}", this

  onChannelReady: (channel, callback) ->
    channelName = generateChannelName channel
    channel = @openedChannels[channelName]
    if channel instanceof KD.remote.api.SocialChannel
    then callback channel
    else @once "ChannelRegistered-#{channelName}", callback

  mapActivity = (data) ->

    return  unless data
    return  unless plain = data.message

    {accountOldId, replies, interactions} = data
    {createdAt, deletedAt, updatedAt}     = plain

    plain._id = plain.id

    m = new KD.remote.api.SocialMessage plain
    m.account = mapAccounts(accountOldId)[0]

    m.replies      = mapActivities data.replies or []
    m.repliesCount = data.repliesCount
    m.isFollowed   = data.isFollowed

    # this is sent by the server when
    # response for pinned messages
    m.unreadRepliesCount = data.unreadRepliesCount

    m.interactions    = interactions or
      like            :
        actorsCount   : 0
        actorsPreview : []
        isInteracted  : no

    m.meta      =
      createdAt : new Date createdAt
      deletedAt : new Date deletedAt
      updatedAt : new Date updatedAt

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
      message = mapActivity channelContainer.lastMessage
      channel = mapChannels(channelContainer)?[0]
      channel.lastMessage = message

      mappedChannels.push channel

    return mappedChannels

  mapAccounts = (accounts)->
    return [] unless accounts
    mappedAccounts = []
    accounts = [].concat(accounts)

    for account in accounts
      mappedAccounts.push {_id: account, constructorName : "JAccount"}
    return mappedAccounts

  mapChannels = (channels)->
    return channels unless channels
    revivedChannels = []
    channels = [].concat(channels)
    {SocialChannel} = KD.remote.api
    for channel in channels
      data                     = channel.channel
      data._id                 = data.id
      data.isParticipant       = channel.isParticipant
      data.participantCount    = channel.participantCount
      data.participantsPreview = mapAccounts channel.participantsPreview
      data.unreadCount         = channel.unreadCount
      data.lastMessage = mapActivity channel.lastMessage if channel.lastMessage
      c = new SocialChannel data
      # push channel into stack
      revivedChannels.push c
    # bind all events
    registerAndOpenChannels revivedChannels
    return revivedChannels
  mapChannels: mapChannels


  forwardMessageEvents = (source, target,  events)->
    events.forEach (event) ->
      source.on event, (message, rest...) ->
        message = mapActivity message
        target.emit event, message, rest...

  forwardMessageEvents : forwardMessageEvents

  registerAndOpenChannels = (socialApiChannels)->
    {socialapi} = KD.singletons

    getCurrentGroup (group)->
      for socialApiChannel in socialApiChannels
        channelName = generateChannelName socialApiChannel
        continue  if socialapi.openedChannels[channelName]
        socialapi.openedChannels[channelName] = {} # placeholder to avoid duplicate registration

        subscriptionData =
          serviceType: 'socialapi'
          group      : group.slug
          channelType: socialApiChannel.typeConstant
          channelName: channelName
          isExclusive: yes

        KD.remote.subscribe name, subscriptionData, (brokerChannel)->
          {name} = brokerChannel
          socialapi.openedChannels[name] = brokerChannel
          forwardMessageEvents brokerChannel, socialApiChannel, [
            "MessageAdded",
            "MessageRemoved"
          ]

          socialapi.emit "ChannelRegistered-#{name}", brokerChannel

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
      mapperFn or= ->
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


  revive :(type, id, callback) ->
    api = KD.singletons.socialapi
    switch type
      when "topic"
        return api.channel.byName {name: id}, callback
      when "channel", "privatemessage"
        return api.channel.byId {id}, callback
      when "post", "message"
        return api.message.byId {id}, callback
      else
        return callback { message: "not implemented in revive" }

  message:
    byId                 : messageRequesterFn
      fnName             : 'byId'
      validateOptionsWith: ['id']
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

    sendPrivateMessage   : messageRequesterFn
      fnName             : 'sendPrivateMessage'
      validateOptionsWith: ['body']
      mapperFn           : mapPrivateMessages

    fetchPrivateMessages : messageRequesterFn
      fnName             : 'fetchPrivateMessages'
      mapperFn           : mapPrivateMessages

    revive               : mapActivity

  channel:
    byId                 : channelRequesterFn
      fnName             : 'byId'
      validateOptionsWith: ['id']
      mapperFn           : mapChannels

    byName               : channelRequesterFn
      fnName             : 'byName'
      validateOptionsWith: ['name']
      mapperFn           : mapChannels

    list                 : channelRequesterFn
      fnName             : 'fetchChannels'
      mapperFn           : mapChannels

    fetchActivities      : channelRequesterFn
      fnName             : 'fetchActivities'
      validateOptionsWith: ["id"]
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
      fnName             : 'follow'
      validateOptionsWith: ['channelId']

    unfollow             : channelRequesterFn
      fnName             : 'unfollow'
      validateOptionsWith: ['channelId']

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


