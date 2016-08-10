actions         = require '../actions/actiontypes'
immutable       = require 'immutable'
KodingFluxStore = require 'app/flux/base/store'


module.exports = class ChannelParticipantIdsStore extends KodingFluxStore

  @getterPath = 'ChannelParticipantIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_CHANNEL_SUCCESS, @handleChannelLoad

    @on actions.LOAD_CHANNEL_PARTICIPANTS_BEGIN, @handleLoadBegin
    @on actions.LOAD_CHANNEL_PARTICIPANT_SUCCESS, @handleLoadSuccess
    @on actions.ADD_PARTICIPANTS_TO_CHANNEL_SUCCESS, @handleLoadSuccess

    @on actions.FOLLOW_CHANNEL_SUCCESS, @handleFollowChannelSuccess
    @on actions.UNFOLLOW_CHANNEL_SUCCESS, @handleUnfollowChannelSuccess
    @on actions.LEAVE_PRIVATE_CHANNEL_SUCCESS, @handleUnfollowChannelSuccess

    @on actions.REMOVE_PARTICIPANT_FROM_CHANNEL, @handleUnfollowChannelSuccess

  ###*
   * Initializes a new channel participants container for loaded channel.
   *
   * @param {Immutable.Map} participantIds
   * @param {object} payload
   * @param {SocialChannel} payload.channel
   * @return {Immutable.Map} nextState
  ###
  handleChannelLoad: (participantIds, { channel }) ->

    unless participantIds.has channel.id
      participantIds = participantIds.set channel.id, immutable.Map()

    return participantIds


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


  ###*
   * Adds given accountId to channel participants container.
   *
   * @param {Immutable.Map} participantIds
   * @param {object} payload
   * @param {string} payload.channelId
   * @param {string} payload.accountId
   * @return {Immutable.Map} nextState
  ###
  handleFollowChannelSuccess: (participantIds, { channelId, accountId }) ->

    return participantIds.setIn [channelId, accountId], accountId


  ###*
   * Removes given accountId from channel participants container.
   *
   * @param {Immutable.Map} participantIds
   * @param {object} payload
   * @param {string} payload.channelId
   * @param {string} payload.accountId
   * @return {Immutable.Map} nextState
  ###
  handleUnfollowChannelSuccess: (participantIds, { channelId, accountId }) ->

    return participantIds  unless participantIds.has channelId

    channel = participantIds.get channelId
    channel = channel.remove accountId
    participantIds = participantIds.set channelId, channel

    return participantIds
