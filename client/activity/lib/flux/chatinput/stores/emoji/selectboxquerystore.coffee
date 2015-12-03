actions        = require 'activity/flux/chatinput/actions/actiontypes'
BaseQueryStore = require 'activity/flux/chatinput/stores/basequerystore'

###*
 * Store to handle emoji selectbox query
###
module.exports = class EmojiSelectBoxQueryStore extends BaseQueryStore

  @getterPath = 'EmojiSelectBoxQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_EMOJI_SELECTBOX_QUERY
      unsetQuery : actions.UNSET_EMOJI_SELECTBOX_QUERY

