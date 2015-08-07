actions            = require 'activity/flux/actions/actiontypes'
SelectedIndexStore = require './chatinputselectedindexstore'

###*
 * Store to contain common emoji list selected index
###
module.exports = class CommonEmojiListSelectedIndexStore extends SelectedIndexStore

  @getterPath = 'CommonEmojiListSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX
      resetIndex      : actions.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX
