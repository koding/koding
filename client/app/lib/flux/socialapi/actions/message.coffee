_                      = require 'lodash'
kd                     = require 'kd'
whoami                 = require 'app/util/whoami'
actionTypes            = require './actiontypes'
generateFakeIdentifier = require 'app/util/generateFakeIdentifier'
messageHelpers         = require '../helpers/message'
realtimeActionCreators = require './realtime/actioncreators'
embedlyHelpers         = require '../helpers/embedly'
Promise                = require 'bluebird'
mergeEmbedPayload      = require 'app/util/mergeEmbedPayload'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...

###*
 * Action to load messages of channel with given channelId.
 *
 * @param {string} channelId
###
loadMessages = (channelId, options = {}) ->

  options.limit ?= 50
  { socialapi } = kd.singletons
  { LOAD_MESSAGES_BEGIN, LOAD_MESSAGES_FAIL,
    LOAD_MESSAGES_SUCCESS, LOAD_MESSAGE_SUCCESS
    SET_ALL_MESSAGES_LOADED, UNSET_ALL_MESSAGES_LOADED } = actionTypes

  dispatch LOAD_MESSAGES_BEGIN, { channelId, options }

  _options = _.assign {}, options, { id: channelId }

  new Promise (resolve, reject) ->
    socialapi.channel.fetchActivities _options, (err, messages) ->
      if err
        dispatch LOAD_MESSAGES_FAIL, { err, channelId }
        return reject err

      # clean load more markers of given messages first.
      # kd.utils.defer -> cleanLoaderMarkers channelId, messages

      channelMessages = kd.singletons.reactor.evaluate ['MessagesStore', channelId]

      limit = Math.max channelMessages?.size or 0, options.limit


      kd.utils.defer ->
        kd.singletons.reactor.batch ->
          for message in messages
            dispatchLoadMessageSuccess channelId, message

          dispatch LOAD_MESSAGES_SUCCESS, { channelId, messages }

          if messages.length < limit
            dispatch SET_ALL_MESSAGES_LOADED, { channelId }
        resolve { messages }


###*
 * An action creator to group load message action operations.
 * It wraps given message with realtimeActionCreators to transform realtime
 * events to flux actions.
 *
 * @param {string} channelId
 * @param {SocialMessage} message
 * @api private
###
dispatchLoadMessageSuccess = (channelId, message) ->

  channel = kd.singletons.socialapi.retrieveCachedItemById channelId

  realtimeActionCreators.bindMessageEvents message
  dispatch actionTypes.LOAD_MESSAGE_SUCCESS, { channelId, channel, message }

  message.replies.forEach (comment) ->
    dispatch actionTypes.LOAD_COMMENT_SUCCESS, { messageId: message.id, comment }
    realtimeActionCreators.bindMessageEvents comment


###*
 * An empty promise resolver. It's being used for default cases that returns
 * promise to keep API consistent.
###
emptyPromise = new Promise (resolve) -> resolve {}


###*
 * Loads the message with given message id. It doesn't fetch if there is a
 * fetch going on with given messageId.
 *
 * @param {string} messageId
###
loadMessage = do (fetchingMap = {}) -> (messageId) ->

  return emptyPromise  unless messageId

  # if there is already a fetch going on for that message just return an empty
  # Promise.
  return emptyPromise  if fetchingMap[messageId]

  # mark this message id as being fetched.
  fetchingMap[messageId] = yes

  { socialapi } = kd.singletons
  { LOAD_MESSAGE_BEGIN
    LOAD_MESSAGE_FAIL } = actionTypes

  dispatch LOAD_MESSAGE_BEGIN, { messageId }

  socialapi.message.byId { id: messageId }, (err, message) ->
    if err
      dispatch LOAD_MESSAGE_FAIL, { err, messageId }
      return

    dispatchLoadMessageSuccess message.initialChannelId, message
    # unmark this message for being fetched.
    # loadComments message.id
    fetchingMap[messageId] = no

    return { message }


