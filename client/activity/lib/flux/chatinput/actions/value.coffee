kd          = require 'kd'
actionTypes = require './actiontypes'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...


setValue = (channelId, value) ->

  { SET_CHAT_INPUT_VALUE } = actionTypes
  dispatch SET_CHAT_INPUT_VALUE, { channelId, value }


resetValue = (channelId) ->

  setValue channelId, ''


module.exports = {
  setValue
  resetValue
}