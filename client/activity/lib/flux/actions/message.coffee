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

  { appManager, socialapi } = kd.singletons
  { LOAD_MESSAGES_BEGIN, LOAD_MESSAGES_FAIL, CREATE_MESSAGE_SUCCESS } = actionTypes

  dispatch LOAD_MESSAGES_BEGIN, { channelId }

  appManager.tell 'Activity', 'fetch', {id: channelId}, (err, result) ->
    if err
      dispatch LOAD_MESSAGES_FAIL, { err, channelId }
      return

    # get the channel instance from cache and dispatch it.
    channel = socialapi.retrieveCachedItemById channelId

    result.forEach (message) ->
      dispatch CREATE_MESSAGE_SUCCESS, { channelId, channel, message }


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

    kd.utils.wait 273, ->
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

    kd.utils.wait 273, ->
      socialapi.message.byId {id: messageId}, (err, message) ->
        dispatch UNLIKE_MESSAGE_SUCCESS, {
          message
        }

editMessage = (messageId, body, payload = {}) ->

    {socialapi} = kd.singletons
    { EDIT_MESSAGE_BEGIN
      EDIT_MESSAGE_SUCCESS
      EDIT_MESSAGE_FAIL
    } = actionTypes

    dispatch EDIT_MESSAGE_BEGIN, {
      messageId, body, payload
    }

    socialapi.message.edit {id: messageId, body, payload}, (err, message) ->

      if err
        dispatch EDIT_MESSAGE_FAIL, {
          err, messageId
        }

        return

      kd.utils.wait 273, ->
        socialapi.message.byId {id: messageId}, (err, message) ->
          message.body = body
          dispatch EDIT_MESSAGE_SUCCESS, {
            message, messageId
          }


module.exports = {
  loadMessages
  createMessage
  likeMessage
  unlikeMessage
  removeMessage
  editMessage
}

