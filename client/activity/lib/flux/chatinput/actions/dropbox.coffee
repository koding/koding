kd          = require 'kd'
actionTypes = require './actiontypes'
getters     = require 'activity/flux/chatinput/getters'

checkForQuery = (stateId, value, position, tokens) ->

  { SET_DROPBOX_QUERY_AND_CONFIG } = actionTypes

  result = extractQuery value, position, tokens
  return reset stateId  unless result

  { query, token } = result

  config = token.getConfig query
  dispatch SET_DROPBOX_QUERY_AND_CONFIG, { stateId, query, config }

  token.triggerAction? stateId, query


extractQuery = (value, position, tokens) ->

  for token in tokens
    query = token.extractQuery value, position
    return { query, token }  if query?


setSelectedIndex = (stateId, index) ->

  { SET_DROPBOX_SELECTED_INDEX } = actionTypes
  dispatch SET_DROPBOX_SELECTED_INDEX, { stateId, index }


moveToNextIndex = (stateId) ->

  { MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX } = actionTypes
  dispatch MOVE_TO_NEXT_DROPBOX_SELECTED_INDEX, { stateId }


moveToPrevIndex = (stateId) ->

  { MOVE_TO_PREV_DROPBOX_SELECTED_INDEX } = actionTypes
  dispatch MOVE_TO_PREV_DROPBOX_SELECTED_INDEX, { stateId }


reset = (stateId) ->

  # do not perform extra dispatches to avoid dispatch errors when switching to another channel
  dropboxConfig = kd.singletons.reactor.evaluate getters.dropboxConfig stateId
  return  unless dropboxConfig

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

