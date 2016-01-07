actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to contain mentions selected index
###
module.exports = class ChatInputMentionsSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'ChatInputMentionsSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_CHAT_INPUT_MENTIONS_SELECTED_INDEX
      moveToNextIndex : actions.MOVE_TO_NEXT_CHAT_INPUT_MENTIONS_INDEX
      moveToPrevIndex : actions.MOVE_TO_PREV_CHAT_INPUT_MENTIONS_INDEX
      resetIndex      : actions.RESET_CHAT_INPUT_MENTIONS_SELECTED_INDEX
