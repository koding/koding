actions    = require 'activity/flux/chatinput/actions/actiontypes'
QueryStore = require 'activity/flux/chatinput/stores/chatinputquerystore'

###*
 * Store to contain users query
###
module.exports = class ChatInputUsersQueryStore extends QueryStore

  @getterPath = 'ChatInputUsersQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_USERS_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_USERS_QUERY

