actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to contain emoji selector selected index
###
module.exports = class EmojiSelectorSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'EmojiSelectorSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_EMOJI_SELECTOR_SELECTED_INDEX
      resetIndex      : actions.RESET_EMOJI_SELECTOR_SELECTED_INDEX

