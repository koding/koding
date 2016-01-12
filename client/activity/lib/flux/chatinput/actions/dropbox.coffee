kd          = require 'kd'
actionTypes = require './actiontypes'
getters     = require 'activity/flux/chatinput/getters'

###*
 * Runs token checks on chat input value to extract dropbox query.
 * If all token checks fail, it means that no dropbox can be shown
 * for the current chat input value, so it clears current dropbox state.
 * Otherwise, it saves extracted dropbox query and token config
 * to the store calling SET_DROPBOX_QUERY_AND_CONFIG for a given stateId.
 * Also, if token has triggerAction method, it's called to load all necessary
 * data for the current dropbox
 *
 * @param {string} stateId
 * @param {string} value
 * @param {number} position
 * @param {array} tokens
###
checkForQuery = (stateId, value, position, tokens) ->

  { SET_DROPBOX_QUERY_AND_CONFIG } = actionTypes

  result = extractQuery value, position, tokens
  return reset stateId  unless result

  { query, token } = result

  config = token.getConfig query
  dispatch SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query, config }

  token.triggerAction? stateId, query


###*
 * Tries to extract dropbox query for every token in a given
 * tokens list from the current chat input value depending
 * on the current cursor position. If any token can extract query,
 * this method returns object with extracted query and the token
 *
 * @param {string} value
 * @param {number} position
 * @param {array} tokens
 * @return {object}
###
extractQuery = (value, position, tokens) ->

  for token in tokens
    query = token.extractQuery value, position
    return { query, token }  if query?

###*
 * Updates dropbox selected index
 *
 * @param {string} stateId
 * @param {number} index
###
setSelectedIndex = (stateId, index) ->

  { SET_DROPBOX_SELECTED_INDEX } = actionTypes
  dispatch SET_DROPBOX_SELECTED_INDEX, { stateId, index }


###*
 * Increments dropbox selected index
 *
 * @param {string} stateId
###
moveToNextIndex = (stateId) ->

  { MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, { stateId }


###*
 * Decrements dropbox selected index
 *
 * @param {string} stateId
###
moveToPrevIndex = (stateId) ->

  { MOVE_TO_PREV_DROPBOX_SELECTED_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, { stateId }


###*
 * Resets current dropbox state
 *
 * @param {string} stateId
###
reset = (stateId) ->

  { RESET_DROPBOX } = actionTypes
  dispatch RESET_DROPBOX, { stateId }


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  checkForQuery
  setSelectedIndex
  moveToNextIndex
  moveToPrevIndex
  reset
}
