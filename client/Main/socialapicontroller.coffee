class SocialApiController extends KDController
  constructor: (options = {}, data) ->
    super options, data

  getCurrentGroup = (callback)->
    groupsController = KD.getSingleton "groupsController"
    groupsController.ready =>
      callback  KD.getSingleton("groupsController").getCurrentGroup()

  fetchChannelActivity = (options, callback)->
    return callback {message: "Channel id is not set for request"} unless options.id
    getCurrentGroup (group)->
      options.groupName = group.slug
      {SocialChannel} = KD.remote.api
      SocialChannel.fetchActivity options, (err, result)->
        return callback err if err
        return callback null, mapActivities result

  fetchGroupActivity = (options, callback)->
    getCurrentGroup (group)->
      return callback {message: "Group doesnt have socialApiChannelId"} unless group.socialApiChannelId
      options.id        = group.socialApiChannelId
      options.groupName = group.slug
      {SocialChannel} = KD.remote.api
      SocialChannel.fetchActivity options, (err, result)->
        return callback err if err
        return callback null, mapActivities result

  fetchChannels = (options, callback)->
    getCurrentGroup (group)->
      options.groupName = group.slug
      {SocialChannel} = KD.remote.api
      SocialChannel.fetchChannels options, (err, result)->
        return callback err if err
        return callback null, mapChannel result

  channel:
    list: fetchChannels
    fetchActivity: fetchChannelActivity
    fetchGroupActivity: fetchGroupActivity

  messageApiFunc = (name, rest..., callback)->
    KD.remote.api.SocialMessage[name] rest..., (err, res)->
      return callback null, mapActivity res

  message:
   edit   :(rest...)-> messageApiFunc 'edit', rest...
   post   :(rest...)-> messageApiFunc 'post', rest...
   reply  :(rest...)-> messageApiFunc 'reply', rest...
   delete :(rest...)-> KD.remote.api.SocialMessage.delete rest...
   like   :(rest...)-> KD.remote.api.SocialMessage.like rest...
   unlike :(rest...)-> KD.remote.api.SocialMessage.unlike rest...

  mapActivities = (messages)->
    # if no result, no need to do something
    return messages unless messages
    # get messagees from result set if they are not at the first level
    messages = messages.messageList if messages.messageList
    messages = [].concat(messages);
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

  mapChannel = (channels)->
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
