actionTypes = require 'activity/flux/actions/actiontypes'
QueryStore  = require './chatinputquerystore'

###*
 * Store to contain filtered emoji list query
###
module.exports = class FilteredEmojiListQueryStore extends QueryStore

  @getterPath = 'FilteredEmojiListQueryStore'

  initialize: ->

    actions =
      setQuery   : actionTypes.SET_FILTERED_EMOJI_LIST_QUERY
      unsetQuery : actionTypes.UNSET_FILTERED_EMOJI_LIST_QUERY

    @bindActions actions

