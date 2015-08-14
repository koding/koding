actions            = require 'activity/flux/actions/actiontypes'
SelectedIndexStore = require './chatinputselectedindexstore'

###*
 * Store to contain users selected index
###
module.exports = class ChatInputUsersSelectedIndexStore extends SelectedIndexStore

  @getterPath = 'ChatInputUsersSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_CHAT_INPUT_USERS_SELECTED_INDEX
      moveToNextIndex : actions.MOVE_TO_NEXT_CHAT_INPUT_USERS_INDEX
      moveToPrevIndex : actions.MOVE_TO_PREV_CHAT_INPUT_USERS_INDEX
      resetIndex      : actions.RESET_CHAT_INPUT_USERS_SELECTED_INDEX
