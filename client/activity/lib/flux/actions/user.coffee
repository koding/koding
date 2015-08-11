kd          = require 'kd'
actionTypes = require './actiontypes'

{ actions: appActions } = require 'app/flux'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


setChatInputUsersQuery = (query) ->

  if query
    { SET_CHAT_INPUT_USERS_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_USERS_QUERY, { query }
    resetChatInputUsersSelectedIndex()
    appActions.user.loadAccounts query
  else
    unsetChatInputUsersQuery()


unsetChatInputUsersQuery = ->

  { UNSET_CHAT_INPUT_USERS_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_USERS_QUERY

  resetChatInputUsersSelectedIndex()


setChatInputUsersSelectedIndex = (index) ->

  { SET_CHAT_INPUT_USERS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_USERS_SELECTED_INDEX, { index }


moveToNextChatInputUsersIndex = ->

  { MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX


moveToPrevChatInputUsersIndex = ->

  { MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX


resetChatInputUsersSelectedIndex = ->

  { RESET_CHAT_INPUT_USERS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_USERS_SELECTED_INDEX


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