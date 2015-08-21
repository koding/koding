KodingFluxStore = require 'app/flux/store'
actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports = class ChannelsStore extends KodingFluxStore

  @getterPath = 'ChannelsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.LOAD_CHANNELS_SUCCESS, @handleLoadChannelListSuccess
    @on actions.LOAD_POPULAR_CHANNELS_SUCCESS, @handleLoadChannelListSuccess

    @on actions.FOLLOW_CHANNEL_BEGIN, @handleFollowChannelBegin
    @on actions.FOLLOW_CHANNEL_SUCCESS, @handleFollowChannelSuccess
    @on actions.FOLLOW_CHANNEL_FAIL, @handleFollowChannelFail

    @on actions.UNFOLLOW_CHANNEL_BEGIN, @handleUnfollowChannelBegin
    @on actions.UNFOLLOW_CHANNEL_SUCCESS, @handleUnfollowChannelSuccess
    @on actions.UNFOLLOW_CHANNEL_FAIL, @handleUnfollowChannelFail


  handleLoadChannelSuccess: (channels, { channel }) ->

    return channels.set channel.id, toImmutable channel


  handleLoadChannelListSuccess: (currentChannels, { channels }) ->

    return currentChannels.withMutations (map) ->
      map.set channel.id, toImmutable channel for channel in  channels
      return map


  handleFollowChannelBegin: (channels, { channelId }) -> channels


  handleFollowChannelFail: (channels, { channelId }) -> channels


  handleFollowChannelSuccess: (channels, { channelId }) ->

    if channels.has channelId
      channels = channels.setIn [channelId, 'isParticipant'], yes

    return channels


  handleUnfollowChannelBegin: (channels, { channelId }) -> channels


  handleUnfollowChannelFail: (channels, { channelId }) -> channels


  handleUnfollowChannelSuccess: (channels, { channelId }) ->

    if channels.has channelId
      channels = channels.setIn [channelId, 'isParticipant'], no

    return channels


initChannel = (channels, id) ->

  return channels  if channels.has id

  # create a channel like structure and add it to the collection.
  channels.set id, toImmutable { id, __fake: yes }


removeFakeChannel = (channels, id) ->

  return channels  unless channels.has id

  channel = channels.get id

  # if it has a `fake` flag, remove it, this means we didn't get any success
  # message.
  if channel.has '__fake'
    channels = channels.remove id

  return channels

