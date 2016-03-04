KodingFluxStore = require 'app/flux/base/store'
actions         = require '../actions/actiontypes'
immutable       = require 'immutable'


module.exports = class MessageFlagsStore extends KodingFluxStore

  @getterPath = 'MessageFlagsStore'


  getInitialState: -> immutable.Map()


  initialize: ->

    @on actions.LOAD_COMMENTS_BEGIN, @markMessageAsLoading
    @on actions.LOAD_COMMENTS_SUCCESS, @unmarkMessageAsLoading


  markMessageAsLoading: (messageFlags, { messageId }) ->

    unless messageFlags.has messageId
      messageFlags = messageFlags.set messageId, immutable.Map()

    return messageFlags.setIn [messageId, 'isMessagesLoading'], yes


  unmarkMessageAsLoading: (messageFlags, { messageId }) ->

    unless messageFlags.has messageId
      messageFlags = messageFlags.set messageId, immutable.Map()

    return messageFlags.setIn [messageId, 'isMessagesLoading'], no
