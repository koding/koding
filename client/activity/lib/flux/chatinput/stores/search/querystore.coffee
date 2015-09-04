actions        = require 'activity/flux/chatinput/actions/actiontypes'
BaseQueryStore = require 'activity/flux/chatinput/stores/basequerystore'

###*
 * Store to handle chat input search query
###
module.exports = class ChatInputSearchQueryStore extends BaseQueryStore

  @getterPath = 'ChatInputSearchQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_SEARCH_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_SEARCH_QUERY

