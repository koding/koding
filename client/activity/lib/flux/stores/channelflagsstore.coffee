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


  handleLoadMessagesBegin: (channelFlags, { channelId }) ->

    unless channelFlags.has channelId
      channelFlags = channelFlags.set channelId, immutable.Map()

    return channelFlags.setIn [channelId, 'isMessagesLoading'], yes


  handleLoadMessagesSuccess: (channelFlags, { channelId }) ->

    unless channelFlags.has channelId
      channelFlags = channelFlags.set channelId, immutable.Map()

    return channelFlags.setIn [channelId, 'isMessagesLoading'], no