###*
 * Ensures a message is there and it also has enough surrounding message
 * siblings so that scrolling into a single post would make much more sense.
 *
 * @param {string} messageId
 * @return {Promise}
###
ensureMessage = (messageId) ->

  { reactor } = kd.singletons

  loadMessage(messageId).then ({ message }) ->
    channelId = message.initialChannelId
    loadMessages(channelId, { from: message.createdAt }).then ({ messages }) ->
      messagesBefore = reactor.evaluate ['MessagesStore']
      loadMessages(channelId, { from: message.createdAt, sortOrder: 'ASC' }).then ({ messages }) ->
        [..., last] = messages
        return { message }  unless last

        # put a loader marker only if this message was not here before.
        unless messagesBefore.has last.id
          putLoaderMarker channelId, last.id, { position: 'after', autoload: no }

        return { message }

###*
 * Action to put a loader marker to a certain position to a channel.
 *
 * @param {string} channelId
 * @param {string} messageId
 * @param {object} options
 * @param {string} options.position - either 'before' or 'after'
 * @param {boolean} options.autoload
###
putLoaderMarker = (channelId, messageId, options) ->

  dispatch actionTypes.ACTIVATE_LOADER_MARKER,
    channelId : channelId
    messageId : messageId
    position  : options.position
    autoload  : options.autoload


###*
 * Removes a message's loader marker in a channel with given options.
 *
 * @param {string} channelId
 * @param {string} messageId
 * @param {object} options
 * @param {string} options.position - either 'before' or after
###
removeLoaderMarker = (channelId, messageId, options) ->

  dispatch actionTypes.DEACTIVATE_LOADER_MARKER, { channelId, messageId, position: options.position }


###*
 * Removes given messages' loader markers in that channel. Both 'before' and
 * 'after' markers.
 *
 * @param {string} channelId
 * @param {Array.<SocialMessage>} messages
###
cleanLoaderMarkers = (channelId, messages) ->

  kd.singletons.reactor.batch ->
    messages.forEach (message) ->
      removeLoaderMarker channelId, message.id, { position: 'before' }
      removeLoaderMarker channelId, message.id, { position: 'after' }


###*
 * Action to load message with given slug.
 *
 * @param {string} slug
###
loadMessageBySlug = (slug) ->

  { socialapi } = kd.singletons
  { LOAD_MESSAGE_BY_SLUG_BEGIN
    LOAD_MESSAGE_BY_SLUG_FAIL
    LOAD_MESSAGE_SUCCESS } = actionTypes

  dispatch LOAD_MESSAGE_BY_SLUG_BEGIN, { slug }

  socialapi.message.bySlug { slug }, (err, message) ->
    if err
      dispatch LOAD_MESSAGE_BY_SLUG_FAIL, { err, slug }
      return

    dispatchLoadMessageSuccess message.initialChannelId, message
    # loadComments message.id


###*
 * Action to create a message.
 *
 * @param {string} channelId
 * @param {string} body
 * @param {object=}
###
createMessage = (channelId, body, payload) ->

  payload = messageHelpers.sanitizePayload payload

  { socialapi } = kd.singletons
  { CREATE_MESSAGE_BEGIN
    CREATE_MESSAGE_FAIL
    CREATE_MESSAGE_SUCCESS } = actionTypes

  clientRequestId = generateFakeIdentifier Date.now()

  dispatch CREATE_MESSAGE_BEGIN, {
    channelId, clientRequestId, body
  }

  # since this action works for all types of channel, we need to specify the
  # type when we are posting.
  channel = socialapi.retrieveCachedItemById channelId
  type    = channel.typeConstant

  # the reason we are doing this is to sync socialApiController cache data
  # FIXME: remove this after removing socialApiController
  channel.unreadCount = 0

  fetchEmbedPayload { body, payload }, (err, embedPayload) ->
    return  if err

    payload = mergeEmbedPayload payload, embedPayload

    options = { channelId, clientRequestId, body, payload, type }
    socialapi.message.sendPrivateMessage options, (err, [channel]) ->
      if err
        dispatch CREATE_MESSAGE_FAIL, {
          err, channelId, clientRequestId
        }
        return

      { lastMessage: message } = channel

      realtimeActionCreators.bindMessageEvents message
      dispatch CREATE_MESSAGE_SUCCESS, {
        message, channelId, clientRequestId, channel
      }


