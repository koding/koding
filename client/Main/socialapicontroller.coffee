class SocialApiController extends KDController

  constructor: (options = {}, data) ->
    super options, data

  mapActivity = (data)->
    message = data?.message or data
    # if no result, no need to do something
    return message unless message

    {SocialMessage} = KD.remote.api
    m = new SocialMessage message
    m._id = message.id
    m.account = {}
    m.account.constructorName = "JAccount"
    m.account._id = data.accountOldId
    m.meta = {}
    m.meta.createdAt = message.createdAt
    m.replies = data.replies
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
      # until we create message id's
      # programmatically
      # inorder to make realtime updates work
      # we need `channel-` here
      c._id = "channel-#{c.id}"

      # bind all events
      registerAndOpenChannel c

      c.on "*", -> console.log arguments
      c.on "MessageAdded", -> console.log arguments, "messageadded"
      # push channel into stack
      revivedChannels.push c

    return revivedChannels

  forwardMessageEvents = (source, target,  events)->
    events.forEach (event) ->
      source.on event, (message, rest...) ->
        message = mapActivity message
        target.emit event, message, rest...

  registerAndOpenChannel = (socialApiChannel)->
    getCurrentGroup (group)->
      subscriptionData =
        serviceType: 'socialapi'
        group      : group.slug
        channelType: socialApiChannel.typeConstant
        channelName: socialApiChannel.name
        isExclusive: yes

      name = "socialapi.#{socialApiChannel.groupName}-#{socialApiChannel.typeConstant}-#{socialApiChannel.name}"
      brokerChannel = KD.remote.subscribe name, subscriptionData
      forwardMessageEvents brokerChannel, socialApiChannel, [
        "MessageAdded",
        "MessageRemoved"
      ]

  message:
    edit   :(rest...)-> messageApiMessageResFunc 'edit', rest...
    post   :(rest...)-> messageApiMessageResFunc 'post', rest...
    reply  :(rest...)-> messageApiMessageResFunc 'reply', rest...
    delete :(rest...)-> KD.remote.api.SocialMessage.delete rest...
    like   :(rest...)-> KD.remote.api.SocialMessage.like rest...
    unlike :(rest...)-> KD.remote.api.SocialMessage.unlike rest...
    listLikers:(rest...)-> KD.remote.api.SocialMessage.listLikers rest...
    sendPrivateMessage :(rest...)->
      sendPrivateMessageRequest 'sendPrivateMessage', rest...
    fetchPrivateMessages :(rest...)->
      sendPrivateMessageRequest 'fetchPrivateMessages', rest...
    revive : mapActivity

  channel:
    list                 : fetchChannels
    fetchActivities      : fetchChannelActivities
    fetchGroupActivities : fetchGroupActivities
    fetchPopularTopics   : fetchPopularTopics
    fetchPinnedMessages  : (rest...)->
      channelApiActivitiesResFunc 'fetchPinnedMessages', rest...
    pin                  : (rest...)->
      KD.remote.api.SocialChannel.pinMessage rest...
    unpin                : (rest...)->
      KD.remote.api.SocialChannel.unpinMessage rest...
    follow               : (rest...)->
      KD.remote.api.SocialChannel.follow rest...
    unfollow             : (rest...)->
      KD.remote.api.SocialChannel.unfollow rest...
    fetchFollowedChannels: (rest...)->
      channelApiChannelsResFunc 'fetchFollowedChannels', rest...
