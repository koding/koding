actions    = require 'activity/flux/modules/chatinput/actions/actiontypes'
QueryStore = require 'activity/flux/modules/chatinput/stores/chatinputquerystore'


###*
 * Store to contain filtered emoji list query
###
module.exports = class FilteredEmojiListQueryStore extends QueryStore

  @getterPath = 'FilteredEmojiListQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_FILTERED_EMOJI_LIST_QUERY
      unsetQuery : actions.UNSET_FILTERED_EMOJI_LIST_QUERY

