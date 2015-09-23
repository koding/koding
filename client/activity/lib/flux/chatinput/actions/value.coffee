kd          = require 'kd'
actionTypes = require './actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to set chat input value for the specified channel.
 *
 * @param {string} channelId
 * @param {string} value
###
setValue = (channelId, value) ->

  { SET_CHAT_INPUT_VALUE } = actionTypes
  dispatch SET_CHAT_INPUT_VALUE, { channelId, value }


###*
 * Action to reset chat input value for the specified channel.
 * It sets chat input value to empty string
 *
 * @param {string} channelId
###
resetValue = (channelId) ->

  setValue channelId, ''


module.exports = {
  setValue
  resetValue
}

