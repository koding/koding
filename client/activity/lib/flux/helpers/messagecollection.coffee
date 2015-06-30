generateDummyMessage = require 'app/util/generateDummyMessage'

IS_LIKED_KEYPATH = ['interactions', 'like', 'isInteracted']
LIKE_INTERACTION_KEYPATH = ['interactions', 'like']

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
 * Create a fake message. Assigns given clientRequestId as fake message's id.
 *
 * @param {string} clientRequestId
 * @param {string} body
 * @return {object} message
###
createFakeMessage = (clientRequestId, body) ->

  message    = generateDummyMessage body
  message.id = clientRequestId

  return message


###*
 * Removes fake message.
 *
 * @param {MessageCollection} messages
 * @param {string} clientRequestId
 * @return {MessageCollection} _messages
###
removeFakeMessage = (messages, clientRequestId) ->

  messages.remove clientRequestId


module.exports = {
  addMessage
  removeMessage
  markMessageRemoved
  unmarkMessageRemoved
  setIsLiked
  addLiker
  removeLiker
  createFakeMessage
  removeFakeMessage
}

