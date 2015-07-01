whoami                   = require 'app/util/whoami'
actionTypes              = require '../actions/actiontypes'
toImmutable              = require 'app/util/toImmutable'
KodingFluxStore          = require 'app/flux/store'
MessageCollectionHelpers = require '../helpers/messagecollection'


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
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.body
   * @param {string} payload.clientRequestId
   * @return {MessageCollection} nextState
  ###
  handleCreateMessageBegin: (messages, { body, clientRequestId }) ->

    { createFakeMessage, addMessage } = MessageCollectionHelpers

    message = createFakeMessage clientRequestId, body

    return addMessage messages, toImmutable message


  ###*
   * Handler for `CREATE_MESSAGE_SUCCESS` action.
   * It first removes fake message if it exists, and then pushes given message
   * from payload.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @param {SocialMessage} payload.message
   * @return {MessageCollection} nextState
  ###
  handleCreateMessageSuccess: (messages, { clientRequestId, message }) ->

    { addMessage, removeFakeMessage } = MessageCollectionHelpers

    if clientRequestId
      messages = removeFakeMessage messages, clientRequestId

    return addMessage messages, toImmutable message


  ###*
   * Handler for `CREATE_MESSAGE_FAIL` action.
   * It removes fake message associated with given clientRequestId.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @return {MessageCollection} nextState
  ###
  handleCreateMessageFail: (messages, { channelId, clientRequestId }) ->

    { removeFakeMessage } = MessageCollectionHelpers

    return removeFakeMessage messages, clientRequestId


  ###*
   * Handler for `REMOVE_MESSAGE_BEGIN` action.
   * It marks message with given messageId as removed, so that views/components
   * can have a way to differentiate.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleRemoveMessageBegin: (messages, { messageId }) ->

    { markMessageRemoved } = MessageCollectionHelpers

    return markMessageRemoved messages, messageId


  ###*
   * Handler for `REMOVE_MESSAGE_FAIL` action.
   * It unmarks removed flag from the message with given messageId.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleRemoveMessageFail: (messages, { messageId }) ->

    { unmarkMessageRemoved } = MessageCollectionHelpers

    return unmarkMessageRemoved messages, messageId


  ###*
   * Handler for `REMOVE_MESSAGE_SUCCESS` action.
   * It removes message with given messageId.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleRemoveMessageSuccess: (messages, { messageId }) ->

    { removeMessage } = MessageCollectionHelpers

    return removeMessage messages, messageId


  ###*
   * Handler for `LIKE_MESSAGE_BEGIN` action.
   * It optimistically adds a like from logged in user.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleLikeMessageBegin: (messages, { messageId }) ->

    { setIsLiked, addLiker } = MessageCollectionHelpers

    return messages.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, yes
        message = addLiker message, whoami()._id


  ###*
   * Handler for `LIKE_MESSAGE_SUCCESS` action.
   * It updates the message with message id with given message.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @param {SocialMessage} payload.message
   * @return {MessageCollection} nextState
  ###
  handleLikeMessageSuccess: (messages, { messageId, message }) ->

    { addMessage } = MessageCollectionHelpers

    return addMessage messages, toImmutable message


  ###*
   * Handler for `LIKE_MESSAGE_FAIL` action.
   * It removes optimistically added like in `LIKE_MESSAGE_BEGIN` action.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleLikeMessageFail: (messages, { messageId }) ->

    { setIsLiked, removeLiker } = MessageCollectionHelpers

    return messages.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, no
        message = removeLiker message, whoami()._id


  ###*
   * Handler for `UNLIKE_MESSAGE_BEGIN` action.
   * It optimistically removes a like from message.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleUnlikeMessageBegin: (messages, { messageId }) ->

    { setIsLiked, removeLiker } = MessageCollectionHelpers

    return messages.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, no
        message = removeLiker message, whoami()._id


  ###*
   * Handler for `UNLIKE_MESSAGE_SUCCESS` action.
   * It updates the message with message id with given message.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @param {SocialMessage} payload.message
   * @return {MessageCollection} nextState
  ###
  handleUnlikeMessageSuccess: (messages, { messageId, message }) ->

    { addMessage } = MessageCollectionHelpers

    return addMessage messages, toImmutable message


  ###*
   * Handler for `UNLIKE_MESSAGE_FAIL` action.
   * It adds back optimistically removed like in `UNLIKE_MESSAGE_BEGIN` action.
   *
   * @param {MessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {MessageCollection} nextState
  ###
  handleUnlikeMessageFail: (messages, { messageId }) ->

    { setIsLiked, addLiker } = MessageCollectionHelpers

    return messages.withMutations (messages) ->
      messages.update messageId, (message) ->
        message = setIsLiked message, yes
        message = addLiker message, whoami()._id


