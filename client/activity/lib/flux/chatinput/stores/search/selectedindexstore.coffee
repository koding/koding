actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to handle chat input search selected index
###
module.exports = class ChatInputSearchSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'ChatInputSearchSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_CHAT_INPUT_SEARCH_SELECTED_INDEX
      moveToNextIndex : actions.MOVE_TO_NEXT_CHAT_INPUT_SEARCH_INDEX
      moveToPrevIndex : actions.MOVE_TO_PREV_CHAT_INPUT_SEARCH_INDEX
      resetIndex      : actions.RESET_CHAT_INPUT_SEARCH_SELECTED_INDEX
