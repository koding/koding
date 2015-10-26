actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to contain users selected index
###
module.exports = class ChatInputUsersSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'ChatInputUsersSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX
      moveToNextIndex : actions.MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX
      moveToPrevIndex : actions.MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX
      resetIndex      : actions.RESET_CHAT_INPUT_USERS_SELECTED_INDEX

