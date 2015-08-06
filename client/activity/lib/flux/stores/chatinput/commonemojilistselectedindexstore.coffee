actionTypes        = require 'activity/flux/actions/actiontypes'
SelectedIndexStore = require './chatinputselectedindexstore'

###*
 * Store to contain common emoji list selected index
###
module.exports = class CommonEmojiListSelectedIndexStore extends SelectedIndexStore

  @getterPath = 'CommonEmojiListSelectedIndexStore'

  initialize: ->

    actions =
      setIndex        : actionTypes.SET_COMMON_EMOJI_LIST_SELECTED_INDEX
      resetIndex      : actionTypes.RESET_COMMON_EMOJI_LIST_SELECTED_INDEX

    @bindActions actions
