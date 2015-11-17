actions        = require 'activity/flux/chatinput/actions/actiontypes'
BaseQueryStore = require 'activity/flux/chatinput/stores/basequerystore'

###*
 * Store to contain filtered emoji list query
###
module.exports = class FilteredEmojiListQueryStore extends BaseQueryStore

  @getterPath = 'FilteredEmojiListQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_FILTERED_EMOJI_LIST_QUERY
      unsetQuery : actions.UNSET_FILTERED_EMOJI_LIST_QUERY

