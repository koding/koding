actions        = require 'activity/flux/chatinput/actions/actiontypes'
BaseQueryStore = require 'activity/flux/chatinput/stores/basequerystore'

###*
 * Store to contain mentions query
###
module.exports = class ChatInputMentionsQueryStore extends BaseQueryStore

  @getterPath = 'ChatInputMentionsQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_MENTIONS_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_MENTIONS_QUERY

