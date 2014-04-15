class SocialApiController extends KDController
  constructor: (options = {}, data) ->
    super options, data

  getCurrentGroup = (callback)->
    groupsController = KD.getSingleton "groupsController"
    groupsController.ready ->
      callback  KD.getSingleton("groupsController").getCurrentGroup()

  fetchChannelActivity = (options, callback)->
    unless options.id
      return callback {message: "Channel id is not set for request"}
    getCurrentGroup (group)->
      options.groupName = group.slug
      channelApiActivitiesResFunc "fetchActivity", options, callback

  fetchGroupActivity = (options, callback)->
    getCurrentGroup (group)->
      unless group.socialApiChannelId
        return callback {message: "Group doesnt have socialApiChannelId"}
      options.id        = group.socialApiChannelId
      options.groupName = group.slug
      channelApiActivitiesResFunc "fetchActivity", options, callback

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
      return callback null, mapActivity res

  channelApiActivitiesResFunc = (name, rest..., callback)->
    KD.remote.api.SocialChannel[name] rest..., (err, result)->
      return callback err if err
      return callback null, mapActivities result

  channelApiChannelsResFunc = (name, rest..., callback)->
    KD.remote.api.SocialChannel[name] rest..., (err, result)->
      return callback err if err
      return callback null, mapChannels result

  mapActivities = (messages)->
    # if no result, no need to do something
    return messages unless messages
    # get messagees from result set if they are not at the first level
    messages = messages.messageList if messages.messageList
    messages = [].concat(messages)
    revivedMessages = []
    {SocialMessage} = KD.remote.api
    for message in messages
      m = new SocialMessage message.message
      m._id = message.message.id
      m.meta = {}
      m.meta.likes = message.interactions.length or 0
      m.meta.createdAt = message.message.createdAt
      m.replies = message.replies
      m.repliesCount = message.replies.length or 0
      m.interactions = message.interactions

      m.on "MessageReplySaved", log
      m.on "update", log

      revivedMessages.push m

    return revivedMessages

  mapActivity = (message)->
    # if no result, no need to do something
    return message unless message

    {SocialMessage} = KD.remote.api
    m = new SocialMessage message
    m._id = message.id
    m.meta = {}
    m.meta.createdAt = message.createdAt

    return m

  mapChannels = (channels)->
    revivedChannels = []
    {SocialChannel} = KD.remote.api
    for channel in channels
      c = new SocialChannel channel
      # until we create message id's
      # programmatically
      # inorder to make realtime updates work
      # we need `channel-` here
      c._id = "channel-#{channel.id}"

      revivedChannels.push c

    return revivedChannels

  message:
    edit   :(rest...)-> messageApiMessageResFunc 'edit', rest...
    post   :(rest...)-> messageApiMessageResFunc 'post', rest...
    reply  :(rest...)-> messageApiMessageResFunc 'reply', rest...
    delete :(rest...)-> KD.remote.api.SocialMessage.delete rest...
    like   :(rest...)-> KD.remote.api.SocialMessage.like rest...
    unlike :(rest...)-> KD.remote.api.SocialMessage.unlike rest...

  channel:
    list               : fetchChannels
    fetchActivity      : fetchChannelActivity
    fetchGroupActivity : fetchGroupActivity
    fetchPopularTopics : fetchPopularTopics
    listPinnedMessages : (rest...)->
      channelApiActivitiesResFunc 'listPinnedMessages', rest...
    pin                : (rest...)->
      KD.remote.api.SocialChannel.pinMessage rest...
    unpin              : (rest...)->
      KD.remote.api.SocialChannel.unpinMessage rest...
    follow             : (rest...)->
      KD.remote.api.SocialChannel.follow rest...
    unfollow           : (rest...)->
      KD.remote.api.SocialChannel.unfollow rest...
