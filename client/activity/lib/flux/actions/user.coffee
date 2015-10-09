kd          = require 'kd'
actionTypes = require './actiontypes'

{ actions: appActions } = require 'app/flux'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to set current query of chat input users.
 * Also, it resets users selected index and loads users
 * filtered by query if query is not empty
 *
 * @param {string} stateId
 * @param {string} query
###
setChatInputUsersQuery = (stateId, query) ->

  if query
    { SET_CHAT_INPUT_USERS_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_USERS_QUERY, { stateId, query }
    resetChatInputUsersSelectedIndex stateId
    appActions.user.searchAccounts query
  else
    unsetChatInputUsersQuery stateId


###*
 * Action to unset current query of chat input users.
 * Also, it resets users selected index
 *
 * @param {string} stateId
###
unsetChatInputUsersQuery = (stateId) ->

  { UNSET_CHAT_INPUT_USERS_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_USERS_QUERY, { stateId }

  resetChatInputUsersSelectedIndex stateId


###*
 * Action to set selected index of chat input users
 *
 * @param {string} stateId
 * @param {number} index
###
setChatInputUsersSelectedIndex = (stateId, index) ->

  { SET_CHAT_INPUT_USERS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_USERS_SELECTED_INDEX, { stateId, index }


###*
 * Action to increment users selected index
 *
 * @param {string} stateId
###
moveToNextChatInputUsersIndex = (stateId) ->

  { MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX, { stateId }


###*
 * Action to decrement users selected index
 *
 * @param {string} stateId
###
moveToPrevChatInputUsersIndex = (stateId) ->

  { MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX, { stateId }


###*
 * Action to reset users selected index
 *
 * @param {string} stateId
###
resetChatInputUsersSelectedIndex = (stateId) ->

  { RESET_CHAT_INPUT_USERS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_USERS_SELECTED_INDEX, { stateId }


###*
 * Action to set visibility of chat input users
 *
 * @param {string} stateId
 * @param {bool} visible
###
setChatInputUsersVisibility = (stateId, visible) ->

  { SET_CHAT_INPUT_USERS_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_USERS_VISIBILITY, { stateId, visible }


module.exports = {
  setChatInputUsersQuery
  unsetChatInputUsersQuery
  setChatInputUsersSelectedIndex
  moveToNextChatInputUsersIndex
  moveToPrevChatInputUsersIndex
  resetChatInputUsersSelectedIndex
  setChatInputUsersVisibility
}