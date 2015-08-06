actionTypes        = require 'activity/flux/actions/actiontypes'
SelectedIndexStore = require './chatinputselectedindexstore'

###*
 * Store to contain channels selected index
###
module.exports = class ChatInputChannelsSelectedIndexStore extends SelectedIndexStore

  @getterPath = 'ChatInputChannelsSelectedIndexStore'

  initialize: ->

    actions =
      setIndex        : actionTypes.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX
      moveToNextIndex : actionTypes.MOVE_TO_NEXT_CHAT_INPUT_CHANNELS_INDEX
      moveToPrevIndex : actionTypes.MOVE_TO_PREV_CHAT_INPUT_CHANNELS_INDEX
      resetIndex      : actionTypes.RESET_CHAT_INPUT_CHANNELS_SELECTED_INDEX

    @bindActions actions
