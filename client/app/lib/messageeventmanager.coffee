remote = require('./remote').getInstance()
getMessageOwner = require './util/getMessageOwner'
filterTrollActivity = require './util/filterTrollActivity'
whoami = require './util/whoami'
kd = require 'kd'
KDObject = kd.Object
Encoder = require 'htmlencode'
MongoOp = require 'bongo-client/node_modules/mongoop'

module.exports = class MessageEventManager extends KDObject

  constructor: (options = {}, data) ->

    super options, data

    kd.singletons.realtime.subscribeMessage data, (err, messageChannel) =>

      return kd.warn err  if err

      messageChannel
        .on 'InteractionAdded', @bound 'addInteraction'
        .on 'InteractionRemoved', @bound 'removeInteraction'
        .on 'ReplyAdded', @bound 'addReply'
        .on 'ReplyRemoved', @bound 'removeReply'
        .on 'updateInstance', @bound 'updateMessage'


  addInteraction: (event) ->

    {accountOldId} = event
    remote.cacheable "JAccount", accountOldId, (err, owner) =>
      return kd.error err  if err
      return kd.error "Account not found" unless owner
      return if filterTrollActivity owner

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
    like.isInteracted = yes  if whoami().getId() is accountOldId

    message.emit "LikeAdded"
    message.emit "update"


  removeLike: (options) ->

    {accountOldId, count} = options

    message = @getData()

    {like} = message.interactions
    like.actorsCount = count
    like.actorsPreview = like.actorsPreview.filter (id) -> id isnt accountOldId

    like.isInteracted = no  if whoami().getId() is accountOldId

    message.emit "LikeRemoved"
    message.emit "update"


  addReply: (plain) ->

    message = @getData()

    return  if message.replyIds[plain.message.id]

    reply = kd.singletons.socialapi.message.revive plain

    getMessageOwner reply, (err, owner) =>

      return kd.error err  if err

      return  if filterTrollActivity owner

      return  unless kd.singletons.socialapi.isFromOtherBrowser plain

      @addMessageReply message, reply


  addMessageReply: require 'activity/mixins/addmessagereply'


  removeReply: (options) ->

    {replyId} = options

    message = @getData()

    for item in message.replies
      reply = item  if replyId is item.getId()

    # when the comment does not appear on the screen, no need to send a 'RemoveReply' event
    if reply
      message.replies = message.replies.filter (reply) -> reply.getId() isnt replyId
      message.repliesCount--
      message.emit "RemoveReply", reply


    message.emit "update"


  updateMessage: (data) ->
    message = @getData()

    new MongoOp(data).applyTo message

    message.body = Encoder.XSSEncode message.body
    message.emit 'update'
