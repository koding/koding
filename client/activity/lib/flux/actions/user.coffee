kd          = require 'kd'
actionTypes = require './actiontypes'

{ actions: appActions } = require 'app/flux'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to set current query of chat input users.
 * Also, it resets users selected index and loads users
 * filtered by query if query is not empty
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {string} query
###
setChatInputUsersQuery = (initiatorId, query) ->

  if query
    { SET_CHAT_INPUT_USERS_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_USERS_QUERY, { initiatorId, query }
    resetChatInputUsersSelectedIndex initiatorId
    appActions.user.searchAccounts query
  else
    unsetChatInputUsersQuery initiatorId


###*
 * Action to unset current query of chat input users.
 * Also, it resets users selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
unsetChatInputUsersQuery = (initiatorId) ->

  { UNSET_CHAT_INPUT_USERS_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_USERS_QUERY, { initiatorId }

  resetChatInputUsersSelectedIndex initiatorId


###*
 * Action to set selected index of chat input users
 *
 * @param {string} initiatorId - id of initiated action component
 * @param {number} index
###
setChatInputUsersSelectedIndex = (initiatorId, index) ->

  { SET_CHAT_INPUT_USERS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_USERS_SELECTED_INDEX, { initiatorId, index }


###*
 * Action to increment users selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
moveToNextChatInputUsersIndex = (initiatorId) ->

  { MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX, { initiatorId }


###*
 * Action to decrement users selected index
 *
 * @param {string} initiatorId - id of initiated action component
###
moveToPrevChatInputUsersIndex = (initiatorId) ->

  { MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX, { initiatorId }


###*
 * Action to reset users selected index to initial value
 *
 * @param {string} initiatorId - id of initiated action component
###
resetChatInputUsersSelectedIndex = (initiatorId) ->

  { RESET_CHAT_INPUT_USERS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_USERS_SELECTED_INDEX, { initiatorId }


###*
 * Action to set visibility of chat input users
 *
 * @param {string} initiatorId - id of initiated action component
###
setChatInputUsersVisibility = (initiatorId, visible) ->

  { SET_CHAT_INPUT_USERS_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_USERS_VISIBILITY, { initiatorId, visible }


module.exports = {
  setChatInputUsersQuery
  unsetChatInputUsersQuery
  setChatInputUsersSelectedIndex
  moveToNextChatInputUsersIndex
  moveToPrevChatInputUsersIndex
  resetChatInputUsersSelectedIndex
  setChatInputUsersVisibility
}