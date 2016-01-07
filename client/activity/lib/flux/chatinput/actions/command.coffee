kd             = require 'kd'
actionTypes    = require './actiontypes'

###*
 * Action to set current query of chat input commands.
 * Also, it resets commands selected index.
 *
 * @param {string} stateId
 * @param {string} query
###
setQuery = (stateId, query) ->

  if query
    { SET_CHAT_INPUT_COMMANDS_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_COMMANDS_QUERY, { stateId, query }
    resetSelectedIndex stateId
  else
    unsetQuery stateId


###*
 * Action to unset current query of chat input commands.
 * Also, it resets commands selected index
 *
 * @param {string} stateId
###
unsetQuery = (stateId) ->

  { UNSET_CHAT_INPUT_COMMANDS_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_COMMANDS_QUERY, { stateId }
  resetSelectedIndex stateId


###*
 * Action to set selected index of chat input commands
 *
 * @param {string} stateId
 * @param {number} index
###
setSelectedIndex = (stateId, index) ->

  { SET_CHAT_INPUT_COMMANDS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_COMMANDS_SELECTED_INDEX, { stateId, index }


###*
 * Action to increment commands selected index
 *
 * @param {string} stateId
###
moveToNextIndex = (stateId) ->

  { MOVE_TO_NEXT_CHAT_INPUT_COMMANDS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_COMMANDS_INDEX, { stateId }


###*
 * Action to decrement commands selected index
 *
 * @param {string} stateId
###
moveToPrevIndex = (stateId) ->

  { MOVE_TO_PREV_CHAT_INPUT_COMMANDS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_COMMANDS_INDEX, { stateId }


###*
 * Action to reset commands selected index
 *
 * @param {string} stateId
###
resetSelectedIndex = (stateId) ->

  { RESET_CHAT_INPUT_COMMANDS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_COMMANDS_SELECTED_INDEX, { stateId }


###*
 * Action to set visibility of chat input commands
 *
 * @param {string} stateId
 * @param {bool} visible
###
setVisibility = (stateId, visible) ->

  { SET_CHAT_INPUT_COMMANDS_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_COMMANDS_VISIBILITY, { stateId, visible }


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


module.exports = {
  setQuery
  unsetQuery
  setSelectedIndex
  moveToNextIndex
  moveToPrevIndex
  resetSelectedIndex
  setVisibility
}
