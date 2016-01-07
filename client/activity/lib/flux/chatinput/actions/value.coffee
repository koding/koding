kd          = require 'kd'
actionTypes = require './actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to set chat input value for the specified channel and stateId.
 *
 * @param {string} channelId
 * @param {string} stateId
 * @param {string} value
###
setValue = (channelId, stateId, value) ->

  { SET_CHAT_INPUT_VALUE } = actionTypes
  dispatch SET_CHAT_INPUT_VALUE, { channelId, stateId, value }


###*
 * Action to reset chat input value for the specified channel.
 * It sets chat input value to empty string
 *
 * @param {string} channelId
###
resetValue = (channelId, stateId) ->

  setValue channelId, stateId, ''


module.exports = {
  setValue
  resetValue
}
