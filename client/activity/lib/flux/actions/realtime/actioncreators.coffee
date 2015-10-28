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
    # FIXME: we need to find a better way to skip handling this case
    # ignore update if it is sent within message 'updateInstance' event,
    # in this case updatedKeys is not empty
    return  if updatedKeys

    channel = kd.singletons.socialapi.retrieveCachedItemById channelId
    dispatch actions.LOAD_MESSAGE_SUCCESS, { channelId, message, channel }

bindNotificationEvents = ->

  { reactor, socialapi } = kd.singletons

  # create specialized functions for dispatching into reactor. These functions
  # will be bound to the reactor instance that is passed.
  _dispatchFn = _createUnreadCountDispatchFn reactor
  _loadMessageFn = _createLoadMessageFn reactor

  kd.singletons.notificationController
    .on 'MessageAddedToChannel', (payload) ->
      { channel, channelMessage } = payload

      # TODO: FIXME
      # The reason we are doing these extra fetches is that right now backend
      # doesn't send us extra information about channel (it already shouldn't).
      # But for private messages the events from `SocialChannel` instance
      # itself is not arriving to participants. So we are making sure that
      # everything is in place before doing anything. This will be fixed once
      # instance events of `SocialChannel` instances for private messages are
      # fixed. ~Umut
      socialapi.channel.byId { id: channel.id }, (err, _channel) ->
        return  if err

        bindChannelEvents _channel
        socialapi.message.byId { id: channelMessage.id }, (err, _message) ->
          return  if err

          bindMessageEvents _message
          _loadMessageFn { channel, channelMessage: _message }
          _dispatchFn { unreadCount: payload.unreadCount, channel }

    .on 'MessageRemovedFromChannel', (payload) ->
      { channel, channelMessage, unreadCount } = payload
      dispatch actions.REMOVE_MESSAGE_SUCCESS, { messageId: channelMessage.id }
      _dispatchFn { unreadCount, channel }

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


###*
 * Takes a dispatcher and returns a function that will dispatch a unread count
 * event to that dispatcher.
 *
 * @param {KodingFluxReactor} _reactor
 * @param {function}
###
_createUnreadCountDispatchFn = (_reactor) -> ({unreadCount, channel}) ->
  _reactor.dispatch actions.SET_CHANNEL_UNREAD_COUNT,
    unreadCount : unreadCount
    channelId   : channel.id


###*
 * Takes a dispatcher and returns a function that will dispatch a load message
 * event to that dispatcher.
 *
 * @param {KodingFluxReactor} _reactor
 * @param {function}
###
_createLoadMessageFn = (_reactor) -> (payload) ->
  {channel, channelMessage} = payload

  dispatch actions.LOAD_MESSAGE_SUCCESS,
    channel   : channel
    channelId : channel.id
    message   : channelMessage

  return payload


module.exports = {
  bindChannelEvents
  bindMessageEvents
  bindNotificationEvents
}
