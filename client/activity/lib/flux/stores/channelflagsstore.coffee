KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actions/actiontypes'
immutable       = require 'immutable'

module.exports = class ChannelFlagsStore extends KodingFluxStore

  @getterPath = 'ChannelFlagsStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_CHANNEL_SUCCESS, @handleLoadChannel
    @on actions.CREATE_MESSAGE_BEGIN, @handleCreateMessageBegin
    @on actions.CREATE_MESSAGE_SUCCESS, @handleCreateMessageEnd
    @on actions.CREATE_MESSAGE_FAIL, @handleCreateMessageEnd
    @on actions.SET_ALL_MESSAGES_LOADED, @handleSetAllMessagesLoaded
    @on actions.UNSET_ALL_MESSAGES_LOADED, @handleUnsetAllMessagesLoaded
    @on actions.SET_CHANNEL_SCROLL_POSITION, @handleSetScrollPosition
    @on actions.SET_CHANNEL_LAST_SEEN_TIME, @handleSetLastSeenTime
    @on actions.SET_MESSAGE_EDIT_MODE, @handleSetMessageEditMode
    @on actions.UNSET_MESSAGE_EDIT_MODE, @handleUnsetMessageEditMode
    @on actions.SET_CHANNEL_RESULT_STATE, @handleChangeResultState


  handleLoadChannel: (channelFlags, { channelId }) ->

    return helper.ensureChannelMap channelFlags, channelId


  handleCreateMessageBegin: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'hasSubmittingMessage'], yes


  handleCreateMessageEnd: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'hasSubmittingMessage'], no


  handleSetAllMessagesLoaded: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'reachedFirstMessage'], yes


  handleUnsetAllMessagesLoaded: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'reachedFirstMessage'], no


  handleSetScrollPosition: (channelFlags, { channelId, position }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'scrollPosition'], position


  handleSetLastSeenTime: (channelFlags, { channelId, timestamp }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'lastSeenTime'], timestamp


  handleSetMessageEditMode: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'hasEditingMessage'], yes


  handleUnsetMessageEditMode: (channelFlags, { channelId }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'hasEditingMessage'], no


  handleChangeResultState: (channelFlags, { channelId, resultState }) ->

    channelFlags = helper.ensureChannelMap channelFlags, channelId
    return channelFlags.setIn [channelId, 'resultListState'], resultState


helper =

  ensureChannelMap: (channelFlags, channelId) ->

    unless channelFlags.has channelId
      return channelFlags.set channelId, immutable.Map()

    return channelFlags