###*
 * Remove a message.
 *
 * @param {string} messageId
###
removeMessage = (messageId) ->

  { socialapi } = kd.singletons
  { REMOVE_MESSAGE_BEGIN
    REMOVE_MESSAGE_FAIL
    REMOVE_MESSAGE_SUCCESS } = actionTypes

  dispatch REMOVE_MESSAGE_BEGIN, { messageId }

  socialapi.message.delete { id: messageId }, (err) ->
    if err
      dispatch REMOVE_MESSAGE_FAIL, { err, messageId }
      return

    dispatch REMOVE_MESSAGE_SUCCESS, { messageId }



###*
 * Like a message.
 *
 * @param {string} messageId
###
likeMessage = (messageId) ->

  { socialapi } = kd.singletons
  { LIKE_MESSAGE_BEGIN
    LIKE_MESSAGE_FAIL
    LIKE_MESSAGE_SUCCESS } = actionTypes

  userId = whoami()._id

  dispatch LIKE_MESSAGE_BEGIN, { messageId, userId }

  socialapi.message.like { id: messageId }, (err) ->
    if err
      dispatch LIKE_MESSAGE_FAIL, { err, messageId, userId }
      return

    socialapi.message.listLikers { id: messageId }, (err, likers) ->
      kd.singletons.reactor.batch ->
        likers.forEach (id) ->
          dispatch LIKE_MESSAGE_SUCCESS, { userId: id, messageId }


###*
 * Unlike a message.
 *
 * @param {string} messageId
###
unlikeMessage = (messageId) ->

  { socialapi } = kd.singletons
  { UNLIKE_MESSAGE_BEGIN
    UNLIKE_MESSAGE_FAIL
    UNLIKE_MESSAGE_SUCCESS } = actionTypes

  userId = whoami()._id

  dispatch UNLIKE_MESSAGE_BEGIN, { messageId, userId }

  socialapi.message.unlike { id: messageId }, (err, message) ->
    if err
      dispatch UNLIKE_MESSAGE_FAIL, { err, messageId }
      return

    dispatch UNLIKE_MESSAGE_SUCCESS, { messageId, userId }


###*
 * Edit message.
 *
 * @param {string} messageId
 * @param {string} body
 * @param {object=} payload
###
editMessage = (messageId, body, payload) ->

  { socialapi } = kd.singletons
  { EDIT_MESSAGE_BEGIN
    EDIT_MESSAGE_SUCCESS
    EDIT_MESSAGE_FAIL } = actionTypes

  messages = kd.singletons.reactor.evaluate ['MessagesStore']
  message  = messages.get messageId

  isEmbedPayloadDisabled = message.get '__isEmbedPayloadDisabled'

  unless payload
    payload = message.get('__editedPayload') ? message.get 'payload'
    payload = payload.toJS()

  payload = messageHelpers.sanitizePayload payload

  dispatch EDIT_MESSAGE_BEGIN, { messageId, body, payload }

  callback = (err, embedPayload) ->
    payload = mergeEmbedPayload payload, embedPayload

    socialapi.message.edit { id: messageId, body, payload }, (err, message) ->
      if err
        dispatch EDIT_MESSAGE_FAIL, { err, messageId }
        return

      realtimeActionCreators.bindMessageEvents message
      dispatch EDIT_MESSAGE_SUCCESS, { message, messageId }

  if isEmbedPayloadDisabled
    callback null, payload
  else
    fetchEmbedPayload { body, payload }, callback


