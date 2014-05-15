class MessageEventHelper extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    @messages = {}


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
