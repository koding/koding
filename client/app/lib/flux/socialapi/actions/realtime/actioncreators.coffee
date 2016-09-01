kd                   = require 'kd'
AppFlux              = require 'app/flux'
actions              = require '../actiontypes'
isPublicChannel      = require 'app/util/isPublicChannel'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

_cache = { channel: {}, message: {} }

bindChannelEvents = (channel) ->

  return  if _cache.channel[channel.id]
  return  if channel.typeConstant is 'group'

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

    channel.on 'RemovedFromChannel', (account) ->

      channelId = channel.id
      accountId = account._id

      dispatch actions.REMOVE_PARTICIPANT_FROM_CHANNEL, { channelId, accountId }

    channel.on 'ChannelUpdated', (channel) ->
      dispatch actions.LOAD_CHANNEL_SUCCESS, { channelId: channel.id, channel }


    channel.on 'AddedToChannel', (account) ->

      userId    = account._id
      channelId = channel.id

      AppFlux.actions.user.loadAccount(userId).then ->
        dispatch actions.ADD_PARTICIPANTS_TO_CHANNEL_SUCCESS, { channelId, userId }


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
      { channel : { id, name, typeConstant }, channelMessage, unreadCount } = payload

      # TODO: FIXME
      # The reason we are doing these extra fetches is that right now backend
      # doesn't send us extra information about channel (it already shouldn't).
      # But for private messages the events from `SocialChannel` instance
      # itself is not arriving to participants. So we are making sure that
      # everything is in place before doing anything. This will be fixed once
      # instance events of `SocialChannel` instances for private messages are
      # fixed. ~Umut
      socialapi.channel.byId { id }, (err, channel) ->
        return  if err

        bindChannelEvents channel

        actionType = if isPublicChannel channel
        then actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS
        else actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS

        dispatch actionType, { channel, channelId: channel.id }
        _dispatchFn { unreadCount, channel }

        socialapi.message.byId { id: channelMessage.id }, (err, message) ->
          return  if err

          bindMessageEvents message
          _loadMessageFn { channel, channelMessage: message }

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

      { message } = options.lastMessage


_isChannelInitiationEvent = (message) ->
  systemType = message.payload?.systemType
  return systemType and systemType is 'initiate'


bindAppBadgeNotifiers = ->

  # removed badge notifications
  # until we bind stack notifications - SY
  return
  return  unless window.nodeRequire

  { ipcRenderer } = nodeRequire 'electron'
  { getters }     = require 'app/flux/socialapi'

  calculateUnreads = (channels) ->
    channels      = channels.toJS()
    unreadPublic  = 0
    unreadPrivate = 0
    for id, channel of channels
      switch channel.typeConstant
        when 'topic'          then unreadPublic  += channel.unreadCount
        when 'privatemessage' then unreadPrivate += channel.unreadCount

    return ipcRenderer.send 'badge-reset'  if unreadPrivate + unreadPublic is 0

    ipcRenderer.send 'badge-unread'                      if unreadPublic
    ipcRenderer.send 'badge-unread', "#{unreadPrivate}"  if unreadPrivate

  kd.singletons.reactor.observe  getters.allChannels, calculateUnreads


###*
 * Takes a dispatcher and returns a function that will dispatch a unread count
 * event to that dispatcher.
 *
 * @param {KodingFluxReactor} _reactor
 * @param {function}
###
_createUnreadCountDispatchFn = (_reactor) -> ({ unreadCount, channel }) ->
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
  { channel, channelMessage } = payload

  dispatch actions.LOAD_MESSAGE_SUCCESS,
    channel   : channel
    channelId : channel.id
    message   : channelMessage

  return payload


module.exports = {
  bindChannelEvents
  bindMessageEvents
  bindNotificationEvents
  bindAppBadgeNotifiers
}
