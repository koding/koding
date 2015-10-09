actions    = require 'activity/flux/actions/actiontypes'
QueryStore = require './chatinputquerystore'

###*
 * Store to handle chat input search query
###
module.exports = class ChatInputSearchQueryStore extends QueryStore

  @getterPath = 'ChatInputSearchQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_SEARCH_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_SEARCH_QUERY

