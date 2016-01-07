actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to contain channels selected index
###
module.exports = class ChatInputChannelsSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'ChatInputChannelsSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_CHAT_INPUT_CHANNELS_SELECTED_INDEX
      moveToNextIndex : actions.MOVE_TO_NEXT_CHAT_INPUT_CHANNELS_INDEX
      moveToPrevIndex : actions.MOVE_TO_PREV_CHAT_INPUT_CHANNELS_INDEX
      resetIndex      : actions.RESET_CHAT_INPUT_CHANNELS_SELECTED_INDEX
