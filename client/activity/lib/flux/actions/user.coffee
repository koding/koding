kd          = require 'kd'
actionTypes = require './actiontypes'

{ actions: appActions } = require 'app/flux'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to set current query of channel participants.
 * Also, it resets users selected index and loads users
 * filtered by query if query is not empty
 *
 * @param {string} query
###
setChannelParticipantsInputQuery = (query) ->

  if query
    { SET_CHANNEL_PARTICIPANTS_QUERY } = actionTypes
    dispatch SET_CHANNEL_PARTICIPANTS_QUERY, { query }
    resetChannelParticipantsSelectedIndex()
    appActions.user.searchAccounts query

  else
    unsetChannelParticipantsInputQuery()


###*
 * Action to unset current query of channel participants.
 * Also, it resets users selected index
###
unsetChannelParticipantsInputQuery = ->

  { UNSET_CHANNEL_PARTICIPANTS_QUERY } = actionTypes
  dispatch UNSET_CHANNEL_PARTICIPANTS_QUERY
  resetChannelParticipantsSelectedIndex()


###*
 * Action to reset users selected index to initial value
###
resetChannelParticipantsSelectedIndex = ->

  { RESET_CHANNEL_PARTICIPANTS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHANNEL_PARTICIPANTS_SELECTED_INDEX


###*
 * Action to set selected index of channel participants.
 *
 * @param {number} index
###
setChannelParticipantsSelectedIndex = (index) ->

  { SET_CHANNEL_PARTICIPANTS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHANNEL_PARTICIPANTS_SELECTED_INDEX, { index }


###*
 * Action to increment users selected index
###
moveToNextChannelParticipantIndex = ->

  { MOVE_TO_NEXT_CHANNEL_PARTICIPANT_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHANNEL_PARTICIPANT_INDEX


###*
 * Action to decrement users selected index
###
moveToPrevChannelParticipantIndex = ->

  { MOVE_TO_PREV_CHANNEL_PARTICIPANT_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHANNEL_PARTICIPANT_INDEX


module.exports = {
  setChannelParticipantsInputQuery
  unsetChannelParticipantsInputQuery
  resetChannelParticipantsSelectedIndex
  setChannelParticipantsSelectedIndex
  moveToNextChannelParticipantIndex
  moveToPrevChannelParticipantIndex
}
