actions            = require 'activity/flux/chatinput/actions/actiontypes'
SelectedIndexStore = require 'activity/flux/chatinput/stores/chatinputselectedindexstore'

###*
 * Store to handle chat input search selected index
###
module.exports = class ChatInputSearchSelectedIndexStore extends SelectedIndexStore

  @getterPath = 'ChatInputSearchSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX
      moveToNextIndex : actions.MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX
      moveToPrevIndex : actions.MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX
      resetIndex      : actions.RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX

