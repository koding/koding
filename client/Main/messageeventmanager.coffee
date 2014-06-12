class MessageEventManager extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    data
      .on "InteractionAdded", @bound "addInteraction"
      .on "InteractionRemoved", @bound "removeInteraction"
      .on "ReplyAdded", @bound "addReply"
      .on "ReplyRemoved", @bound "removeReply"


  addInteraction: (event) ->

    {typeConstant} = event
    fn = @bound "add#{typeConstant.capitalize()}"
    fn event


  removeInteraction: (event) ->

    {typeConstant} = event
    fn = @bound "remove#{typeConstant.capitalize()}"
    fn event


  addLike: ({accountOldId, count}) ->

    message = @getData()

    {like} = message.interactions

    like.actorsCount = count
    like.actorsPreview.unshift accountOldId  if accountOldId not in like.actorsPreview
    like.isInteracted = yes  if KD.whoami().getId() is accountOldId

    message.emit "LikeAdded"
    message.emit "update"


  removeLike: ({accountOldId, count}) ->

    message = @getData()

    {like} = message.interactions

    like.actorsCount   = count
    like.actorsPreview = like.actorsPreview.filter (id) -> id isnt accountOldId

    like.isInteracted = no  if KD.whoami().getId() is accountOldId

    message.emit "LikeRemoved"
    message.emit "update"


  addReply: (plain) ->

    reply = KD.singleton("socialapi").message.revive plain

    message = @getData()
    message.replies.push reply
    message.repliesCount++

    message.emit "AddReply", reply
    message.emit "update"


  removeReply: ({replyId}) ->

    message = @getData()

    for item in message.replies
      reply = item  if replyId is item.getId()

    message.replies = message.replies.filter (reply) -> reply.getId() isnt replyId
    message.repliesCount--

    message.emit "RemoveReply", reply
    message.emit "update"
