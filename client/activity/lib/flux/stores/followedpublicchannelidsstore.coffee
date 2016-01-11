KodingFluxStore      = require 'app/flux/base/store'
actions              = require '../actions/actiontypes'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
createChannelActions = require 'activity/flux/createchannel/actions/actiontypes'

module.exports = class FollowedPublicChannelIdsStore extends KodingFluxStore

  @getterPath = 'FollowedPublicChannelIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.FOLLOW_CHANNEL_SUCCESS, @handleFollowChannelSuccess
    @on actions.UNFOLLOW_CHANNEL_SUCCESS, @handleUnfollowChannelSuccess
    @on createChannelActions.CREATE_PUBLIC_CHANNEL_SUCCESS, @handleLoadChannelSuccess

  ###*
   * Adds a new channel to followedChannels by given channelId
   *
   * @param {Immutable.Map} followedChannelIds
   * @param {object} payload
   * @param {string} payload.channel
  ###
  handleLoadChannelSuccess: (followedChannelIds, { channel }) ->

    followedChannelIds.set channel.id, channel.id


  ###*
   * Adds a new channel to followedChannels by given channelId
   *
   * @param {Immutable.Map} followedChannelIds
   * @param {object} payload
   * @param {string} payload.channelId
  ###
  handleFollowChannelSuccess: (followedChannelIds, { channelId }) ->

    followedChannelIds.set channelId, channelId


  ###*
   * Remove a channel from followedChannelIds by given channelId
   *
   * @param {Immutable.Map} followedChannelIds
   * @param {object} payload
   * @param {string} payload.channelId
  ###
  handleUnfollowChannelSuccess: (followedChannelIds, { channelId }) ->

    followedChannelIds.remove channelId
