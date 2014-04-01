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
