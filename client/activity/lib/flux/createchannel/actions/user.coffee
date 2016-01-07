kd          = require 'kd'
actionTypes = require './actiontypes'

{ actions: appActions } = require 'app/flux'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to set current query of create channel modal participants.
 * Also, it resets users selected index and loads users
 * filtered by query if query is not empty
 *
 * @param {string} query
###
setInputQuery = (query) ->

  if query
    { SET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY } = actionTypes
    dispatch SET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY, { query }
    resetSelectedIndex()
    appActions.user.searchAccounts query

  else
    unsetInputQuery()


###*
 * Action to unset current query of create channel participants.
 * Also, it resets users selected index
###
unsetInputQuery = ->

  { UNSET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY } = actionTypes
  dispatch UNSET_CREATE_NEW_CHANNEL_PARTICIPANTS_QUERY
  resetSelectedIndex()


###*
 * Action to reset users selected index to initial value
###
resetSelectedIndex = ->

  { RESET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX


###*
 * Action to set selected index of create channel participants.
 *
 * @param {number} index
###
setSelectedIndex = (index) ->

  { SET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX } = actionTypes
  dispatch SET_CREATE_NEW_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }


###*
 * Action to increment users selected index
###
moveToNextIndex = ->

  { MOVE_TO_NEXT_CREATE_NEW_CHANNEL_PARTICIPANT_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CREATE_NEW_CHANNEL_PARTICIPANT_INDEX


###*
 * Action to decrement users selected index
###
moveToPrevIndex = ->

  { MOVE_TO_PREV_CREATE_NEW_CHANNEL_PARTICIPANT_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CREATE_NEW_CHANNEL_PARTICIPANT_INDEX


###*
 * Action to set visibility of create channel dropdown visibility
###
setDropdownVisibility = (visible) ->

  { SET_CREATE_NEW_CHANNEL_PARTICIPANTS_DROPDOWN_VISIBILITY } = actionTypes
  dispatch SET_CREATE_NEW_CHANNEL_PARTICIPANTS_DROPDOWN_VISIBILITY, { visible }



module.exports = {
  setInputQuery
  unsetInputQuery
  resetSelectedIndex
  setSelectedIndex
  moveToNextIndex
  moveToPrevIndex
  setDropdownVisibility
}
