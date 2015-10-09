actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
toImmutable     = require 'app/util/toImmutable'
KodingFluxStore = require 'app/flux/store'


module.exports = class ChannelParticipantIdsStore extends KodingFluxStore

  @getterPath = 'ChannelParticipantIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_CHANNEL_SUCCESS, @handleChannelLoad

    @on actions.LOAD_CHANNEL_PARTICIPANTS_BEGIN, @handleLoadBegin
    @on actions.LOAD_CHANNEL_PARTICIPANT_SUCCESS, @handleLoadSuccess


  ###*
   * Initializes a new channel participants container for loaded channel.
   *
   * @param {Immutable.Map} participantIds
   * @param {object} payload
   * @param {SocialChannel} payload.channel
   * @return {Immutable.Map} nextState
  ###
  handleChannelLoad: (participantIds, { channel }) ->

    return participantIds.set channel.id, immutable.Map()


  ###*
   * Loads given participants preview into channel participants container.
   *
   * @param {Immutable.Map} participantIds
   * @param {object} payload
   * @param {string} channelId
   * @param {array} participantsPreview
   * @return {Immutable.Map} nextState
  ###
  handleLoadBegin: (participantIds, { channelId, participantsPreview }) ->

    return participantIds.withMutations (ids) ->
      participantsPreview.forEach (preview) ->
        ids = ids.setIn [channelId, preview._id], preview._id

  ###*
   * Adds given userId to channel participants container.
   *
   * @param {Immutable.Map} participantIds
   * @param {object} payload
   * @param {string} payload.channelId
   * @param {string} payload.userId
   * @return {Immutable.Map} nextState
  ###
  handleLoadSuccess: (participantIds, { channelId, userId }) ->

    return participantIds.setIn [channelId, userId], userId




