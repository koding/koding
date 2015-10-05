actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to contain common emoji list selected index
###
module.exports = class CommonEmojiListSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'CommonEmojiListSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_COMMON_EMOJI_LIST_SELECTED_INDEX
      resetIndex      : actions.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX

