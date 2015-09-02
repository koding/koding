actions            = require 'activity/flux/chatinput/actions/actiontypes'
SelectedIndexStore = require 'activity/flux/chatinput/stores/chatinputselectedindexstore'

###*
 * Store to contain common emoji list selected index
###
module.exports = class CommonEmojiListSelectedIndexStore extends SelectedIndexStore

  @getterPath = 'CommonEmojiListSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX
      resetIndex      : actions.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX

