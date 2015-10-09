kd = require 'kd'
actions = require '../actiontypes'
getGroup = require 'app/util/getGroup'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

_cache = channel: {}, message: {}

bindChannelEvents = (channel) ->

  return  if _cache.channel[channel.id]

  _cache.channel[channel.id] = yes

  kd.singletons.socialapi.onChannelReady channel, ->

    channel.on 'MessageAdded', (message) ->
      bindMessageEvents message
      dispatch actions.LOAD_MESSAGE_SUCCESS, { channel, message, channelId: channel.id }

    channel.on 'MessageRemoved', (message) ->
      dispatch actions.REMOVE_MESSAGE_SUCCESS, { messageId: message.id }


bindMessageEvents = (message) ->

  messageId = message.id
  { initialChannelId: channelId } = message

  return  if _cache.message[messageId]

  _cache.message[messageId] = yes

  message.on 'LikeAdded', ({ accountId: userId }) ->
    dispatch actions.LIKE_MESSAGE_SUCCESS, { userId, messageId }

  message.on 'LikeRemoved', ({ accountId: userId }) ->
    dispatch actions.UNLIKE_MESSAGE_SUCCESS, { userId, messageId }

  message.on 'AddReply', (comment) ->
    if getGroup().socialApiChannelId is channelId
      channel = kd.singletons.socialapi.retrieveCachedItemById channelId
      dispatch actions.LOAD_MESSAGE_SUCCESS, { message: comment, channelId, channel }
    dispatch actions.LOAD_COMMENT_SUCCESS, { messageId, comment }

  message.on 'RemoveReply', (comment) ->
    dispatch actions.REMOVE_MESSAGE_SUCCESS, { messageId: comment.id }

  message.on 'update', ->
    channel = kd.singletons.socialapi.retrieveCachedItemById channelId
    dispatch actions.LOAD_MESSAGE_SUCCESS, { channelId, message, channel }


module.exports = {
  bindChannelEvents
  bindMessageEvents
}
