kd             = require 'kd'
actionTypes    = require './actiontypes'
DropboxActions = require './dropbox'

dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to set chat input value for the specified channel and stateId.
 * If value is empty, it calls dropbox reset action
 * Otherwise, if dropboxInfo is provided, it calls checking value for dropbox query
 *
 * @param {string} channelId
 * @param {string} stateId
 * @param {string} value
 * @param {object} dropboxInfo
###
setValue = (channelId, stateId, value, dropboxInfo) ->

  { SET_CHAT_INPUT_VALUE } = actionTypes
  dispatch SET_CHAT_INPUT_VALUE, { channelId, stateId, value }

  unless value
    DropboxActions.reset stateId
  else if dropboxInfo
    { position, tokens } = dropboxInfo
    DropboxActions.checkForQuery stateId, value, position, tokens


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

