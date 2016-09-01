KodingFluxStore      = require 'app/flux/base/store'
actions              = require '../actions/actiontypes'
toImmutable          = require 'app/util/toImmutable'
immutable            = require 'immutable'

module.exports = class ChannelsStore extends KodingFluxStore

  @getterPath = 'ChannelsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.LOAD_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, @handleLoadFollowedChannelSuccess
    @on actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.LOAD_POPULAR_CHANNELS_SUCCESS, @handleLoadPopularChannelsSuccess

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

    @on actions.REMOVE_PARTICIPANT_FROM_CHANNEL, @handleRemoveParticipantFromChannel

    @on actions.UPDATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess


  handleLoadChannelSuccess: (channels, { channel }) ->

    return channels.set channel.id, toImmutable channel


  handleLoadPopularChannelsSuccess: (currentChannels, { channels }) ->

    # we don't update channel if channel has been already set. Because
    # fetchPopularTopics action doesn't get the correct unreadCount value.
    # When BE fix it, we are gonna change this.
    return currentChannels.withMutations (map) ->
      for channel in  channels
        map.set channel.id, toImmutable channel  unless map.get channel.id

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


  handleRemoveParticipantFromChannel: (channels, { channelId, accountId }) ->

    channel = channels.get channelId

    participantCount    = channel.get 'participantCount'
    participantsPreview = channel.get 'participantsPreview'

    participantsPreview = participantsPreview.filter (participant) ->

      participant.get('_id') isnt accountId

    channels = channels.setIn [channelId, 'participantCount'], participantCount - 1
    channels = channels.setIn [channelId, 'participantsPreview'], participantsPreview


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
