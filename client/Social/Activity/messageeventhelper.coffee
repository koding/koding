class MessageEventHelper extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @messages = {}


  bindListeners: (message) ->

    @messages[message.getId()] = message

    message
      .on "InteractionAdded", @bound "addInteraction"
      .on "InteractionRemoved", @bound "removeInteraction"


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

    message.emit "LikeAdded"
    message.emit "update"


  removeLike: (message, {accountOldId, count}) ->

    {like} = message.interactions

    like.actorsCount   = count
    like.actorsPreview = like.actorsPreview.filter (id) -> id isnt accountOldId

    message.emit "LikeRemoved"
    message.emit "update"


  addReply: (message, plain) ->

    reply = KD.singleton("socialapi").message.revive plain

    message.replies.push reply
    message.repliesCount++

    message.emit "AddReply", reply
    message.emit "update"
