actions        = require 'activity/flux/chatinput/actions/actiontypes'
BaseQueryStore = require 'activity/flux/chatinput/stores/basequerystore'

###*
 * Store to handle emoji selector query
###
module.exports = class EmojiSelectorQueryStore extends BaseQueryStore

  @getterPath = 'EmojiSelectorQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_EMOJI_SELECTOR_QUERY
      unsetQuery : actions.UNSET_EMOJI_SELECTOR_QUERY

