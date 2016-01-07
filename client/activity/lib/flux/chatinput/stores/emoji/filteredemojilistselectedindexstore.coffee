actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to contain filtered emoji list selected index
###
module.exports = class FilteredEmojiListSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'FilteredEmojiListSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX
      moveToNextIndex : actions.MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX
      moveToPrevIndex : actions.MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX
      resetIndex      : actions.RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX
