_                        = require 'lodash'
whoami                   = require 'app/util/whoami'
actions                  = require '../actions/actiontypes'
chatinputActions         = require '../chatinput/actions/actiontypes'
toImmutable              = require 'app/util/toImmutable'
KodingFluxStore          = require 'app/flux/base/store'
MessageCollectionHelpers = require '../helpers/messagecollection'
getEmptyEmbedPayload     = require 'activity/util/getEmptyEmbedPayload'


###*
 * Immutable version of a social message. see toImmutable util.
 *
 * @typedef IMSocialMessage
###

###*
 * MessagesStore state represents a IMMessageCollection, in which keys are
 * messageIds and values are immutable version of associated SocialMessage
 * instances.
 *
 * @typedef {Immutable.Map<string, IMSocialMessage>} IMMessageCollection
###

module.exports = class MessagesStore extends KodingFluxStore

  @getterPath = 'MessagesStore'

  getInitialState: -> toImmutable {}


  initialize: ->

    @on actions.LOAD_MESSAGE_SUCCESS, @handleLoadMessageSuccess
    @on actions.LOAD_POPULAR_MESSAGE_SUCCESS, @handleLoadMessageSuccess

    @on actions.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actions.CREATE_MESSAGE_SUCCESS, @handleCreateMessageSuccess
    @on actions.CREATE_MESSAGE_FAIL, @handleCreateMessageFail

    @on actions.EDIT_MESSAGE_BEGIN, @handleEditMessageBegin
    @on actions.EDIT_MESSAGE_SUCCESS, @handleEditMessageSuccess
    @on actions.EDIT_MESSAGE_FAIL, @handleEditMessageFail
    @on actions.SET_MESSAGE_EDIT_MODE, @handleSetMessageEditMode
    @on actions.UNSET_MESSAGE_EDIT_MODE, @handleUnsetMessageEditMode

    @on actions.REMOVE_MESSAGE_BEGIN, @handleRemoveMessageBegin
    @on actions.REMOVE_MESSAGE_SUCCESS, @handleRemoveMessageSuccess
    @on actions.REMOVE_MESSAGE_FAIL, @handleRemoveMessageFail

    @on actions.LIKE_MESSAGE_BEGIN, @handleLikeMessageBegin
    @on actions.LIKE_MESSAGE_SUCCESS, @handleLikeMessageSuccess
    @on actions.LIKE_MESSAGE_FAIL, @handleLikeMessageFail

    @on actions.UNLIKE_MESSAGE_BEGIN, @handleUnlikeMessageBegin
    @on actions.UNLIKE_MESSAGE_SUCCESS, @handleUnlikeMessageSuccess
    @on actions.UNLIKE_MESSAGE_FAIL, @handleUnlikeMessageFail

    @on actions.LOAD_COMMENT_SUCCESS, @handleLoadCommentSuccess

    @on actions.CREATE_COMMENT_BEGIN, @handleCreateMessageBegin
    @on actions.CREATE_COMMENT_SUCCESS, @handleCreateCommentSuccess
    @on actions.CREATE_COMMENT_FAIL, @handleCreateMessageFail

    @on actions.EDIT_MESSAGE_EMBED_PAYLOAD_SUCCESS, @handleEditMessageEmbedPayloadSuccess
    @on actions.EDIT_MESSAGE_EMBED_PAYLOAD_FAIL, @handleEditMessageEmbedPayloadFail
    @on actions.RESET_EDITED_MESSAGE_PAYLOAD, @handleResetEditedMessagePayload


  ###*
   * Handler for message load actions.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {SocialMessage} payload.message
   * @return {IMMessageCollection} nextState
  ###
  handleLoadMessageSuccess: (messages, { message }) ->

    { addMessage } = MessageCollectionHelpers

    return addMessage messages, toImmutable message


  ###*
   * Handler for `CREATE_MESSAGE_BEGIN` action.
   * It creates a fake message and pushes it to given channel's thread.
   * Latency compensation first step.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.body
   * @param {string} payload.clientRequestId
   * @return {IMMessageCollection} nextState
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
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @param {SocialMessage} payload.message
   * @return {IMMessageCollection} nextState
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
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @return {IMMessageCollection} nextState
  ###
  handleCreateMessageFail: (messages, { channelId, clientRequestId }) ->

    { removeFakeMessage } = MessageCollectionHelpers

    return removeFakeMessage messages, clientRequestId


  ###*
   * Use private fields to updated optimistically.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @param {string} payload.body
   * @param {object=} payload.payload
   * @return {IMMessageCollection} nextState
  ###
  handleEditMessageBegin: (messages, { messageId, body, payload }) ->

    { addMessage } = MessageCollectionHelpers

    message = messages.get messageId
    message = message.set '__editedBody', body
    message = message.set '__editedPayload', toImmutable payload

    return addMessage messages, message


  ###*
   * Replace old message with given messageId with the new one provided through
   * props.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @param {SocialMessage} payload.message
   * @return {IMMessageCollection} nextState
  ###
  handleEditMessageSuccess: (messages, { message, messageId }) ->

    { addMessage } = MessageCollectionHelpers

    return addMessage messages, toImmutable message


  ###*
   * Cleanup optimistically updates.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleEditMessageFail: (messages, { messageId }) ->

    { addMessage } = MessageCollectionHelpers

    message = messages.get messageId
    message = message.remove '__editedBody'
    message = message.remove '__editedPayload'

    return addMessage messages, message


  ###*
   * It sets message editing mode
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleSetMessageEditMode: (messages, { messageId }) ->

    return messages = messages.setIn [messageId, '__isEditing'], yes


  ###*
   * It unsets message editing mode
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleUnsetMessageEditMode: (messages, { messageId }) ->

    { addMessage } = MessageCollectionHelpers

    message = messages.get messageId
    message = message.set '__isEditing', no

    return addMessage messages, message


  ###*
   * Handler for `CREATE_COMMENT_SUCCESS` action.
   * It first removes fake comment if it exists, and then pushes given comment
   * from payload.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.clientRequestId
   * @param {SocialMessage} payload.comment
   * @return {IMMessageCollection} nextState
  ###
  handleCreateCommentSuccess: (messages, { clientRequestId, comment }) ->

    { addMessage, removeFakeMessage } = MessageCollectionHelpers

    if clientRequestId
      messages = removeFakeMessage messages, clientRequestId

    return addMessage messages, toImmutable comment


  ###*
   * Handler for successful comment creation.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {SocialMessage} payload.comment
   * @param {IMMessageCollection} nextState
  ###
  handleLoadCommentSuccess: (messages, { comment }) ->

    { addMessage } = MessageCollectionHelpers

    return addMessage messages, toImmutable comment


  ###*
   * Handler for `REMOVE_MESSAGE_BEGIN` action.
   * It marks message with given messageId as removed, so that views/components
   * can have a way to differentiate.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleRemoveMessageBegin: (messages, { messageId }) ->

    { markMessageRemoved } = MessageCollectionHelpers

    return markMessageRemoved messages, messageId


  ###*
   * Handler for `REMOVE_MESSAGE_FAIL` action.
   * It unmarks removed flag from the message with given messageId.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleRemoveMessageFail: (messages, { messageId }) ->

    { unmarkMessageRemoved } = MessageCollectionHelpers

    return unmarkMessageRemoved messages, messageId


  ###*
   * Handler for `REMOVE_MESSAGE_SUCCESS` action.
   * It removes message with given messageId.
   *
   * @param {IMMessageCollection} messages
   * @param {object} payload
   * @param {string} payload.messageId
   * @return {IMMessageCollection} nextState
  ###
  handleRemoveMessageSuccess: (messages, { messageId }) ->

    { removeMessage } = MessageCollectionHelpers

    return removeMessage messages, messageId


  handleEditMessageEmbedPayloadSuccess: (messages, { messageId, embedPayload }) ->

    message = messages.get messageId
    return messages  unless message.get '__isEditing'

    payload = message.get 'payload'
    payload = _.assign {}, payload.toJS(), embedPayload ? getEmptyEmbedPayload()

    return messages = messages.setIn [messageId, '__editedPayload'], toImmutable payload


  handleEditMessageEmbedPayloadFail: (messages, { messageId }) ->

    payload = messages.getIn [messageId, 'payload']
    payload = _.assign {}, payload.toJS(), getEmptyEmbedPayload()

    return messages = messages.setIn [messageId, '__editedPayload'], toImmutable payload


  handleResetEditedMessagePayload: (messages, { messageId }) ->

    { addMessage } = MessageCollectionHelpers

    message = messages.get messageId
    message = message.remove '__editedPayload'

    return addMessage messages, message

