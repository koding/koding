actions    = require 'activity/flux/actions/actiontypes'
QueryStore = require './chatinputquerystore'

###*
 * Store to contain users query
###
module.exports = class ChatInputUsersQueryStore extends QueryStore

  @getterPath = 'ChatInputUsersQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_USERS_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_USERS_QUERY