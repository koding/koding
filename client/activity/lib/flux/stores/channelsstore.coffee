KodingFluxStore = require 'app/flux/store'
actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports = class ChannelsStore extends KodingFluxStore

  @getterPath = 'ChannelsStore'

  getInitialState: -> immutable.Map()

  initialize: ->

    @on actions.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actions.CREATE_MESSAGE_SUCCESS, @handleCreateMessageSuccess
    @on actions.CREATE_MESSAGE_FAIL, @handleCreateMessageFail

    @on actions.LOAD_FOLLOWED_PUBLIC_CHANNEL_SUCCESS, @handleLoadChannelSuccess
    @on actions.LOAD_FOLLOWED_PRIVATE_CHANNEL_SUCCESS, @handleLoadChannelSuccess


  handleLoadChannelSuccess: (channels, { channel }) ->

    return channels.set channel.id, toImmutable channel


  handleCreateMessageBegin: (channels, { channelId }) ->

    return initChannel channels, channelId


  handleCreateMessageSuccess: (channels, { channelId, channel }) ->

    return channels.set channelId, toImmutable channel


  handleCreateMessageFail: (channels, { channelId }) ->

    return removeFakeChannel channels, channelId


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

