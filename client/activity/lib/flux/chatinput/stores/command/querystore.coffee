actions        = require 'activity/flux/chatinput/actions/actiontypes'
BaseQueryStore = require 'activity/flux/chatinput/stores/basequerystore'

###*
 * Store to handle chat input commands query
###
module.exports = class ChatInputCommandsQueryStore extends BaseQueryStore

  @getterPath = 'ChatInputCommandsQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_COMMANDS_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_COMMANDS_QUERY
