KodingFluxStore      = require 'app/flux/base/store'
actions              = require '../actions/actiontypes'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'
createChannelActions = require 'activity/flux/createchannel/actions/actiontypes'

module.exports = class ChannelsStore extends KodingFluxStore

  @getterPath = 'ChannelsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, @handleLoadFollowedChannelSuccess
    @on actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.LOAD_POPULAR_CHANNELS_SUCCESS, @handleLoadChannelListSuccess

    @on actions.FOLLOW_CHANNEL_BEGIN, @handleFollowChannelBegin
    @on actions.FOLLOW_CHANNEL_SUCCESS, @handleFollowChannelSuccess
    @on actions.FOLLOW_CHANNEL_FAIL, @handleFollowChannelFail

    @on actions.UNFOLLOW_CHANNEL_BEGIN, @handleUnfollowChannelBegin
    @on actions.UNFOLLOW_CHANNEL_SUCCESS, @handleUnfollowChannelSuccess
    @on actions.UNFOLLOW_CHANNEL_FAIL, @handleUnfollowChannelFail
    @on actions.LEAVE_PRIVATE_CHANNEL_SUCCESS, @handleUnfollowChannelSuccess

    @on actions.ADD_PARTICIPANTS_TO_CHANNEL_BEGIN, @handleAddParticipantsToChannelBegin
    @on actions.ADD_PARTICIPANTS_TO_CHANNEL_FAIL, @handleAddParticipantsToChannelFail

    @on actions.SET_CHANNEL_UNREAD_COUNT, @handleSetUnreadCount

    @on actions.GLANCE_CHANNEL_BEGIN, @handleGlanceChannel
    @on actions.GLANCE_CHANNEL_SUCCESS, @handleGlanceChannel

    @on createChannelActions.CREATE_PRIVATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on createChannelActions.CREATE_PUBLIC_CHANNEL_SUCCESS, @handleLoadChannelSuccess

  handleLoadChannelSuccess: (channels, { channel }) ->

    # if channel comes from backend without unreadCount data,
    # we use it from the store if it exists
    if channels.has(channel.id) and not channel.unreadCount
      channel.unreadCount = channels.getIn [channel.id, 'unreadCount']

    return channels.set channel.id, toImmutable channel


  handleLoadChannelListSuccess: (currentChannels, { channels }) ->

    return currentChannels.withMutations (map) ->
      map.set channel.id, toImmutable channel for channel in  channels
      return map


  handleLoadFollowedChannelSuccess: (channels, { channel }) ->

    channels = @handleLoadChannelSuccess channels, { channel }
    return @handleFollowChannelSuccess channels, { channelId : channel.id }


  handleFollowChannelSuccess: (channels, { channelId }) ->

    if channels.has channelId
      channels = channels.setIn [channelId, 'isParticipant'], yes

    return channels


  handleUnfollowChannelSuccess: (channels, { channelId }) ->

    if channels.has channelId
      channels = channels.setIn [channelId, 'isParticipant'], no

    return channels


  handleSetUnreadCount: (channels, { channelId, unreadCount }) ->

    channels.setIn [channelId, 'unreadCount'], unreadCount


  handleGlanceChannel: (channels, { channelId }) ->

    channels.setIn [channelId, 'unreadCount'], 0


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

