actions              = require '../actions/actiontypes'
immutable            = require 'immutable'
toImmutable          = require 'app/util/toImmutable'
KodingFluxStore      = require 'app/flux/base/store'
createChannelActions = require 'activity/flux/createchannel/actions/actiontypes'

module.exports = class FollowedPrivateChannelIdsStore extends KodingFluxStore

  @getterPath = 'FollowedPrivateChannelIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.DELETE_PRIVATE_CHANNEL_SUCCESS, @handleRemovePrivateChannelSuccess
    @on actions.LEAVE_PRIVATE_CHANNEL_SUCCESS, @handleRemovePrivateChannelSuccess
    @on createChannelActions.CREATE_PRIVATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess

  ###*
   * Adds given channel to privateMessageIds container.
   *
   * @param {Immutable.Map} privateMessageIds
   * @param {object} payload
   * @param {object} payload.channel
   * @return {Immutable.Map} nextState
  ###
  handleLoadChannelSuccess: (privateMessageIds, { channel }) ->

    privateMessageIds.set channel.id, channel.id


  ###*
   * Removes given channel from privateMessageIds container.
   *
   * @param {Immutable.Map} privateMessageIds
   * @param {object} payload
   * @param {string} payload.channelId
   * @return {Immutable.Map} nextState
  ###
  handleRemovePrivateChannelSuccess: (privateMessageIds, { channelId }) ->

    privateMessageIds = privateMessageIds.remove channelId

