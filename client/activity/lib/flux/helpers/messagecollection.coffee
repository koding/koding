whoami               = require 'app/util/whoami'
generateDummyMessage = require 'app/util/generateDummyMessage'


###*
 * Adds given message to given messages map.
 *
 * @param {MessageCollection} messages
 * @param {IMSocialMessage} message
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
 * @param {IMSocialMessage} message
 * @param {boolean} state
 * @return {IMSocialMessage} _message
###
setIsLiked = (message, state) ->

  message.setIn ['interactions', 'like', 'isInteracted'], state


###*
 * Adds an actor (given userId) to like interaction of given message.
 *
 * @param {IMSocialMessage} message
 * @param {string} userId
 * @return {IMSocialMessage} _message
###
addLiker = (message, userId) ->

  message.updateIn ['interactions', 'like'], (like) ->
    like
      # add logged in user to actors preview.
      .update 'actorsPreview', (preview) -> preview.unshift userId
      # increase actors count by one.
      .update 'actorsCount', (count) -> count + 1


###*
 * Removes actor (given userId) from like interaction of given message.
 *
 * @param {IMSocialMessage} message
 * @param {boolean} state
 * @return {IMSocialMessage} _message
###
removeLiker = (message, userId) ->

  message.updateIn ['interactions', 'like'], (like) ->
    like
      # filter out given userId from actorsPreview list.
      .update 'actorsPreview', (preview) -> preview.filterNot (id) -> id is userId
      # decrease actors count by one.
      .update 'actorsCount', (count) -> count - 1


###*
 * Create a fake message.
 *
 * @param {string} id
 * @param {string} body
 * @return {object} message
###
createFakeMessage = (id, body) ->

  message           = generateDummyMessage body
  message.accountId = whoami().socialApiId
  message.id        = id

  return message


###*
 * Removes fake message.
 *
 * @param {MessageCollection} messages
 * @param {string} id
 * @return {MessageCollection} _messages
###
removeFakeMessage = (messages, id) ->

  messages.remove id


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
