kd             = require 'kd'
actionTypes    = require './actiontypes'
ChannelActions = require 'activity/flux/actions/channel'

###*
 * Action to set current query of chat input channels.
 * Also, it resets channels selected index and loads channels
 * depending on query's value:
 * - if query is empty, it loads popular channels
 * - otherwise, it loads channels filtered by query
 *
 * @param {string} stateId
 * @param {string} query
###
setQuery = (stateId, query) ->

  if query
    { SET_CHAT_INPUT_CHANNELS_QUERY } = actionTypes
    dispatch SET_CHAT_INPUT_CHANNELS_QUERY, { stateId, query }
    resetSelectedIndex stateId
    ChannelActions.loadChannelsByQuery query
  else
    unsetQuery stateId
    ChannelActions.loadPopularChannels()


###*
 * Action to unset current query of chat input channels.
 * Also, it resets channels selected index
 *
 * @param {string} stateId
###
unsetQuery = (stateId) ->

  { UNSET_CHAT_INPUT_CHANNELS_QUERY } = actionTypes
  dispatch UNSET_CHAT_INPUT_CHANNELS_QUERY, { stateId }

  resetSelectedIndex stateId


###*
 * Action to set selected index of chat input channels
 *
 * @param {string} stateId
 * @param {number} index
###
setSelectedIndex = (stateId, index) ->

  { SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX } = actionTypes
  dispatch SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { stateId, index }


###*
 * Action to increment channels selected index
 *
 * @param {string} stateId
###
moveToNextIndex = (stateId) ->

  { MOVE_TO_NEXT_CHAT_INPUT_CHANNELS_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_CHAT_INPUT_CHANNELS_INDEX, { stateId }


###*
 * Action to decrement channels selected index
 *
 * @param {string} stateId
###
moveToPrevIndex = (stateId) ->

  { MOVE_TO_PREV_CHAT_INPUT_CHANNELS_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_CHAT_INPUT_CHANNELS_INDEX, { stateId }


###*
 * Action to reset channels selected index
 *
 * @param {string} stateId
###
resetSelectedIndex = (stateId) ->

  { RESET_CHAT_INPUT_CHANNELS_SELECTED_INDEX } = actionTypes
  dispatch RESET_CHAT_INPUT_CHANNELS_SELECTED_INDEX, { stateId }


###*
 * Action to set visibility of chat input channels
 *
 * @param {string} stateId
 * @param {bool} visible
###
setVisibility = (stateId, visible) ->

  { SET_CHAT_INPUT_CHANNELS_VISIBILITY } = actionTypes
  dispatch SET_CHAT_INPUT_CHANNELS_VISIBILITY, { stateId, visible }


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

