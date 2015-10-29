KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports = class ChannelFlagsStore extends KodingFluxStore

  @getterPath = 'ChannelFlagsStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actions.CREATE_MESSAGE_SUCCESS, @handleCreateMessageEnd
    @on actions.CREATE_MESSAGE_FAIL, @handleCreateMessageEnd
    @on actions.SET_ALL_MESSAGES_LOADED, @handleSetAllMessagesLoaded
    @on actions.UNSET_ALL_MESSAGES_LOADED, @handleUnsetAllMessagesLoaded
    @on actions.SET_CHANNEL_SCROLL_POSITION, @handleSetScrollPosition


  handleCreateMessageBegin: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'isMessageBeingSubmitted'], yes


  handleCreateMessageEnd: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'isMessageBeingSubmitted'], no


  handleSetAllMessagesLoaded: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'reachedFirstMessage'], yes


  handleUnsetAllMessagesLoaded: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'reachedFirstMessage'], no


  handleSetScrollPosition: (channelFlags, { channelId, position }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'scrollPosition'], position


helper =

  ensureChannelMap: (channelFlags, channelId) ->

    unless channelFlags.has channelId
      return channelFlags.set channelId, immutable.Map()

    return channelFlags

