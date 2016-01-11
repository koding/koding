actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to contain commands selected index
###
module.exports = class ChatInputCommandsSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'ChatInputCommandsSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_CHAT_INPUT_COMMANDS_SELECTED_INDEX
      moveToNextIndex : actions.MOVE_TO_NEXT_CHAT_INPUT_COMMANDS_INDEX
      moveToPrevIndex : actions.MOVE_TO_PREV_CHAT_INPUT_COMMANDS_INDEX
      resetIndex      : actions.RESET_CHAT_INPUT_COMMANDS_SELECTED_INDEX
