actions    = require 'activity/flux/chatinput/actions/actiontypes'
QueryStore = require 'activity/flux/chatinput/stores/chatinputquerystore'

###*
 * Store to contain channels query
###
module.exports = class ChatInputChannelsQueryStore extends QueryStore

  @getterPath = 'ChatInputChannelsQueryStore'

  initialize: ->

    @bindActions
      setQuery   : actions.SET_CHAT_INPUT_CHANNELS_QUERY
      unsetQuery : actions.UNSET_CHAT_INPUT_CHANNELS_QUERY

