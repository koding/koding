whoami               = require 'app/util/whoami'
actionTypes          = require '../actions/actiontypes'
toImmutable          = require 'app/util/toImmutable'
KodingFluxStore      = require 'app/flux/store'
{ createFakeMessage } = require '../helper'

IS_LIKED_KEYPATH = ['interactions', 'like', 'isInteracted']
LIKE_INTERACTION_KEYPATH = ['interactions', 'like']

###*
 * Immutable version of a social message. see toImmutable util.
 *
 * @typedef ImmutableSocialMessage
###

###*
 * MessagesStore state represents a MessageCollection, in which keys are
 * messageIds and values are immutable version of associated SocialMessage
 * instances.
 *
 * @typedef {Immutable.Map<string, ImmutableSocialMessage>} MessageCollection
###

module.exports = class MessagesStore extends KodingFluxStore

  getInitialState: -> toImmutable {}


  initialize: ->

    @on actionTypes.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actionTypes.CREATE_MESSAGE_SUCCESS, @handleCreateMessageSuccess
    @on actionTypes.CREATE_MESSAGE_FAIL, @handleCreateMessageFail

    @on actionTypes.REMOVE_MESSAGE_BEGIN, @handleRemoveMessageBegin
    @on actionTypes.REMOVE_MESSAGE_SUCCESS, @handleRemoveMessageSuccess
    @on actionTypes.REMOVE_MESSAGE_FAIL, @handleRemoveMessageFail

    @on actionTypes.LIKE_MESSAGE_BEGIN, @handleLikeMessageBegin
    @on actionTypes.LIKE_MESSAGE_SUCCESS, @handleLikeMessageSuccess
    @on actionTypes.LIKE_MESSAGE_FAIL, @handleLikeMessageFail

    @on actionTypes.UNLIKE_MESSAGE_BEGIN, @handleUnlikeMessageBegin
    @on actionTypes.UNLIKE_MESSAGE_SUCCESS, @handleUnlikeMessageSuccess
    @on actionTypes.UNLIKE_MESSAGE_FAIL, @handleUnlikeMessageFail


  ###*
   * Handler for `CREATE_MESSAGE_BEGIN` action.
   * It creates a fake message and pushes it to given channel's thread.
   * Latency compensation first step.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.body
   * @param {string} payload.clientRequestId
   * @return {MessageCollection} nextState
  ###
  handleCreateMessageBegin: (currentState, { body, clientRequestId }) ->

    message = createFakeMessage clientRequestId, body

    nextState = addMessage currentState, toImmutable message

    return nextState


  ###*
   * Handler for `CREATE_MESSAGE_SUCCESS` action.
   * It first removes fake message if it exists, and then pushes given message
   * from payload.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @param {SocialMessage} payload.message
   * @return {MessageCollection} nextState
  ###
  handleCreateMessageSuccess: (currentState, { clientRequestId, message }) ->

    if clientRequestId
      currentState = removeFakeMessage currentState, clientRequestId

    nextState = addMessage currentState, toImmutable message

    return nextState


  ###*
   * Handler for `CREATE_MESSAGE_FAIL` action.
   * It removes fake message associated with given clientRequestId.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @return {MessageCollection} nextState
  ###
  handleCreateMessageFail: (currentState, { channelId, clientRequestId }) ->

    nextState = removeFakeMessage currentState, clientRequestId

    return nextState


  ###*
   * Handler for `REMOVE_MESSAGE_BEGIN` action.
   * It marks message with given messageId as removed, so that views/components
   * can have a way to differentiate.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleRemoveMessageBegin: (currentState, { messageId }) ->

    nextState = markMessageRemoved currentState, messageId

    return nextState


  ###*
   * Handler for `REMOVE_MESSAGE_FAIL` action.
   * It unmarks removed flag from the message with given messageId.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleRemoveMessageFail: (currentState, { messageId }) ->

    nextState = unmarkMessageRemoved currentState, messageId

    return nextState


  ###*
   * Handler for `REMOVE_MESSAGE_SUCCESS` action.
   * It removes message with given messageId.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleRemoveMessageSuccess: (currentState, { messageId }) ->

    nextState = removeMessage currentState, messageId

    return nextState


  ###*
   * Handler for `LIKE_MESSAGE_BEGIN` action.
   * It optimistically adds a like from logged in user.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleLikeMessageBegin: (currentState, { messageId }) ->

    nextState = currentState.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, yes
        message = addLiker message, whoami()._id

    return nextState


  ###*
   * Handler for `LIKE_MESSAGE_SUCCESS` action.
   * It updates the message with message id with given message.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @param {SocialMessage} payload.message
   * @return {MessageCollection} nextState
  ###
  handleLikeMessageSuccess: (currentState, { messageId, message }) ->

    nextState = currentState.set messageId, toImmutable message

    return nextState


  ###*
   * Handler for `LIKE_MESSAGE_FAIL` action.
   * It removes optimistically added like in `LIKE_MESSAGE_BEGIN` action.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleLikeMessageFail: (currentState, { messageId }) ->

    nextState = currentState.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, no
        message = removeLiker message, whoami()._id

    return nextState


  ###*
   * Handler for `UNLIKE_MESSAGE_BEGIN` action.
   * It optimistically removes a like from message.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleUnlikeMessageBegin: (currentState, { messageId }) ->

    nextState = currentState.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, no
        message = removeLiker message, whoami()._id

    return nextState


  ###*
   * Handler for `UNLIKE_MESSAGE_SUCCESS` action.
   * It updates the message with message id with given message.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @param {SocialMessage} payload.message
   * @return {MessageCollection} nextState
  ###
  handleUnlikeMessageSuccess: (currentState, { messageId, message }) ->

    nextState = currentState.set messageId, toImmutable message

    return nextState


  ###*
   * Handler for `UNLIKE_MESSAGE_FAIL` action.
   * It adds back optimistically removed like in `UNLIKE_MESSAGE_BEGIN` action.
   *
   * @param {MessageCollection} currentState
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleUnlikeMessageFail: (currentState, { messageId }) ->

    nextState = currentState.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, yes
        message = addLiker message, whoami()._id

    return nextState


