kd          = require 'kd'
actionTypes = require './actiontypes'

{ actions: appActions } = require 'app/flux'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to set current query of chat input users.
 * Also, it resets users selected index and loads users
 * filtered by query if query is not empty
 *
 * @param {string} query
###
setChatInputUsersQuery = (query) ->

  if query
    { SET_CHAT_INPUT_USERS_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_USERS_QUERY, { query }
    resetChatInputUsersSelectedIndex()
    appActions.user.searchAccounts query
  else
    unsetChatInputUsersQuery()


###*
 * Action to unset current query of chat input users.
 * Also, it resets users selected index
###
unsetChatInputUsersQuery = ->

  { UNSET_CHAT_INPUT_USERS_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_USERS_QUERY

  resetChatInputUsersSelectedIndex()


###*
 * Action to set selected index of chat input users
 *
 * @param {number} index
###
setChatInputUsersSelectedIndex = (index) ->

  { SET_CHAT_INPUT_USERS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_USERS_SELECTED_INDEX, { index }


###*
 * Action to increment users selected index
###
moveToNextChatInputUsersIndex = ->

  { MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX


###*
 * Action to decrement users selected index
###
moveToPrevChatInputUsersIndex = ->

  { MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX


###*
 * Action to reset users selected index to initial value
###
resetChatInputUsersSelectedIndex = ->

  { RESET_CHAT_INPUT_USERS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_USERS_SELECTED_INDEX


###*
 * Action to set visibility of chat input users
###
setChatInputUsersVisibility = (visible) ->

  { SET_CHAT_INPUT_USERS_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_USERS_VISIBILITY, { visible }


module.exports = {
  setChatInputUsersQuery
  unsetChatInputUsersQuery
  setChatInputUsersSelectedIndex
  moveToNextChatInputUsersIndex
  moveToPrevChatInputUsersIndex
  resetChatInputUsersSelectedIndex
  setChatInputUsersVisibility
}