remote = require('./remote').getInstance()
getMessageOwner = require './util/getMessageOwner'
filterTrollActivity = require './util/filterTrollActivity'
whoami = require './util/whoami'
kd = require 'kd'
KDObject = kd.Object

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

    reply = kd.singletons.socialapi.message.revive plain

    getMessageOwner reply, (err, owner) =>

      return kd.error err  if err
      return  if filterTrollActivity owner

      message = @getData()
      message.replies.push reply
      message.repliesCount++

      plain.message.messageId = message.id

      return  unless kd.singletons.socialapi.isFromOtherBrowser plain

      message.emit "AddReply", reply
      message.emit "update"


  removeReply: (options) ->

    {replyId} = options

    message = @getData()

    return  unless kd.singletons.socialapi.isFromOtherBrowser message

    for item in message.replies
      reply = item  if replyId is item.getId()

    # when the comment does not appear on the screen, no need to send a 'RemoveReply' event
    if reply
      message.replies = message.replies.filter (reply) -> reply.getId() isnt replyId
      message.repliesCount--
      message.emit "RemoveReply", reply


    message.emit "update"

