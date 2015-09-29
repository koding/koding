kd             = require 'kd'
actionTypes    = require './actiontypes'

setQuery = (stateId, query) ->

  if query
    { SET_CHAT_INPUT_COMMANDS_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_COMMANDS_QUERY, { stateId, query }
    resetSelectedIndex stateId
  else
    unsetQuery stateId


unsetQuery = (stateId) ->

  { UNSET_CHAT_INPUT_COMMANDS_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_COMMANDS_QUERY, { stateId }
  resetSelectedIndex stateId


setSelectedIndex = (stateId, index) ->

  { SET_CHAT_INPUT_COMMANDS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_COMMANDS_SELECTED_INDEX, { stateId, index }


moveToNextIndex = (stateId) ->

  { MOVE_TO_NEXT_CHAT_INPUT_COMMANDS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_COMMANDS_INDEX, { stateId }


moveToPrevIndex = (stateId) ->

  { MOVE_TO_PREV_CHAT_INPUT_COMMANDS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_COMMANDS_INDEX, { stateId }


resetSelectedIndex = (stateId) ->

  { RESET_CHAT_INPUT_COMMANDS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_COMMANDS_SELECTED_INDEX, { stateId }


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