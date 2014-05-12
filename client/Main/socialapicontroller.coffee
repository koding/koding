class SocialApiController extends KDController

  constructor: (options = {}, data) ->
    @openedChannels = {}
    super options, data

  mapActivity = (data)->
    message = data?.message or data
    # if no result, no need to do something
    return message unless message

    {SocialMessage} = KD.remote.api
    message._id = message.id
    m = new SocialMessage message
    m.account = {}
    m.account.constructorName = "JAccount"
    m.account._id = data.accountOldId
    m.meta = {}
    m.meta.createdAt = message.createdAt
    m.replies = mapActivities data.replies
    m.repliesCount = data.replies?.length or 0
    m.interactions = data.interactions

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

  getCurrentGroup = (callback)->
    groupsController = KD.getSingleton "groupsController"
    groupsController.ready ->
      callback  KD.getSingleton("groupsController").getCurrentGroup()

  fetchChannelActivities = (options, callback)->
    unless options.id
      return callback {message: "Channel id is not set for request"}
    getCurrentGroup (group)->
      options.groupName = group.slug
      channelApiActivitiesResFunc "fetchActivities", options, callback

  fetchGroupActivities = (options, callback)->
    getCurrentGroup (group)->
      unless group.socialApiChannelId
        return callback {message: "Group doesnt have socialApiChannelId"}
      options.id        = group.socialApiChannelId
      options.groupName = group.slug
      channelApiActivitiesResFunc "fetchActivities", options, callback

  fetchChannels = (options, callback)->
    getCurrentGroup (group)->
      options.groupName = group.slug
      channelApiChannelsResFunc 'fetchChannels', options, callback

  fetchPopularTopics = (options, callback)->
    getCurrentGroup (group)->
      options.groupName = group.slug
      channelApiChannelsResFunc 'fetchPopularTopics', options, callback

  messageApiMessageResFunc = (name, rest..., callback)->
    KD.remote.api.SocialMessage[name] rest..., (err, res)->
      return callback err if err
      return callback null, mapActivity res

  channelApiActivitiesResFunc = (name, rest..., callback)->
    KD.remote.api.SocialChannel[name] rest..., (err, result)->
      return callback err if err
      return callback null, mapActivities result

  channelApiChannelsResFunc = (name, rest..., callback)->
    KD.remote.api.SocialChannel[name] rest..., (err, result)->
      return callback err if err
      return callback null, mapChannels result

  sendPrivateMessageRequest = (name, rest..., callback)->
    KD.remote.api.SocialMessage[name] rest..., (err, result)->
      return callback err if err
      return callback null, mapPrivateMessages result

  mapPrivateMessages = (messages)->
    messages = [].concat(messages)
    return [] unless messages?.length > 0

    mappedMessages = []

    for messageContainer in messages
      message = mapActivity messageContainer.lastMessage
      message.channel = mapChannels(messageContainer)[0]
      mappedMessages.push message

    return mappedMessages

  mapChannels = (channels)->
    return channels unless channels
    revivedChannels = []
    channels = [].concat(channels)
    {SocialChannel} = KD.remote.api
    for channel in channels
      data = channel.channel
      data.isParticipant = channel.isParticipant
      data.participantCount = channel.participantCount
      data.participantsPreview = channel.participantsPreview
      c = new SocialChannel data
      # push channel into stack
      revivedChannels.push c
    # bind all events
    registerAndOpenChannels revivedChannels
    return revivedChannels

  forwardMessageEvents = (source, target,  events)->
    events.forEach (event) ->
      source.on event, (message, rest...) ->
        message = mapActivity message
        target.emit event, message, rest...

  registerAndOpenChannels = (socialApiChannels)->
    getCurrentGroup (group)->
      for socialApiChannel in socialApiChannels
        # lock
        name = "socialapi.#{socialApiChannel.groupName}-#{socialApiChannel.typeConstant}-#{socialApiChannel.name}"
        continue  if KD.singletons.socialapi.openedChannels[name]
        KD.singletons.socialapi.openedChannels[name] = {}

        subscriptionData =
          serviceType: 'socialapi'
          group      : group.slug
          channelType: socialApiChannel.typeConstant
          channelName: socialApiChannel.name
          isExclusive: yes

        KD.remote.subscribe name, subscriptionData, (brokerChannel)->
          KD.singletons.socialapi.openedChannels[brokerChannel.name] = brokerChannel
          forwardMessageEvents brokerChannel, socialApiChannel, [
            "MessageAdded",
            "MessageRemoved"
          ]

  message:
    edit   :(args...)-> messageApiMessageResFunc 'edit', args...
    post   :(args...)-> messageApiMessageResFunc 'post', args...
    reply  :(args...)-> messageApiMessageResFunc 'reply', args...
    delete :(args...)-> KD.remote.api.SocialMessage.delete args...
    like   :(args...)-> KD.remote.api.SocialMessage.like args...
    unlike :(args...)-> KD.remote.api.SocialMessage.unlike args...
    listLikers:(args...)-> KD.remote.api.SocialMessage.listLikers args...
    sendPrivateMessage :(args...)->
      sendPrivateMessageRequest 'sendPrivateMessage', args...
    fetchPrivateMessages :(args...)->
      sendPrivateMessageRequest 'fetchPrivateMessages', args...
    revive : mapActivity

  channel:
    list                 : fetchChannels
    fetchActivities      : fetchChannelActivities
    fetchGroupActivities : fetchGroupActivities
    fetchPopularTopics   : fetchPopularTopics
    fetchPinnedMessages  : (args...)->
      channelApiActivitiesResFunc 'fetchPinnedMessages', args...
    pin                  : (args...)->
      KD.remote.api.SocialChannel.pinMessage args...
    unpin                : (args...)->
      KD.remote.api.SocialChannel.unpinMessage args...
    follow               : (args...)->
      KD.remote.api.SocialChannel.follow args...
    unfollow             : (args...)->
      KD.remote.api.SocialChannel.unfollow args...
    fetchFollowedChannels: (args...)->
      channelApiChannelsResFunc 'fetchFollowedChannels', args...
    searchTopics         : (args...)->
      channelApiChannelsResFunc 'searchTopics', args...
