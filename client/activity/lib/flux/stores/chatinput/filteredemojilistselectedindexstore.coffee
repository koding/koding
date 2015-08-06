actionTypes        = require 'activity/flux/actions/actiontypes'
SelectedIndexStore = require './chatinputselectedindexstore'

###*
 * Store to contain filtered emoji list selected index
###
module.exports = class FilteredEmojiListSelectedIndexStore extends SelectedIndexStore

  @getterPath = 'FilteredEmojiListSelectedIndexStore'

  initialize: ->

    actions =
      setIndex        : actionTypes.SET_FILTERED_EMOJI_LIST_SELECTED_INDEX
      moveToNextIndex : actionTypes.MOVE_TO_NEXT_FILTERED_EMOJI_LIST_INDEX
      moveToPrevIndex : actionTypes.MOVE_TO_PREV_FILTERED_EMOJI_LIST_INDEX
      resetIndex      : actionTypes.RESET_FILTERED_EMOJI_LIST_SELECTED_INDEX

    @bindActions actions
