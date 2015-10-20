actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/base/store'


###*
 * Store to handle participants-dropdown of create new channel modal participantIds
###
module.exports = class CreateNewChannelParticipantIdsStore extends KodingFluxStore

  @getterPath = 'CreateNewChannelParticipantIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.ADD_PARTICIPANT_TO_NEW_CHANNEL, @handleAddParticipantToNewChannel
    @on actions.REMOVE_PARTICIPANT_FROM_NEW_CHANNEL, @handleRemoveParticipantFromNewChannel
    @on actions.REMOVE_ALL_PARTICIPANTS_FROM_NEW_CHANNEL, @handleRemoveAllParticipantsFromNewChannel


  ###*
   * It sets given accountId to participantIdsStore
   *
   * @param {immutable.Map} participantIds
   * @param {object} payload
   * @param {string} payload.accountId
   * @return {string} nextState
  ###
  handleAddParticipantToNewChannel: (participantIds, { accountId }) ->

    return participantIds.set accountId, accountId


  ###*
   * It removes given accountId from participantIdsStore
   * @param {immutable.Map} participantIds
   * @param {object} payload
   * @param {string} payload.accountId
   * @return {string} nextState
  ###
  handleRemoveParticipantFromNewChannel: (participantIds, { accountId }) ->

    return participantIds.remove accountId


  ###*
   * It removes all accountIds from participantIdsStore
   * @param {immutable.Map} participantIds
   * @return {string} nextState
  ###
  handleRemoveAllParticipantsFromNewChannel: (participants) -> immutable.Map()