###*
 * Action to load comments with given options.
 *
 * @param {string} messageId
 * @param {string} from
 * @param {number} limit
###
loadComments = (messageId, options = {}) ->

  options.limit ?= 25
  { socialapi } = kd.singletons
  { LOAD_COMMENTS_BEGIN
    LOAD_COMMENTS_FAIL
    LOAD_COMMENTS_SUCCESS
    LOAD_COMMENT_SUCCESS } = actionTypes

  _options = _.assign {}, options, { messageId }

  dispatch LOAD_COMMENTS_BEGIN, _options

  socialapi.message.listReplies _options, (err, comments) ->
    if err
      dispatchData = _.assign {}, { err }, options
      dispatch LOAD_COMMENTS_FAIL, dispatchData
      return

    dispatch LOAD_COMMENTS_SUCCESS, { messageId }

    kd.singletons.reactor.batch ->
      comments.forEach (comment) ->
        realtimeActionCreators.bindMessageEvents comment
        dispatch LOAD_COMMENT_SUCCESS, { messageId, comment }


###*
 * Adds comment to given message.
 *
 * @param {string} messageId
 * @param {string} body
 * @param {object=} payload
###
createComment = (messageId, body, payload) ->

  payload = messageHelpers.sanitizePayload payload

  { socialapi } = kd.singletons
  { CREATE_COMMENT_BEGIN
    CREATE_COMMENT_FAIL
    CREATE_COMMENT_SUCCESS } = actionTypes

  clientRequestId = generateFakeIdentifier Date.now()

  dispatch CREATE_COMMENT_BEGIN, { messageId, clientRequestId, body }

  socialapi.message.reply { messageId, clientRequestId, body, payload }, (err, comment) ->
    if err
      dispatch CREATE_COMMENT_FAIL, { err, comment, clientRequestId }
      return

    addMessageReply = require 'app/mixins/addmessagereply'
    message         = socialapi.retrieveCachedItemById messageId
    realtimeActionCreators.bindMessageEvents comment
    addMessageReply message, comment
    dispatch CREATE_COMMENT_SUCCESS, { messageId, comment, clientRequestId }


###*
 * Changes selected message id.
 *
 * @param {string} messageId
###
changeSelectedMessage = (messageId) ->

  unless messageId
    return dispatch actionTypes.SET_SELECTED_MESSAGE_THREAD, { messageId: null }

  ensureMessage(messageId).then ({ message }) ->
    dispatch actionTypes.SET_SELECTED_MESSAGE_THREAD, { messageId }


###*
 * Change selected message with given slug.
 *
 * @param {string} slug
###
changeSelectedMessageBySlug = (slug) ->

  { SET_SELECTED_MESSAGE_THREAD_FAIL,
    SET_SELECTED_MESSAGE_THREAD } = actionTypes

  kd.singletons.socialapi.message.bySlug { slug }, (err, message) ->
    if err
      dispatch SET_SELECTED_MESSAGE_THREAD_FAIL, { err, slug }
      return

    dispatch SET_SELECTED_MESSAGE_THREAD, { messageId: message.id }


###*
 * Sets message edit mode
 *
 * @param {string} messageId
 * @param {string} channelId
###
setMessageEditMode = (messageId, channelId) ->

  { SET_MESSAGE_EDIT_MODE } = actionTypes
  dispatch SET_MESSAGE_EDIT_MODE, { messageId, channelId }


###*
 * Unsets message edit mode
 *
 * @param {string} messageId
 * @param {string} channelId
###
unsetMessageEditMode = (messageId, channelId, resetEditedPayload) ->

  { UNSET_MESSAGE_EDIT_MODE } = actionTypes
  dispatch UNSET_MESSAGE_EDIT_MODE, { messageId, channelId, resetEditedPayload }


###*
 * Fetches embed data by url extracted from message body
 * and calls callback when fetch is done
 * If extracted url and payload url are the same, fetch doesn't
 * happen and callback is called with payload data
 *
 * @param {object} messageData
 * @param {function} callback