###*
 * Adds given message to given messages map.
 *
 * @param {MessageCollection} messages
 * @param {ImmutableSocialMessage} message
 * @return {MessageCollection} _messages
###
addMessage = (messages, message) -> messages.set message.get('id'), message


###*
 * It removes message with given messageId if exists.
 *
 * @param {MessageCollection} messages
 * @param {string} messageId
 * @return {MessageCollection} _messages
###
removeMessage = (messages, messageId) ->

  if messages.has messageId
  then messages.remove messageId
  else messages


###*
 * It sets `__removed` flag to message with given messageId.
 *
 * @param {MessageCollection} messages
 * @param {string} messageId
 * @return {MessageCollection} _messages
###
markMessageRemoved = (messages, messageId) ->

  return messages  unless messages.has messageId

  messages.update messageId, (message) -> message.set '__removed', yes


###*
 * It removes `__removed` flag to message with given messageId.
 *
 * @param {MessageCollection} messages
 * @param {string} messageId
 * @return {MessageCollection} _messages
###
unmarkMessageRemoved = (messages, messageId) ->

  if messages.hasIn [messageId, '__removed']
  then messages.deleteIn [messageId, '__removed']
  else messages


###*
 * Sets isLiked status of given message to given state.
 *
 * @param {ImmutableSocialMessage} message
 * @param {boolean} state
 * @return {ImmutableSocialMessage} _message
###
setIsLiked = (message, state) -> message.setIn IS_LIKED_KEYPATH, state


###*
 * Adds an actor (given userId) to like interaction of given message.
 *
 * @param {ImmutableSocialMessage} message
 * @param {boolean} state
 * @return {ImmutableSocialMessage} _message
###
addLiker = (message, userId) ->

  message.updateIn LIKE_INTERACTION_KEYPATH, (likeInteraction) ->
    likeInteraction
      # add logged in user to actors preview.
      .update 'actorsPreview', (preview) -> preview.unshift userId
      # increase actors count by one.
      .update 'actorsCount', (count) -> count + 1


###*
 * Removes actor (given userId) from like interaction of given message.
 *
 * @param {ImmutableSocialMessage} message
 * @param {boolean} state
 * @return {ImmutableSocialMessage} _message
###
removeLiker = (message, userId) ->

  message.updateIn LIKE_INTERACTION_KEYPATH, (likeInteraction) ->
    likeInteraction
      # filter out given userId from actorsPreview list.
      .update 'actorsPreview', (preview) -> preview.filterNot (id) -> id is userId
      # decrease actors count by one.
      .update 'actorsCount', (count) -> count - 1


###*
 * Removes fake message.
 *
 * @param {MessageCollection} messages
 * @param {string} clientRequestId
 * @return {MessageCollection} _messages
###
removeFakeMessage = (messages, clientRequestId) ->

  messages.remove clientRequestId


