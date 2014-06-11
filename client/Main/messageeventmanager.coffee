class MessageEventManager extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @messages = {}


  bindListeners: (message) ->

    @messages[message.getId()] = message

    message
      .on "InteractionAdded", @bound "addInteraction"
      .on "InteractionRemoved", @bound "removeInteraction"
      .on "ReplyAdded", @lazyBound "addReply", message
      .on "ReplyRemoved", @lazyBound "removeReply", message


  addInteraction: (event) ->

    {messageId, typeConstant} = event

    return  unless message = @messages[messageId]

    fn = @bound "add#{typeConstant.capitalize()}"
    KD.utils.defer => fn message, event


  removeInteraction: (event) ->

    {messageId, typeConstant} = event

    return  unless message = @messages[messageId]

    fn = @bound "remove#{typeConstant.capitalize()}"
    KD.utils.defer => fn message, event


  addLike: (message, {accountOldId, count}) ->

    {like} = message.interactions

    like.actorsCount = count
    like.actorsPreview.unshift accountOldId  if accountOldId not in like.actorsPreview
    like.isInteracted = yes  if KD.whoami().getId() is accountOldId

    message.emit "LikeAdded"
    message.emit "update"


  removeLike: (message, {accountOldId, count}) ->

    {like} = message.interactions

    like.actorsCount   = count
    like.actorsPreview = like.actorsPreview.filter (id) -> id isnt accountOldId

    like.isInteracted = no  if KD.whoami().getId() is accountOldId

    message.emit "LikeRemoved"
    message.emit "update"


  addReply: (message, plain) ->

    reply = KD.singleton("socialapi").message.revive plain

    message.replies.push reply
    message.repliesCount++

    message.emit "AddReply", reply
    message.emit "update"


  removeReply: (message, {replyId}) ->

    for item in message.replies
      reply = item  if replyId is item.getId()

    message.replies = message.replies.filter (reply) -> reply.getId() isnt replyId
    message.repliesCount--

    message.emit "RemoveReply", reply
    message.emit "update"
