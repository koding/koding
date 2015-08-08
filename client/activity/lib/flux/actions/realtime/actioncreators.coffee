kd = require 'kd'
actions = require '../actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

bindChannelEvents = (channel) ->

  kd.singletons.socialapi.onChannelReady channel, ->

    channel.on 'MessageAdded', (message) ->
      bindMessageEvents message
      dispatch actions.LOAD_MESSAGE_SUCCESS, { channel, message, channelId: channel.id }

    channel.on 'MessageRemoved', (message) ->
      dispatch actions.REMOVE_MESSAGE_SUCCESS, { messageId: message.id }


bindMessageEvents = (message) ->

  messageId = message.id
  { initialChannelId: channelId } = message

  message.on 'LikeAdded', ({ accountId }) ->
    dispatch actions.LIKE_MESSAGE_SUCCESS, { userId: accountId, messageId }

  message.on 'LikeRemoved', ({ accountId }) ->
    dispatch actions.UNLIKE_MESSAGE_SUCCESS, { userId: accountId, messageId }

  message.on 'AddReply', (comment) ->
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
