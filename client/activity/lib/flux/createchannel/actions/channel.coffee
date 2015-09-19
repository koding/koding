kd          = require 'kd'
actionTypes = require './actiontypes'

{ actions: appActions } = require 'app/flux'


dispatch = (args...) -> kd.singletons.reactor.dispatch args...


###*
 * Action to add participant to new channel by given accountId
 *
 * @param {string} accountId
###
addParticipant = (accountId) ->

  { ADD_PARTICIPANT_TO_NEW_CHANNEL } = actionTypes
  dispatch ADD_PARTICIPANT_TO_NEW_CHANNEL, { accountId }


###*
 * Action to remove participant from new channel by given accountId
 *
 * @param {string} accountId
###
removeParticipant = (accountId) ->

  { REMOVE_PARTICIPANT_FROM_NEW_CHANNEL } = actionTypes
  dispatch REMOVE_PARTICIPANT_FROM_NEW_CHANNEL, { accountId }

###*
 * Action to remove all participants from new channel
 *
 * @param {string} accountId
###
removeAllParticipants = ->

  { REMOVE_ALL_PARTICIPANTS_FROM_NEW_CHANNEL } = actionTypes
  dispatch REMOVE_ALL_PARTICIPANTS_FROM_NEW_CHANNEL



module.exports = {
  addParticipant
  removeParticipant
  removeAllParticipants
}

