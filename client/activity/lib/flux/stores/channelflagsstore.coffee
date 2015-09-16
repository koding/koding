KodingFluxStore = require 'app/flux/store'
actions         = require '../actions/actiontypes'
toImmutable     = require 'app/util/toImmutable'
immutable       = require 'immutable'

module.exports = class ChannelFlagsStore extends KodingFluxStore

  @getterPath = 'ChannelFlagsStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_MESSAGES_BEGIN, @handleLoadMessagesBegin
    @on actions.LOAD_MESSAGES_SUCCESS, @handleLoadMessagesSuccess
    @on actions.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actions.CREATE_MESSAGE_SUCCESS, @handleCreateMessageEnd
    @on actions.CREATE_MESSAGE_FAIL, @handleCreateMessageEnd


  handleLoadMessagesBegin: (channelFlags, { channelId }) ->

    channelFlags = @createChannelMapIfNeed channelFlags, channelId
    return channelFlags.setIn [channelId, 'isMessagesLoading'], yes


  handleLoadMessagesSuccess: (channelFlags, { channelId }) ->

    channelFlags = @createChannelMapIfNeed channelFlags, channelId
    return channelFlags.setIn [channelId, 'isMessagesLoading'], no


  handleCreateMessageBegin: (channelFlags, { channelId }) ->

    channelFlags = @createChannelMapIfNeed channelFlags, channelId
    return channelFlags.setIn [channelId, 'isMessageBeingSubmitted'], yes


  handleCreateMessageEnd: (channelFlags, { channelId }) ->

    channelFlags = @createChannelMapIfNeed channelFlags, channelId
    return channelFlags.setIn [channelId, 'isMessageBeingSubmitted'], no


  createChannelMapIfNeed: (channelFlags, channelId) ->

    unless channelFlags.has channelId
      return channelFlags.set channelId, immutable.Map()

    return channelFlags

