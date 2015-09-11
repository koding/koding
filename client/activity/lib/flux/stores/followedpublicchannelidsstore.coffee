KodingFluxStore = require 'app/flux/store'
actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports = class FollowedPublicChannelIdsStore extends KodingFluxStore

  @getterPath = 'FollowedPublicChannelIdsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.FOLLOW_CHANNEL_SUCCESS, @handleFollowChannelSuccess


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

