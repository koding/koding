class MessageEventManager extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    KD.singletons.realtime.subscribeMessage data, (err, messageChannel) =>

      return warn err  if err

      messageChannel
        .on 'InteractionAdded', @bound 'addInteraction'
        .on 'InteractionRemoved', @bound 'removeInteraction'
        .on 'ReplyAdded', @bound 'addReply'
        .on 'ReplyRemoved', @bound 'removeReply'


  addInteraction: (event) ->

    {accountOldId} = event
    KD.remote.cacheable "JAccount", accountOldId, (err, owner) =>
      return error err  if err
      return error "Account not found" unless owner
      return if KD.filterTrollActivity owner

      {typeConstant} = event
      fn = @bound "add#{typeConstant.capitalize()}"
      fn event


  removeInteraction: (event) ->

    {typeConstant} = event
    fn = @bound "remove#{typeConstant.capitalize()}"
    fn event


  addLike: (options) ->

    {accountOldId, count} = options

    message = @getData()

    {like} = message.interactions

    like.actorsCount = count
    like.actorsPreview.unshift accountOldId  if accountOldId not in like.actorsPreview
    like.isInteracted = yes  if KD.whoami().getId() is accountOldId

    message.emit "LikeAdded"
    message.emit "update"


  removeLike: (options) ->

    {accountOldId, count} = options

    message = @getData()

    {like} = message.interactions
    like.actorsCount = count
    like.actorsPreview = like.actorsPreview.filter (id) -> id isnt accountOldId

    like.isInteracted = no  if KD.whoami().getId() is accountOldId

    message.emit "LikeRemoved"
    message.emit "update"


  addReply: (plain) ->

    # revive adds the reply to cache. if reply is already there, it means it is shown
    # on the screen
    # TODO this code gone mad. Need a better caching mechanism
    return  if KD.singletons.socialapi._cache[plain.message.typeConstant]?[plain.message.id]

    reply = KD.singletons.socialapi.message.revive plain

    KD.getMessageOwner reply, (err, owner) =>

      return error err  if err
      return  if KD.filterTrollActivity owner

      message = @getData()
      message.replies.push reply
      message.repliesCount++

      plain.message.messageId = message.id

      return  unless KD.singletons.socialapi.isFromOtherBrowser plain

      message.emit "AddReply", reply
      message.emit "update"


  removeReply: (options) ->

    {replyId} = options

    message = @getData()

    return  unless KD.singletons.socialapi.isFromOtherBrowser message

    for item in message.replies
      reply = item  if replyId is item.getId()

    # when the comment does not appear on the screen, no need to send a 'RemoveReply' event
    if reply
      message.replies = message.replies.filter (reply) -> reply.getId() isnt replyId
      message.repliesCount--
      message.emit "RemoveReply", reply


    message.emit "update"

