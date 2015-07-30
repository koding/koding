kd = require 'kd'
generateFakeIdentifier = require 'app/util/generateFakeIdentifier'
actionTypes = require './actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...

###*
 * Action to load messages of channel with given channelId.
 *
 * @param {string} channelId
###
loadMessages = (channelId) ->

  { socialapi } = kd.singletons
  { LOAD_MESSAGES_BEGIN, LOAD_MESSAGES_FAIL, LOAD_MESSAGE_SUCCESS } = actionTypes

  dispatch LOAD_MESSAGES_BEGIN, { channelId }

  socialapi.channel.fetchActivities {id: channelId}, (err, messages) ->
    if err
      dispatch LOAD_MESSAGES_FAIL, { err, channelId }
      return

    # get the channel instance from cache and dispatch it.
    channel = socialapi.retrieveCachedItemById channelId

    kd.singletons.reactor.batch ->
      messages.forEach (message) ->
        dispatch LOAD_MESSAGE_SUCCESS, { channelId, channel, message }


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

    dispatch LOAD_MESSAGE_SUCCESS, { messageId: message.id, message }
    loadComments message.id


###*
 * Action to create a message.
 *
 * @param {string} channelId
 * @param {string} body
###
createMessage = (channelId, body) ->

  { socialapi } = kd.singletons
  { CREATE_MESSAGE_BEGIN
    CREATE_MESSAGE_FAIL
    CREATE_MESSAGE_SUCCESS } = actionTypes

  clientRequestId = generateFakeIdentifier Date.now()

  dispatch CREATE_MESSAGE_BEGIN, {
    channelId, clientRequestId, body
  }

  socialapi.message.post { channelId, clientRequestId, body }, (err, message) ->
    if err
      dispatch CREATE_MESSAGE_FAIL, {
        err, channelId, clientRequestId
      }
      return

    channel = socialapi.retrieveCachedItemById channelId

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

  dispatch LIKE_MESSAGE_BEGIN, { messageId }

  socialapi.message.like { id: messageId }, (err) ->
    if err
      dispatch LIKE_MESSAGE_FAIL, { err, messageId }
      return

    kd.utils.wait 573, ->
      socialapi.message.byId { id: messageId }, (err, message) ->
        dispatch LIKE_MESSAGE_SUCCESS, { message }


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

  dispatch UNLIKE_MESSAGE_BEGIN, { messageId }

  socialapi.message.unlike { id: messageId }, (err, message) ->
    if err
      dispatch UNLIKE_MESSAGE_FAIL, {
        err, messageId
      }
      return

    kd.utils.wait 573, ->
      socialapi.message.byId {id: messageId}, (err, message) ->
        dispatch UNLIKE_MESSAGE_SUCCESS, {
          message
        }

###*
 * Edit message.
 *
 * @param {string} messageId
 * @param {string} body
 * @param {object=} payload
###
editMessage = (messageId, body, payload = {}) ->

    {socialapi} = kd.singletons
    { EDIT_MESSAGE_BEGIN
      EDIT_MESSAGE_SUCCESS
      EDIT_MESSAGE_FAIL
    } = actionTypes

    dispatch EDIT_MESSAGE_BEGIN, { messageId, body, payload }

    socialapi.message.edit {id: messageId, body, payload}, (err, message) ->
      if err
        dispatch EDIT_MESSAGE_FAIL, { err, messageId }
        return

      kd.utils.wait 273, ->
        socialapi.message.byId {id: messageId}, (err, message) ->
          message.body = body
          dispatch EDIT_MESSAGE_SUCCESS, { message, messageId }


###*
 * Action to load comments with given options.
 *
 * @param {string} messageId
 * @param {string} from
 * @param {number} limit
###
loadComments = (messageId, from, limit) ->

  { socialapi } = kd.singletons
  { LOAD_COMMENTS_BEGIN
    LOAD_COMMENTS_FAIL
    LOAD_COMMENT_SUCCESS } = actionTypes

  dispatch LOAD_COMMENTS_BEGIN, { messageId, from, limit }

  socialapi.message.listReplies {messageId, from, limit}, (err, comments) ->
    if err
      dispatch LOAD_COMMENTS_FAIL, { err, messageId, from, limit }
      return

    kd.singletons.reactor.batch ->
      comments.forEach (comment) ->
        dispatch LOAD_COMMENT_SUCCESS, { messageId, comment }


###*
 * Adds comment to given message.
 *
 * @param {string} messageId
 * @param {string} body
 * @param {object=} payload
###
createComment = (messageId, body, payload = {}) ->

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

    dispatch CREATE_COMMENT_SUCCESS, { messageId, comment, clientRequestId }


###*
 * Changes selected message id.
 *
 * @param {string} messageId
###
changeSelectedMessage = (messageId) ->

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


module.exports = {
  loadMessages
  loadMessageBySlug
  createMessage
  likeMessage
  unlikeMessage
  removeMessage
  editMessage
  loadComments
  createComment
  changeSelectedMessage
  changeSelectedMessageBySlug
}

