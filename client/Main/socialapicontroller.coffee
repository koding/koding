class SocialApiController extends KDController
  constructor: (options = {}, data) ->
    super options, data
    @groupsController = KD.getSingleton "groupsController"

  getCurrentGroup: (callback)->
    @groupsController.ready =>
      callback @groupsController.getCurrentGroup()

  fetchChannelActivity:(options, callback)->
    return callback {message: "Channel id is not set for request"} unless options.id
    @getCurrentGroup (group)=>
      options.groupName = group.slug
      {SocialChannel} = KD.remote.api
      SocialChannel.fetchActivity options, (err, result)=>
        return callback err if err
        return callback null, @mapActivity result

  fetchGroupActivity:(options, callback)->
    @getCurrentGroup (group)=>
      return callback {message: "Group doesnt have socialApiChannelId"} unless group.socialApiChannelId
      options.id        = group.socialApiChannelId
      options.groupName = group.slug
      {SocialChannel} = KD.remote.api
      SocialChannel.fetchActivity options, (err, result)=>
        return callback err if err
        return callback null, @mapActivity result

  fetchChannels:(options, callback)->
    @getCurrentGroup (group)=>
      return callback { message: "Group doesnt have socialApiChannelId" } unless group.socialApiChannelId
      options.id = group.socialApiChannelId
      {SocialChannel} = KD.remote.api
      SocialChannel.fetchActivity options, (err, result)=>
        return callback err if err
        return callback null, @mapActivity result


  mapActivity:(result)->
    messages = result.messageList
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

  mapChannel:(channels)->
    revivedChannels = []
    {SocialChannel} = KD.remote.api
    for channel in channels
      c = new SocialChannel channel
      c.on "MessageReplySaved", log
      c.on "update", log

      revivedChannels.push c

    return revivedChannels