###
fetchEmbedPayload = (messageData, callback = kd.noop) ->

  { body, payload } = messageData
  url = embedlyHelpers.extractUrl body
  return callback()  unless url
  return callback null, payload  if payload?.link_url is url

  fetchDataFromEmbedly url, callback


###*
 * Fetches embed data by given url and updates
 * edited message embed payload with received response
 * Does nothing if message is disabled for embed payload
 *
 * @param {string} messageId
 * @param {string} url
###
editEmbedPayloadByUrl = (messageId, url) ->

  { EDIT_MESSAGE_EMBED_PAYLOAD_BEGIN,
    EDIT_MESSAGE_EMBED_PAYLOAD_SUCCESS,
    EDIT_MESSAGE_EMBED_PAYLOAD_FAIL } = actionTypes

  messages = kd.singletons.reactor.evaluate ['MessagesStore']
  message  = messages.get messageId
  return  if message.get '__isEmbedPayloadDisabled'

  return dispatch EDIT_MESSAGE_EMBED_PAYLOAD_SUCCESS, { messageId }  unless url

  fetchDataFromEmbedly url, (err, embedPayload) ->
    return dispatch EDIT_MESSAGE_EMBED_PAYLOAD_FAIL, { messageId, err }  if err
    dispatch EDIT_MESSAGE_EMBED_PAYLOAD_SUCCESS, { messageId, embedPayload }


###*
 * Fetches data from embed.ly by given url, creates payload
 * from received response and calls callback with payload
 * or error if embed.ly request has failed
###
fetchDataFromEmbedly = (url, callback = kd.noop) ->

  options =
    maxWidth  : 600
    maxHeight : 450
    wmode     : 'transparent'

  { socialapi } = kd.singletons

  socialapi.message.fetchDataFromEmbedly url, options, (err, result) ->

    if err
      kd.log 'Embed.ly error!', err
      callback err
    else if result
      data    = result.first
      payload = embedlyHelpers.createMessagePayload data

    callback null, payload


###*
 * Disables embed payload for editing message
 *
 * @param {string} messageId
###
disableEditedEmbedPayload = (messageId) ->

  { DISABLE_EDITED_MESSAGE_EMBED_PAYLOAD } = actionTypes
  dispatch DISABLE_EDITED_MESSAGE_EMBED_PAYLOAD, { messageId }


setChannelMessagesSearchQuery = (query) ->

  { SET_CHANNEL_MESSAGES_SEARCH_QUERY } = actionTypes

  dispatch SET_CHANNEL_MESSAGES_SEARCH_QUERY, { query }


fetchMessagesByQuery = (channelId, query, options = {}) ->

  {
    LOAD_MESSAGES_SUCCESS
    CHANNEL_MESSAGES_SEARCH_BEGIN
    CHANNEL_MESSAGES_SEARCH_SUCCESS } = actionTypes

  dispatch CHANNEL_MESSAGES_SEARCH_BEGIN, { channelId, query }

  kd.singletons.search.searchChannel query, channelId, options
    .then (messages) ->
      kd.singletons.reactor.batch ->
        for message in messages
          dispatchLoadMessageSuccess channelId, message

        dispatch CHANNEL_MESSAGES_SEARCH_SUCCESS, { channelId, messages }
        dispatch LOAD_MESSAGES_SUCCESS, { channelId, messages }


module.exports = {
  loadMessage
  loadMessages
  loadMessageBySlug
  ensureMessage
  createMessage
  likeMessage
  unlikeMessage
  removeMessage
  editMessage
  loadComments
  createComment
  changeSelectedMessage
  setMessageEditMode
  unsetMessageEditMode
  changeSelectedMessageBySlug
  putLoaderMarker
  removeLoaderMarker
  editEmbedPayloadByUrl
  disableEditedEmbedPayload
  fetchMessagesByQuery
  setChannelMessagesSearchQuery
}
