kd = require 'kd'
actions = require '../actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

_cache = channel: {}, message: {}

bindChannelEvents = (channel) ->

  return  if _cache.channel[channel.id]

  _cache.channel[channel.id] = yes

  kd.singletons.socialapi.onChannelReady channel, ->

    channel.on 'MessageAdded', (message) ->
      bindMessageEvents message

      _channel = kd.singletons.socialapi.retrieveCachedItemById message.initialChannelId
      dispatch actions.LOAD_MESSAGE_SUCCESS,
        channel   : _channel
        channelId : _channel.id
        message   : message

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
    dispatch actions.LOAD_COMMENT_SUCCESS, { messageId, comment }

  message.on 'RemoveReply', (comment) ->
    dispatch actions.REMOVE_MESSAGE_SUCCESS, { messageId: comment.id }

  message.on 'update', (updatedKeys) ->
    # FIXME: we need to find a better way to skip handle this case
    # ignore update if it is sent within message 'updateInstance' event,
    # in this case updatedKeys is not empty
    return  if updatedKeys

    channel = kd.singletons.socialapi.retrieveCachedItemById channelId
    dispatch actions.LOAD_MESSAGE_SUCCESS, { channelId, message, channel }

bindNotificationEvents = ->

  _dispatchFn = _createUnreadCountDispatchFn kd.singletons.reactor

  kd.singletons.notificationController
    .on 'MessageAddedToChannel', _dispatchFn
    .on 'MessageRemovedFromChannel', _dispatchFn
    .on 'RemovedFromChannel', _dispatchFn
    .on 'ReplyAdded', _dispatchFn
    .on 'ParticipantUpdated', _dispatchFn
    .on 'MessageListUpdated', _dispatchFn
    .on 'AddedToChannel', (options) ->
      channel = kd.singletons.socialapi.channel.revive options
      actionType = if channel.typeConstant in ['privatemessage', 'bot', 'collaboration']
      then actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS
      else actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS
      payload = { channel, channelId: channel.id }
      dispatch actionType, payload

      { unreadCount } = channel

      _dispatchFn { unreadCount, channel }


_createUnreadCountDispatchFn = (_reactor) -> ({unreadCount, channel}) ->
  _reactor.dispatch actions.SET_CHANNEL_UNREAD_COUNT,
    unreadCount : unreadCount
    channelId   : channel.id

  _reactor.dispatch actions.UNSET_LOADED_WITH_SCROLL, channelId: channel.id


module.exports = {
  bindChannelEvents
  bindMessageEvents
  bindNotificationEvents
}
