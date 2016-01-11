actions                = require 'activity/flux/chatinput/actions/actiontypes'
BaseSelectedIndexStore = require 'activity/flux/chatinput/stores/baseselectedindexstore'

###*
 * Store to contain emoji selectbox selected index
###
module.exports = class EmojiSelectBoxSelectedIndexStore extends BaseSelectedIndexStore

  @getterPath = 'EmojiSelectBoxSelectedIndexStore'

  initialize: ->

    @bindActions
      setIndex        : actions.SET_EMOJI_SELECTBOX_SELECTED_INDEX
      resetIndex      : actions.RESET_EMOJI_SELECTBOX_SELECTED_INDEX
