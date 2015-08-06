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
    @on actions.LOAD_CHANNELS_BY_QUERY_SUCCESS, @handleLoadChannelListSuccess


  handleLoadChannelSuccess: (channels, { channel }) ->

    return channels.set channel.id, toImmutable channel


  handleLoadChannelListSuccess: (currentChannels, { channels }) ->

    currentChannels.withMutations (map) ->
      channels.forEach (channel) -> map.set channel.id, toImmutable channel


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

