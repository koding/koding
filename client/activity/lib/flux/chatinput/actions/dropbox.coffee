kd          = require 'kd'
actionTypes = require './actiontypes'
DropboxType = require 'activity/flux/chatinput/dropboxtype'
helpers     = require './helpers'

ChannelActions          = require 'activity/flux/actions/channel'
{ actions: AppActions } = require 'app/flux'


checkForQuery = (stateId, value, position) ->

  { SET_DROPBOX_QUERY, RESET_DROPBOX } = actionTypes

  result = helpers.extractQuery value, position
  return reset stateId  unless result

  { query, type } = result

  switch type
    when DropboxType.CHANNEL then loadChannelsByQuery query
    when DropboxType.MENTION then loadAccountsByQuery query

  dispatch SET_DROPBOX_QUERY, { stateId, query, type }


loadChannelsByQuery = (query) ->

  if query
    ChannelActions.loadChannelsByQuery query
  else
    ChannelActions.loadPopularChannels()


loadAccountsByQuery = (query) ->

  AppActions.user.searchAccounts query  if query


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

