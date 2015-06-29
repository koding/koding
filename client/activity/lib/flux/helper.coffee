generateDummyMessage = require 'app/util/generateDummyMessage'

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


module.exports = {
  createFakeMessage
}

