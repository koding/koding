actions    = require 'activity/flux/chatinput/actions/actiontypes'
QueryStore = require 'activity/flux/chatinput/stores/chatinputquerystore'

###*
 * Store to handle chat input search query
###
module.exports = class ChatInputSearchQueryStore extends QueryStore

  @getterPath = 'ChatInputSearchQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_SEARCH_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_SEARCH_QUERY

