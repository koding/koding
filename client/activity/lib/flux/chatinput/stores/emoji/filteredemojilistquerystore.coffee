actions    = require 'activity/flux/chatinput/actions/actiontypes'
QueryStore = require 'activity/flux/chatinput/stores/chatinputquerystore'


###*
 * Store to contain filtered emoji list query
###
module.exports = class FilteredEmojiListQueryStore extends QueryStore

  @getterPath = 'FilteredEmojiListQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_FILTERED_EMOJI_LIST_QUERY
      unsetQuery : actions.UNSET_FILTERED_EMOJI_LIST_QUERY

