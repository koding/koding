actions        = require 'activity/flux/chatinput/actions/actiontypes'
BaseQueryStore = require 'activity/flux/chatinput/stores/basequerystore'

###*
 * Store to contain users query
###
module.exports = class ChatInputUsersQueryStore extends BaseQueryStore

  @getterPath = 'ChatInputUsersQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_USERS_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_USERS_QUERY

